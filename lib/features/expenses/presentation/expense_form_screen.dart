import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/ids.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/attachment.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/expense_category.dart';
import '../../../data/models/expense_item.dart';
import '../../../data/models/merchant.dart';
import '../../../data/providers.dart';
import '../../../shared/recognition/expense_prefill.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../../shared/widgets/category_icons.dart';
import '../../../shared/widgets/date_field.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../receipt_ocr/domain/receipt_text_parser.dart';
import '../../receipt_ocr/presentation/receipt_capture.dart';
import '../application/expense_providers.dart';
import 'widgets/items_section.dart';
import 'widgets/photo_strip.dart';
import 'widgets/scan_warnings.dart';

/// Unos novog računa (ručno ili iz prepoznatih podataka) i izmjena postojećeg.
///
/// Prepoznati podaci se NIKADA ne spremaju automatski – korisnik ih ovdje
/// pregledava, ispravlja i potvrđuje gumbom "Spremi".
class ExpenseFormScreen extends ConsumerStatefulWidget {
  const ExpenseFormScreen({super.key, this.expenseId, this.prefill});

  /// Ako je postavljen, obrazac uređuje postojeći račun.
  final String? expenseId;

  /// Podaci iz QR skenera ili OCR-a za novi račun.
  final ExpensePrefill? prefill;

  bool get isEditing => expenseId != null;

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _invoiceController = TextEditingController();
  final _noteController = TextEditingController();

  /// Kontroler polja izdavatelja dolazi iz `Autocomplete` widgeta.
  TextEditingController? _merchantController;
  String _initialMerchant = '';

  String? _categoryId;
  ExpenseType _type = ExpenseType.retail;
  PaymentStatus _status = PaymentStatus.paid;
  DateTime _issueDate = DateUtils.dateOnly(DateTime.now());
  bool _issueDateFromSource = false;
  DateTime? _dueDate;
  DateTime? _paidDate = DateUtils.dateOnly(DateTime.now());
  int? _taxCents;
  String? _qrContent;

  List<ExpenseItemDraft> _items = [];
  bool _itemsChanged = false;
  List<Attachment> _existingAttachments = [];
  final List<String> _newImagePaths = [];
  List<String> _warnings = [];

  bool _loadingExisting = false;
  bool _notFound = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadingExisting = true;
      _loadExisting();
    } else if (widget.prefill != null) {
      _applyPrefill(widget.prefill!, merge: false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _invoiceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String get _merchantText =>
      (_merchantController?.text ?? _initialMerchant).trim();

  Future<void> _loadExisting() async {
    final repo = ref.read(expenseRepositoryProvider);
    final expense = await repo.getById(widget.expenseId!);
    final items = expense == null
        ? const <ExpenseItemDraft>[]
        : (await repo.getItems(expense.id)).map((i) => i.toDraft()).toList();
    final attachments = expense == null
        ? const <Attachment>[]
        : await repo.getAttachments(expense.id);
    if (!mounted) return;
    setState(() {
      _loadingExisting = false;
      if (expense == null) {
        _notFound = true;
        return;
      }
      _initialMerchant = expense.merchantName;
      _categoryId = expense.categoryId;
      _type = expense.type;
      _status = expense.isPaid ? PaymentStatus.paid : PaymentStatus.unpaid;
      _issueDate = expense.issueDate;
      _dueDate = expense.dueDate;
      _paidDate =
          expense.paidDate ??
          (expense.isPaid ? DateUtils.dateOnly(DateTime.now()) : null);
      _taxCents = expense.taxCents;
      _qrContent = expense.qrContent;
      _amountController.text = centsToInput(expense.totalCents);
      _invoiceController.text = expense.invoiceNumber ?? '';
      _noteController.text = expense.note ?? '';
      _items = items;
      _existingAttachments = attachments;
    });
  }

  /// Popunjava obrazac prepoznatim podacima.
  ///
  /// Kod spajanja ([merge] = true, npr. fotografija nakon QR koda) postojeći
  /// podaci imaju prednost – popunjavaju se samo prazna polja.
  void _applyPrefill(ExpensePrefill p, {required bool merge}) {
    final amountWasEmpty = _amountController.text.trim().isEmpty;

    if (p.merchantName != null && (!merge || _merchantText.isEmpty)) {
      if (_merchantController != null) {
        _merchantController!.text = p.merchantName!;
      } else {
        _initialMerchant = p.merchantName!;
      }
      if (merge && p.type != null) _type = p.type!;
    }
    if (p.categoryKey != null && (!merge || _categoryId == null)) {
      _categoryId = Ids.category(p.categoryKey!);
    }
    if (!merge) {
      if (p.type != null) _type = p.type!;
      if (p.status != null) {
        _status = p.status!;
        _paidDate = _status == PaymentStatus.paid
            ? DateUtils.dateOnly(DateTime.now())
            : null;
      }
    }
    if (p.issueDate != null && (!merge || !_issueDateFromSource)) {
      _issueDate = p.issueDate!;
      _issueDateFromSource = true;
      if (_status == PaymentStatus.paid && p.source == PrefillSource.qr) {
        _paidDate = p.issueDate;
      }
    }
    if (p.dueDate != null && _dueDate == null) _dueDate = p.dueDate;
    if (p.totalCents != null && (!merge || amountWasEmpty)) {
      _amountController.text = centsToInput(p.totalCents!);
    }
    if (p.taxCents != null && _taxCents == null) _taxCents = p.taxCents;
    if (p.invoiceNumber != null && _invoiceController.text.trim().isEmpty) {
      _invoiceController.text = p.invoiceNumber!;
    }
    if (p.note != null && _noteController.text.trim().isEmpty) {
      _noteController.text = p.note!;
    }
    _qrContent ??= p.qrContent;

    final extraWarnings = <String>[];
    if (p.items.isNotEmpty) {
      if (_items.isEmpty) {
        _items = [...p.items];
        _itemsChanged = true;
      } else {
        extraWarnings.add(AppStrings.itemsKeptWarning);
      }
    }
    if (p.imagePath != null) _newImagePaths.add(p.imagePath!);

    // Zbroj stavki se provjerava uživo u odjeljku stavki, a "iznos nije
    // pronađen" nije relevantan ako je iznos već bio unesen (npr. iz QR-a).
    _warnings = [
      for (final w in p.warnings)
        if (!w.startsWith('Zbroj artikala') &&
            !(merge &&
                !amountWasEmpty &&
                w == ReceiptTextParser.totalNotFoundWarning) &&
            !(merge && w.startsWith('QR kod fiskalnog')))
          w,
      ...extraWarnings,
    ];
  }

  Future<void> _scanPhoto(ImageSource source) async {
    final prefill = await captureReceipt(context, ref, source);
    if (prefill == null || !mounted) return;
    setState(() => _applyPrefill(prefill, merge: true));
  }

  void _onMerchantSelected(String name, List<Merchant> merchants) {
    final merchant = merchants.where((m) => m.name == name).firstOrNull;
    if (merchant == null) return;
    setState(() {
      _type = merchant.type;
      if (_categoryId == null && merchant.defaultCategoryId != null) {
        _categoryId = merchant.defaultCategoryId;
      }
    });
  }

  void _onCategoryChanged(String? id, List<ExpenseCategory> categories) {
    setState(() {
      _categoryId = id;
      final category = categories.where((c) => c.id == id).firstOrNull;
      final type = category?.group.expenseType;
      if (type != null) _type = type;
    });
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final cents = parseMoneyToCents(_amountController.text);
    final merchantName = _merchantText;
    if (cents == null || merchantName.isEmpty) return;

    setState(() => _saving = true);
    try {
      final actions = ref.read(expenseActionsProvider);
      final stored = await actions.storeFiles(_newImagePaths);
      final isPaid = _status == PaymentStatus.paid;
      final draft = ExpenseDraft(
        merchantName: merchantName,
        categoryId: _categoryId,
        type: _type,
        issueDate: _issueDate,
        dueDate: _dueDate,
        paidDate: isPaid
            ? (_paidDate ?? DateUtils.dateOnly(DateTime.now()))
            : null,
        totalCents: cents,
        status: _status,
        invoiceNumber: _invoiceController.text,
        note: _noteController.text,
        qrContent: _qrContent,
        taxCents: _taxCents,
        items: (!widget.isEditing || _itemsChanged) ? _items : null,
        newAttachments: stored,
      );
      if (widget.isEditing) {
        await actions.update(widget.expenseId!, draft);
      } else {
        await actions.create(draft);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.expenseSaved)));
      context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.saveFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(expenseCategoriesProvider);
    final itemCategories =
        ref.watch(itemCategoriesProvider).dataOrNull ?? const [];
    final merchants = ref.watch(merchantsProvider).dataOrNull ?? const [];
    final canSave = !_loadingExisting && !_notFound;

    Widget body;
    if (_loadingExisting) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_notFound) {
      body = const Center(
        child: EmptyState(message: AppStrings.expenseNotFound),
      );
    } else {
      body = AsyncValueWidget<List<ExpenseCategory>>(
        value: categories,
        data: (cats) => _buildForm(context, cats, itemCategories, merchants),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? AppStrings.editExpense : AppStrings.newExpense,
        ),
      ),
      body: body,
      bottomNavigationBar: canSave
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(AppStrings.save),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildForm(
    BuildContext context,
    List<ExpenseCategory> categories,
    List<ExpenseCategory> itemCategories,
    List<Merchant> merchants,
  ) {
    const gap = SizedBox(height: 16);
    final labelStyle = Theme.of(context).textTheme.labelLarge;
    // Ako odabrana kategorija ne postoji, ne smije se proslijediti
    // padajućem izborniku (inače baca grešku).
    final selectedCategory = categories.any((c) => c.id == _categoryId)
        ? _categoryId
        : null;
    final photoPaths = [
      for (final a in _existingAttachments)
        if (a.isImage && a.localPath != null) a.localPath!,
      ..._newImagePaths,
    ];

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (_warnings.isNotEmpty) ...[
            ScanWarnings(
              warnings: _warnings,
              onDismiss: () => setState(() => _warnings = []),
            ),
            gap,
          ],
          // Fotografija računa: OCR popunjava prazna polja i stavke.
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _scanPhoto(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text(AppStrings.takePhoto),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _scanPhoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text(AppStrings.fromGallery),
                ),
              ),
            ],
          ),
          if (photoPaths.isNotEmpty) ...[
            const SizedBox(height: 12),
            PhotoStrip(
              paths: photoPaths,
              onRemove: (path) {
                if (_newImagePaths.contains(path)) {
                  setState(() => _newImagePaths.remove(path));
                }
              },
            ),
          ],
          gap,
          Autocomplete<String>(
            initialValue: TextEditingValue(text: _initialMerchant),
            optionsBuilder: (value) {
              final query = value.text.trim().toLowerCase();
              if (query.isEmpty) return const Iterable<String>.empty();
              return merchants
                  .map((m) => m.name)
                  .where((name) => name.toLowerCase().contains(query));
            },
            onSelected: (name) => _onMerchantSelected(name, merchants),
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
                  _merchantController = controller;
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: AppStrings.merchant,
                      prefixIcon: Icon(Icons.storefront_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? AppStrings.merchantRequired
                        : null,
                    onFieldSubmitted: (_) => onFieldSubmitted(),
                  );
                },
          ),
          gap,
          Text(AppStrings.expenseType, style: labelStyle),
          const SizedBox(height: 8),
          SegmentedButton<ExpenseType>(
            showSelectedIcon: false,
            segments: [
              for (final t in ExpenseType.values)
                ButtonSegment(value: t, label: Text(t.label)),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          gap,
          DropdownButtonFormField<String>(
            // Ključ osvježava polje kada se kategorija postavi automatski.
            key: ValueKey('category-$selectedCategory'),
            initialValue: selectedCategory,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: AppStrings.category,
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: [
              for (final c in categories)
                DropdownMenuItem(
                  value: c.id,
                  child: Row(
                    children: [
                      Icon(
                        categoryIcon(c.icon),
                        size: 18,
                        color: Color(c.color),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(c.name, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
            ],
            onChanged: (id) => _onCategoryChanged(id, categories),
            validator: (v) => v == null ? AppStrings.categoryRequired : null,
          ),
          gap,
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: AppStrings.totalAmount,
              hintText: AppStrings.amountHint,
              prefixIcon: Icon(Icons.euro),
              suffixText: '€',
            ),
            validator: (v) {
              final cents = parseMoneyToCents(v ?? '');
              if (cents == null) return AppStrings.amountInvalid;
              if (cents <= 0) return AppStrings.amountMustBePositive;
              return null;
            },
          ),
          if (_taxCents != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                '${AppStrings.tax}: ${formatCents(_taxCents!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
          gap,
          DateField(
            label: AppStrings.issueDate,
            value: _issueDate,
            onChanged: (d) {
              if (d != null) {
                setState(() {
                  _issueDate = d;
                  _issueDateFromSource = true;
                });
              }
            },
          ),
          gap,
          DateField(
            label: AppStrings.dueDate,
            value: _dueDate,
            allowClear: true,
            icon: Icons.event_busy_outlined,
            onChanged: (d) => setState(() => _dueDate = d),
          ),
          gap,
          Text(AppStrings.paymentStatus, style: labelStyle),
          const SizedBox(height: 8),
          SegmentedButton<PaymentStatus>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: PaymentStatus.paid,
                label: Text(AppStrings.statusPaid),
                icon: Icon(Icons.check_circle_outline),
              ),
              ButtonSegment(
                value: PaymentStatus.unpaid,
                label: Text(AppStrings.statusUnpaid),
                icon: Icon(Icons.schedule),
              ),
            ],
            selected: {_status},
            onSelectionChanged: (s) => setState(() {
              _status = s.first;
              if (_status == PaymentStatus.paid) {
                _paidDate ??= DateUtils.dateOnly(DateTime.now());
              }
            }),
          ),
          if (_status == PaymentStatus.paid) ...[
            gap,
            DateField(
              label: AppStrings.paidDate,
              value: _paidDate,
              icon: Icons.event_available_outlined,
              onChanged: (d) {
                if (d != null) setState(() => _paidDate = d);
              },
            ),
          ],
          gap,
          ItemsSection(
            items: _items,
            categories: itemCategories,
            totalCents: parseMoneyToCents(_amountController.text),
            onChanged: (items) => setState(() {
              _items = items;
              _itemsChanged = true;
            }),
            onUseItemsSum: (sum) => setState(() {
              if (sum > 0) _amountController.text = centsToInput(sum);
            }),
          ),
          gap,
          TextFormField(
            controller: _invoiceController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: AppStrings.invoiceNumberOptional,
              prefixIcon: Icon(Icons.tag),
            ),
          ),
          gap,
          TextFormField(
            controller: _noteController,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: AppStrings.noteOptional,
              prefixIcon: Icon(Icons.notes),
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }
}

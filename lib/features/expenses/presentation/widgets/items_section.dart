import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money.dart';
import '../../../../data/models/expense_category.dart';
import '../../../../data/models/expense_item.dart';
import '../../../../shared/widgets/category_icons.dart';

/// Popis stavki računa u obrascu: dodavanje, uređivanje i brisanje.
class ItemsSection extends StatelessWidget {
  const ItemsSection({
    super.key,
    required this.items,
    required this.categories,
    required this.totalCents,
    required this.onChanged,
    required this.onUseItemsSum,
  });

  final List<ExpenseItemDraft> items;
  final List<ExpenseCategory> categories;

  /// Ukupan iznos računa iz obrasca (za provjeru zbroja), ako je unesen.
  final int? totalCents;
  final ValueChanged<List<ExpenseItemDraft>> onChanged;
  final ValueChanged<int> onUseItemsSum;

  Future<void> _edit(BuildContext context, int? index) async {
    final result = await showDialog<_ItemEditResult>(
      context: context,
      builder: (_) => _ItemDialog(
        initial: index == null ? null : items[index],
        categories: categories,
      ),
    );
    if (result == null) return;
    final next = [...items];
    if (result.delete) {
      if (index != null) next.removeAt(index);
    } else if (index == null) {
      next.add(result.item!);
    } else {
      next[index] = result.item!;
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final sum = items.fold<int>(0, (s, i) => s + i.totalCents);
    final mismatch =
        items.isNotEmpty && totalCents != null && sum != totalCents;
    final names = {for (final c in categories) c.id: c};

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${AppStrings.items} (${items.length})',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (items.isNotEmpty)
                    Text(
                      formatCents(sum),
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  IconButton(
                    tooltip: AppStrings.addItem,
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => _edit(context, null),
                  ),
                ],
              ),
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  AppStrings.noItemsHint,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            for (var i = 0; i < items.length; i++)
              ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                leading: Icon(
                  categoryIcon(names[items[i].categoryId]?.icon),
                  size: 20,
                  color: categoryColor(names[items[i].categoryId]?.color, context),
                ),
                title: Text(items[i].name),
                subtitle: items[i].unitPriceCents == null ||
                        items[i].quantity == 1
                    ? null
                    : Text(
                        '${formatQuantity(items[i].quantity)} × '
                        '${formatCents(items[i].unitPriceCents!)}',
                      ),
                trailing: Text(formatCents(items[i].totalCents)),
                onTap: () => _edit(context, i),
              ),
            if (mismatch)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 18,
                      color: AppColors.unpaid,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.itemsSumMismatch(sum, totalCents!),
                        style: textTheme.bodySmall,
                      ),
                    ),
                    TextButton(
                      onPressed: () => onUseItemsSum(sum),
                      child: const Text(AppStrings.useItemsSum),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ItemEditResult {
  const _ItemEditResult.save(this.item) : delete = false;
  const _ItemEditResult.delete() : item = null, delete = true;

  final ExpenseItemDraft? item;
  final bool delete;
}

class _ItemDialog extends StatefulWidget {
  const _ItemDialog({required this.initial, required this.categories});

  final ExpenseItemDraft? initial;
  final List<ExpenseCategory> categories;

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _quantity;
  late final TextEditingController _unitPrice;
  late final TextEditingController _total;
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _name = TextEditingController(text: i?.name ?? '');
    _quantity = TextEditingController(
      text: i == null ? '1' : formatQuantity(i.quantity),
    );
    _unitPrice = TextEditingController(
      text: i?.unitPriceCents == null ? '' : centsToInput(i!.unitPriceCents!),
    );
    _total = TextEditingController(
      text: i == null ? '' : centsToInput(i.totalCents),
    );
    _categoryId = widget.categories.any((c) => c.id == i?.categoryId)
        ? i?.categoryId
        : null;
    _quantity.addListener(_recalculate);
    _unitPrice.addListener(_recalculate);
  }

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _unitPrice.dispose();
    _total.dispose();
    super.dispose();
  }

  double? get _qty => double.tryParse(_quantity.text.trim().replaceAll(',', '.'));

  /// Količina × jedinična cijena → ukupno (ako su oba ispravna).
  void _recalculate() {
    final qty = _qty;
    final unit = parseMoneyToCents(_unitPrice.text);
    if (qty == null || unit == null || qty <= 0) return;
    _total.text = centsToInput((qty * unit).round());
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      _ItemEditResult.save(
        ExpenseItemDraft(
          name: _name.text.trim(),
          quantity: _qty ?? 1,
          unitPriceCents: parseMoneyToCents(_unitPrice.text),
          totalCents: _signedCents(_total.text)!,
          categoryId: _categoryId,
        ),
      ),
    );
  }

  static int? _signedCents(String text) {
    final t = text.trim();
    final negative = t.startsWith('-');
    final cents = parseMoneyToCents(negative ? t.substring(1) : t);
    if (cents == null) return null;
    return negative ? -cents : cents;
  }

  @override
  Widget build(BuildContext context) {
    const decimal = TextInputType.numberWithOptions(decimal: true);
    final amountFormatter = FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'));
    const gap = SizedBox(height: 12);

    return AlertDialog(
      title: Text(widget.initial == null ? AppStrings.addItem : AppStrings.editItem),
      scrollable: true,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              autofocus: widget.initial == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: AppStrings.itemName),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? AppStrings.itemNameRequired
                  : null,
            ),
            gap,
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantity,
                    keyboardType: decimal,
                    inputFormatters: [amountFormatter],
                    decoration: const InputDecoration(
                      labelText: AppStrings.quantity,
                    ),
                    validator: (v) {
                      final q = double.tryParse(
                        (v ?? '').trim().replaceAll(',', '.'),
                      );
                      return (q == null || q <= 0)
                          ? AppStrings.quantityInvalid
                          : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _unitPrice,
                    keyboardType: decimal,
                    inputFormatters: [amountFormatter],
                    decoration: const InputDecoration(
                      labelText: AppStrings.unitPrice,
                      suffixText: '€',
                    ),
                  ),
                ),
              ],
            ),
            gap,
            TextFormField(
              controller: _total,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\-]')),
              ],
              decoration: const InputDecoration(
                labelText: AppStrings.itemTotal,
                helperText: AppStrings.itemTotalHelper,
                suffixText: '€',
              ),
              validator: (v) => _signedCents(v ?? '') == null
                  ? AppStrings.amountInvalid
                  : null,
            ),
            gap,
            DropdownButtonFormField<String?>(
              initialValue: _categoryId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: AppStrings.itemCategory,
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text(AppStrings.uncategorized),
                ),
                for (final c in widget.categories)
                  DropdownMenuItem<String?>(value: c.id, child: Text(c.name)),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.initial != null)
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(const _ItemEditResult.delete()),
            style: TextButton.styleFrom(foregroundColor: AppColors.overdue),
            child: const Text(AppStrings.delete),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        TextButton(onPressed: _save, child: const Text(AppStrings.save)),
      ],
    );
  }
}

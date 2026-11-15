import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/expense.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_chip.dart';
import '../application/expense_providers.dart';

/// Detalji računa s promjenom statusa, uređivanjem i brisanjem.
class ExpenseDetailScreen extends ConsumerWidget {
  const ExpenseDetailScreen({super.key, required this.expenseId});

  final String expenseId;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.deleteExpenseTitle),
        content: const Text(AppStrings.deleteExpenseMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.overdue,
              minimumSize: const Size(64, 40),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(expenseActionsProvider).delete(expenseId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text(AppStrings.expenseDeleted)));
    context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(expenseByIdProvider(expenseId));
    final expense = value.dataOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.expenseDetail),
        actions: expense == null
            ? null
            : [
                IconButton(
                  tooltip: AppStrings.edit,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () =>
                      context.push(AppRoutes.editExpense(expenseId)),
                ),
                IconButton(
                  tooltip: AppStrings.delete,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
      ),
      body: AsyncValueWidget<Expense?>(
        value: value,
        data: (e) => e == null
            ? const Center(
                child: EmptyState(message: AppStrings.expenseNotFound),
              )
            : _DetailBody(expense: e),
      ),
    );
  }
}

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({required this.expense});

  final Expense expense;

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  bool _updating = false;

  Future<void> _toggleStatus() async {
    final e = widget.expense;
    final next = e.isPaid ? PaymentStatus.unpaid : PaymentStatus.paid;
    setState(() => _updating = true);
    try {
      await ref.read(expenseActionsProvider).setStatus(e.id, next);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.saveFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.expense;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.merchantName,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formatCents(e.totalCents),
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                StatusChip(status: e.status, dueDate: e.dueDate),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                _DetailRow(
                  label: AppStrings.category,
                  value: e.categoryName ?? AppStrings.uncategorized,
                ),
                _DetailRow(label: AppStrings.expenseType, value: e.type.label),
                _DetailRow(
                  label: AppStrings.issueDate,
                  value: formatDate(e.issueDate),
                ),
                if (e.dueDate != null)
                  _DetailRow(
                    label: AppStrings.dueDate,
                    value: formatDate(e.dueDate!),
                  ),
                if (e.paidDate != null)
                  _DetailRow(
                    label: AppStrings.paidDate,
                    value: formatDate(e.paidDate!),
                  ),
                if (e.invoiceNumber != null)
                  _DetailRow(
                    label: AppStrings.invoiceNumber,
                    value: e.invoiceNumber!,
                  ),
                if (e.note != null)
                  _DetailRow(label: AppStrings.note, value: e.note!),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (e.isPaid)
          OutlinedButton.icon(
            onPressed: _updating ? null : _toggleStatus,
            icon: const Icon(Icons.undo),
            label: const Text(AppStrings.markUnpaid),
          )
        else
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.paid),
            onPressed: _updating ? null : _toggleStatus,
            icon: const Icon(Icons.check),
            label: const Text(AppStrings.markPaid),
          ),
        const SizedBox(height: 16),
        Text(
          '${AppStrings.createdAt}: ${formatDateTime(e.createdAt)}\n'
          '${AppStrings.updatedAt}: ${formatDateTime(e.updatedAt)}',
          style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
          ),
          Expanded(child: Text(value, style: textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/expense.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../../shared/widgets/empty_state.dart';
import '../application/expense_providers.dart';
import 'widgets/expense_tile.dart';

/// Popis računa s pretraživanjem i filtrima.
class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(expenseFilterProvider).query,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(expenseFilterProvider);
    final notifier = ref.read(expenseFilterProvider.notifier);
    final expenses = ref.watch(expenseListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.expensesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.newExpense),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.newExpense),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: notifier.setQuery,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: AppStrings.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: filter.query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: AppStrings.clearSearch,
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          notifier.setQuery('');
                        },
                      ),
              ),
            ),
          ),
          _MonthSelector(month: filter.month, onChanged: notifier.setMonth),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final option in <PaymentStatus?>[
                  null,
                  PaymentStatus.paid,
                  PaymentStatus.unpaid,
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(option?.label ?? AppStrings.filterAll),
                      selected: filter.status == option,
                      onSelected: (_) => notifier.setStatus(option),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: AsyncValueWidget<List<Expense>>(
              value: expenses,
              data: (list) => list.isEmpty
                  ? const Center(
                      child: EmptyState(
                        icon: Icons.receipt_long_outlined,
                        message: AppStrings.noExpensesForFilter,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: list.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) return _ListSummary(expenses: list);
                        return ExpenseTile(expense: list[index - 1]);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({required this.month, required this.onChanged});

  final DateTime? month;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final base = month ?? monthStart(DateTime.now());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            tooltip: AppStrings.previousMonth,
            icon: const Icon(Icons.chevron_left),
            onPressed: () => onChanged(addMonths(base, month == null ? 0 : -1)),
          ),
          Expanded(
            child: Center(
              child: TextButton(
                // Dodir prebacuje između "Svi mjeseci" i tekućeg mjeseca.
                onPressed: () =>
                    onChanged(month == null ? monthStart(DateTime.now()) : null),
                child: Text(
                  month == null ? AppStrings.allMonths : formatMonthYear(month!),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: AppStrings.nextMonth,
            icon: const Icon(Icons.chevron_right),
            onPressed: () => onChanged(addMonths(base, month == null ? 0 : 1)),
          ),
        ],
      ),
    );
  }
}

class _ListSummary extends StatelessWidget {
  const _ListSummary({required this.expenses});

  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
    final total = expenses.fold<int>(0, (sum, e) => sum + e.totalCents);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Text(
        '${AppStrings.expenseCount(expenses.length)} · '
        '${AppStrings.total}: ${formatCents(total)}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

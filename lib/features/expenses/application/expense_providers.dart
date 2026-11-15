import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/enums.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/expense_category.dart';
import '../../../data/models/expense_filter.dart';
import '../../../data/models/merchant.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/expense_repository.dart';

/// Trenutni filter popisa računa.
class ExpenseFilterNotifier extends Notifier<ExpenseFilter> {
  @override
  ExpenseFilter build() => const ExpenseFilter();

  void setQuery(String query) => state = state.copyWith(query: query);

  void setStatus(PaymentStatus? status) =>
      state = state.copyWith(status: status, clearStatus: status == null);

  void setMonth(DateTime? month) =>
      state = state.copyWith(month: month, clearMonth: month == null);
}

final expenseFilterProvider =
    NotifierProvider<ExpenseFilterNotifier, ExpenseFilter>(
      ExpenseFilterNotifier.new,
    );

final expenseListProvider = FutureProvider.autoDispose<List<Expense>>((ref) {
  ref.watch(dataRevisionProvider);
  final filter = ref.watch(expenseFilterProvider);
  return ref.watch(expenseRepositoryProvider).getExpenses(filter);
});

final expenseByIdProvider = FutureProvider.autoDispose.family<Expense?, String>(
  (ref, id) {
    ref.watch(dataRevisionProvider);
    return ref.watch(expenseRepositoryProvider).getById(id);
  },
);

final expenseCategoriesProvider =
    FutureProvider.autoDispose<List<ExpenseCategory>>((ref) {
      ref.watch(dataRevisionProvider);
      return ref.watch(categoryRepositoryProvider).getExpenseCategories();
    });

final merchantsProvider = FutureProvider.autoDispose<List<Merchant>>((ref) {
  ref.watch(dataRevisionProvider);
  return ref.watch(merchantRepositoryProvider).getAll();
});

/// Radnje nad računima. Nakon svake izmjene osvježava sve povezane prikaze.
class ExpenseActions {
  ExpenseActions({
    required ExpenseRepository repository,
    required void Function() onChanged,
  }) : _repository = repository,
       _onChanged = onChanged;

  final ExpenseRepository _repository;
  final void Function() _onChanged;

  Future<String> create(ExpenseDraft draft) async {
    final id = await _repository.create(draft);
    _onChanged();
    return id;
  }

  Future<void> update(String id, ExpenseDraft draft) async {
    await _repository.update(id, draft);
    _onChanged();
  }

  Future<void> setStatus(String id, PaymentStatus status) async {
    await _repository.setStatus(id, status);
    _onChanged();
  }

  Future<void> delete(String id) async {
    await _repository.softDelete(id);
    _onChanged();
  }
}

final expenseActionsProvider = Provider<ExpenseActions>(
  (ref) => ExpenseActions(
    repository: ref.watch(expenseRepositoryProvider),
    onChanged: () => ref.read(dataRevisionProvider.notifier).bump(),
  ),
);

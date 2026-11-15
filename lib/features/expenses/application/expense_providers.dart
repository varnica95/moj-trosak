import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/attachment_storage.dart';
import '../../../data/models/attachment.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/expense_category.dart';
import '../../../data/models/expense_filter.dart';
import '../../../data/models/expense_item.dart';
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

final itemCategoriesProvider =
    FutureProvider.autoDispose<List<ExpenseCategory>>((ref) {
      ref.watch(dataRevisionProvider);
      return ref.watch(categoryRepositoryProvider).getItemCategories();
    });

final expenseItemsProvider = FutureProvider.autoDispose
    .family<List<ExpenseItem>, String>((ref, id) {
      ref.watch(dataRevisionProvider);
      return ref.watch(expenseRepositoryProvider).getItems(id);
    });

final expenseAttachmentsProvider = FutureProvider.autoDispose
    .family<List<Attachment>, String>((ref, id) {
      ref.watch(dataRevisionProvider);
      return ref.watch(expenseRepositoryProvider).getAttachments(id);
    });

final merchantsProvider = FutureProvider.autoDispose<List<Merchant>>((ref) {
  ref.watch(dataRevisionProvider);
  return ref.watch(merchantRepositoryProvider).getAll();
});

/// Radnje nad računima. Nakon svake izmjene osvježava sve povezane prikaze.
class ExpenseActions {
  ExpenseActions({
    required ExpenseRepository repository,
    required AttachmentStorage storage,
    required void Function() onChanged,
  }) : _repository = repository,
       _storage = storage,
       _onChanged = onChanged;

  final ExpenseRepository _repository;
  final AttachmentStorage _storage;
  final void Function() _onChanged;

  /// Kopira privremene fotografije (kamera/galerija) u trajnu pohranu.
  Future<List<StoredFile>> storeFiles(List<String> paths) async => [
    for (final path in paths) await _storage.store(path),
  ];

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
    storage: ref.watch(attachmentStorageProvider),
    onChanged: () => ref.read(dataRevisionProvider.notifier).bump(),
  ),
);

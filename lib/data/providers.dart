import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/attachment_storage.dart';
import 'database/app_database.dart';
import 'repositories/category_repository.dart';
import 'repositories/expense_repository.dart';
import 'repositories/merchant_repository.dart';

/// Otvorena baza. Postavlja se u `main.dart` putem `overrideWithValue`.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError(
    'appDatabaseProvider mora biti postavljen u ProviderScope overrides.',
  ),
);

final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => ExpenseRepository(ref.watch(appDatabaseProvider)),
);

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(ref.watch(appDatabaseProvider)),
);

final merchantRepositoryProvider = Provider<MerchantRepository>(
  (ref) => MerchantRepository(ref.watch(appDatabaseProvider)),
);

final attachmentStorageProvider = Provider<AttachmentStorage>(
  (ref) => AttachmentStorage(),
);

/// Brojač izmjena podataka. Svi upiti nad bazom ga prate, pa se nakon
/// svake izmjene automatski ponovno učitavaju.
class DataRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state = state + 1;
}

final dataRevisionProvider = NotifierProvider<DataRevision, int>(
  DataRevision.new,
);

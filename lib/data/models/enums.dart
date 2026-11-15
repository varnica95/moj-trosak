import '../../core/l10n/app_strings.dart';

/// Status plaćanja računa.
enum PaymentStatus {
  paid('paid'),
  unpaid('unpaid'),

  /// Pripremljeno za buduću verziju (djelomična plaćanja). Shema baze to već
  /// podržava kroz stupac `paid_cents`, ali UI ga još ne nudi.
  partiallyPaid('partially_paid');

  const PaymentStatus(this.dbValue);
  final String dbValue;

  static PaymentStatus fromDb(String? value) => PaymentStatus.values.firstWhere(
    (e) => e.dbValue == value,
    orElse: () => PaymentStatus.unpaid,
  );

  String get label => switch (this) {
    PaymentStatus.paid => AppStrings.statusPaid,
    PaymentStatus.unpaid => AppStrings.statusUnpaid,
    PaymentStatus.partiallyPaid => AppStrings.statusPartiallyPaid,
  };
}

/// Vrsta računa.
enum ExpenseType {
  utility('utility'),
  retail('retail'),
  other('other');

  const ExpenseType(this.dbValue);
  final String dbValue;

  static ExpenseType fromDb(String? value) => ExpenseType.values.firstWhere(
    (e) => e.dbValue == value,
    orElse: () => ExpenseType.other,
  );

  String get label => switch (this) {
    ExpenseType.utility => AppStrings.typeUtility,
    ExpenseType.retail => AppStrings.typeRetail,
    ExpenseType.other => AppStrings.typeOther,
  };
}

/// Skupina kategorije.
enum CategoryGroup {
  /// Režijski troškovi (struja, voda, plin...).
  utility('utility'),

  /// Maloprodaja (namirnice, drogerija...).
  retail('retail'),

  /// Opći troškovi.
  general('general'),

  /// Kategorije pojedinačnih artikala (FAZA 3 – OCR stavki).
  item('item');

  const CategoryGroup(this.dbValue);
  final String dbValue;

  static CategoryGroup fromDb(String? value) => CategoryGroup.values.firstWhere(
    (e) => e.dbValue == value,
    orElse: () => CategoryGroup.general,
  );

  /// Vrsta računa koja prirodno odgovara ovoj skupini.
  ExpenseType? get expenseType => switch (this) {
    CategoryGroup.utility => ExpenseType.utility,
    CategoryGroup.retail => ExpenseType.retail,
    CategoryGroup.general => ExpenseType.other,
    CategoryGroup.item => null,
  };
}

/// Status sinkronizacije zapisa s oblakom (FAZA 5).
enum SyncStatus {
  pending('pending'),
  synced('synced'),
  conflict('conflict');

  const SyncStatus(this.dbValue);
  final String dbValue;

  static SyncStatus fromDb(String? value) => SyncStatus.values.firstWhere(
    (e) => e.dbValue == value,
    orElse: () => SyncStatus.pending,
  );
}

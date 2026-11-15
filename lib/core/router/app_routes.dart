/// Putanje unutar aplikacije.
abstract final class AppRoutes {
  static const String dashboard = '/';
  static const String expenses = '/expenses';
  static const String newExpense = '/expenses/new';
  static const String scan = '/scan';
  static const String scanQr = '/scan/qr';
  static const String statistics = '/statistics';
  static const String settings = '/settings';

  static String expenseDetail(String id) => '/expenses/$id';
  static String editExpense(String id) => '/expenses/$id/edit';
}

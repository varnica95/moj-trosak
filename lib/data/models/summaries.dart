import 'expense.dart';

/// Ukupna potrošnja jedne kategorije u razdoblju.
class CategoryTotal {
  const CategoryTotal({
    required this.totalCents,
    required this.count,
    this.categoryId,
    this.name,
    this.color,
    this.icon,
  });

  final String? categoryId;
  final String? name;
  final int? color;
  final String? icon;
  final int totalCents;
  final int count;
}

/// Ukupna potrošnja u jednom mjesecu.
class MonthlyTotal {
  const MonthlyTotal({
    required this.month,
    required this.totalCents,
    required this.count,
  });

  final DateTime month;
  final int totalCents;
  final int count;
}

/// Usporedba dva mjeseca.
class MonthComparison {
  const MonthComparison({required this.current, required this.previous});

  final MonthlyTotal current;
  final MonthlyTotal previous;

  int get differenceCents => current.totalCents - previous.totalCents;
}

/// Podaci za početni ekran.
class DashboardSummary {
  const DashboardSummary({
    required this.month,
    required this.monthTotalCents,
    required this.monthCount,
    required this.monthPaidCents,
    required this.monthPaidCount,
    required this.openUnpaidCents,
    required this.openUnpaidCount,
    required this.overdueCount,
    required this.categoryTotals,
    required this.recent,
  });

  final DateTime month;
  final int monthTotalCents;
  final int monthCount;
  final int monthPaidCents;
  final int monthPaidCount;

  /// Svi otvoreni (neplaćeni) računi, neovisno o mjesecu.
  final int openUnpaidCents;
  final int openUnpaidCount;
  final int overdueCount;
  final List<CategoryTotal> categoryTotals;
  final List<Expense> recent;
}

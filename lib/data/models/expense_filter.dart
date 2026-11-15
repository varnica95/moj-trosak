import 'enums.dart';

/// Kriteriji pretraživanja i filtriranja popisa računa.
class ExpenseFilter {
  const ExpenseFilter({
    this.query = '',
    this.status,
    this.month,
    this.minCents,
    this.maxCents,
  });

  /// Slobodni tekst: naziv trgovine, kategorija, broj računa ili napomena.
  final String query;
  final PaymentStatus? status;

  /// Ako je postavljen, prikazuju se samo računi iz tog mjeseca.
  final DateTime? month;
  final int? minCents;
  final int? maxCents;

  ExpenseFilter copyWith({
    String? query,
    PaymentStatus? status,
    DateTime? month,
    int? minCents,
    int? maxCents,
    bool clearStatus = false,
    bool clearMonth = false,
    bool clearAmounts = false,
  }) => ExpenseFilter(
    query: query ?? this.query,
    status: clearStatus ? null : (status ?? this.status),
    month: clearMonth ? null : (month ?? this.month),
    minCents: clearAmounts ? null : (minCents ?? this.minCents),
    maxCents: clearAmounts ? null : (maxCents ?? this.maxCents),
  );
}

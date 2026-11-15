import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/summaries.dart';
import '../../../data/providers.dart';

/// Ukupno po mjesecima za odabranu godinu.
final monthlyTotalsProvider = FutureProvider.autoDispose
    .family<List<MonthlyTotal>, int>((ref, year) {
      ref.watch(dataRevisionProvider);
      return ref.watch(expenseRepositoryProvider).getMonthlyTotals(year);
    });

/// Tekući mjesec u usporedbi s prethodnim.
final monthComparisonProvider = FutureProvider.autoDispose<MonthComparison>((
  ref,
) {
  ref.watch(dataRevisionProvider);
  return ref
      .watch(expenseRepositoryProvider)
      .compareWithPreviousMonth(DateTime.now());
});

/// Potrošnja po kategorijama za mjesec (ključ: prvi dan mjeseca).
final categoryTotalsProvider = FutureProvider.autoDispose
    .family<List<CategoryTotal>, DateTime>((ref, month) {
      ref.watch(dataRevisionProvider);
      return ref.watch(expenseRepositoryProvider).getCategoryTotals(month);
    });

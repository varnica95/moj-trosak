import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/summaries.dart';
import '../../../data/providers.dart';

/// Sažetak za početni ekran (tekući mjesec).
final dashboardSummaryProvider = FutureProvider.autoDispose<DashboardSummary>((
  ref,
) {
  ref.watch(dataRevisionProvider);
  return ref.watch(expenseRepositoryProvider).getDashboardSummary(DateTime.now());
});

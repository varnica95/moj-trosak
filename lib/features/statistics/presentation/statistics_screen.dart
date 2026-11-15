import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/summaries.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../../shared/widgets/category_breakdown.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_card.dart';
import '../application/statistics_providers.dart';

/// Osnovna statistika (FAZA 1). Grafovi s fl_chart dolaze u FAZI 4.
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  int _year = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final currentMonth = monthStart(DateTime.now());
    final comparison = ref.watch(monthComparisonProvider);
    final monthly = ref.watch(monthlyTotalsProvider(_year));
    final byCategory = ref.watch(categoryTotalsProvider(currentMonth));

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.navStatistics)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SectionCard(
            title: AppStrings.monthComparison,
            child: AsyncValueWidget<MonthComparison>(
              value: comparison,
              data: (c) => _ComparisonView(comparison: c),
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: '${AppStrings.byCategory} – ${formatMonthName(currentMonth)}',
            child: AsyncValueWidget<List<CategoryTotal>>(
              value: byCategory,
              data: (totals) => totals.isEmpty
                  ? const EmptyState(message: AppStrings.noExpensesThisMonth)
                  : CategoryBreakdown(
                      totals: totals,
                      totalCents: totals.fold(0, (s, t) => s + t.totalCents),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: '${AppStrings.byMonth} $_year.',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: AppStrings.previousYear,
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() => _year--),
                ),
                IconButton(
                  tooltip: AppStrings.nextYear,
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _year >= DateTime.now().year
                      ? null
                      : () => setState(() => _year++),
                ),
              ],
            ),
            child: AsyncValueWidget<List<MonthlyTotal>>(
              value: monthly,
              data: (months) => _MonthlyBars(months: months),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonView extends StatelessWidget {
  const _ComparisonView({required this.comparison});

  final MonthComparison comparison;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final diff = comparison.differenceCents;
    // Veća potrošnja = crveno, manja = zeleno.
    final diffColor = diff > 0
        ? AppColors.overdue
        : diff < 0
        ? AppColors.paid
        : AppColors.textMuted;

    Widget row(String label, String value, {TextStyle? style}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: textTheme.bodyMedium)),
          Text(value, style: style ?? textTheme.bodyMedium),
        ],
      ),
    );

    return Column(
      children: [
        row(
          formatMonthYear(comparison.previous.month),
          formatCents(comparison.previous.totalCents),
        ),
        row(
          formatMonthYear(comparison.current.month),
          formatCents(comparison.current.totalCents),
        ),
        const Divider(),
        row(
          AppStrings.difference,
          formatSignedCents(diff),
          style: textTheme.titleMedium?.copyWith(
            color: diffColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MonthlyBars extends StatelessWidget {
  const _MonthlyBars({required this.months});

  final List<MonthlyTotal> months;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final max = months.fold<int>(0, (m, t) => t.totalCents > m ? t.totalCents : m);
    final yearTotal = months.fold<int>(0, (s, t) => s + t.totalCents);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final m in months)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text(formatMonthShort(m.month), style: textTheme.bodySmall),
                ),
                Expanded(
                  child: LinearProgressIndicator(
                    value: max == 0 ? 0 : m.totalCents / max,
                    minHeight: 10,
                    color: AppColors.primary,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    formatCents(m.totalCents),
                    textAlign: TextAlign.right,
                    style: textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        const Divider(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.yearTotal,
                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              formatCents(yearTotal),
              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}

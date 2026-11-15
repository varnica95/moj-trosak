import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/summaries.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../../shared/widgets/category_breakdown.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_card.dart';
import '../../expenses/presentation/widgets/expense_tile.dart';
import '../application/dashboard_providers.dart';

/// Početni ekran.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appName)),
      body: AsyncValueWidget<DashboardSummary>(
        value: summary,
        data: (s) => RefreshIndicator(
          onRefresh: () => ref.refresh(dashboardSummaryProvider.future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _MonthTotalCard(summary: s),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: AppStrings.paidThisMonth,
                      amountCents: s.monthPaidCents,
                      count: s.monthPaidCount,
                      color: AppColors.paid,
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: AppStrings.unpaidOpen,
                      amountCents: s.openUnpaidCents,
                      count: s.openUnpaidCount,
                      color: AppColors.unpaid,
                      icon: Icons.schedule,
                    ),
                  ),
                ],
              ),
              if (s.overdueCount > 0) ...[
                const SizedBox(height: 12),
                _OverdueBanner(count: s.overdueCount),
              ],
              const SizedBox(height: 12),
              const _QuickActions(),
              const SizedBox(height: 16),
              SectionCard(
                title: AppStrings.byCategoryThisMonth,
                child: s.categoryTotals.isEmpty
                    ? const EmptyState(
                        icon: Icons.pie_chart_outline,
                        message: AppStrings.noExpensesThisMonth,
                      )
                    : CategoryBreakdown(
                        totals: s.categoryTotals,
                        totalCents: s.monthTotalCents,
                      ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: AppStrings.recentExpenses,
                trailing: TextButton(
                  onPressed: () => context.go(AppRoutes.expenses),
                  child: const Text(AppStrings.seeAll),
                ),
                childPadding: const EdgeInsets.only(bottom: 8),
                child: s.recent.isEmpty
                    ? const EmptyState(message: AppStrings.noExpensesYet)
                    : Column(
                        children: [
                          for (final e in s.recent) ExpenseTile(expense: e),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthTotalCard extends StatelessWidget {
  const _MonthTotalCard({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const onPrimary = Colors.white;
    return Card(
      color: AppColors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatMonthYear(summary.month),
              style: textTheme.bodyMedium?.copyWith(
                color: onPrimary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.totalExpenses,
              style: textTheme.titleMedium?.copyWith(color: onPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              formatCents(summary.monthTotalCents),
              style: textTheme.headlineLarge?.copyWith(
                color: onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.expenseCount(summary.monthCount),
              style: textTheme.bodySmall?.copyWith(
                color: onPrimary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.amountCents,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String label;
  final int amountCents;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatCents(amountCents),
                style: textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(AppStrings.expenseCount(count), style: textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _OverdueBanner extends StatelessWidget {
  const _OverdueBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.overdue.withValues(alpha: 0.08),
      child: ListTile(
        leading: const Icon(Icons.warning_amber_rounded, color: AppColors.overdue),
        title: Text(AppStrings.overdueBanner(count)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go(AppRoutes.expenses),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => context.push(AppRoutes.newExpense),
            icon: const Icon(Icons.edit_note),
            label: const Text(AppStrings.manualEntry),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          // Kartica "Skeniraj": QR/barkod ili fotografija računa (OCR).
          child: OutlinedButton.icon(
            onPressed: () => context.go(AppRoutes.scan),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text(AppStrings.scan),
          ),
        ),
      ],
    );
  }
}

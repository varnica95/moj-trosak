import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moj_trosak/core/l10n/app_strings.dart';
import 'package:moj_trosak/core/theme/app_theme.dart';
import 'package:moj_trosak/data/models/enums.dart';
import 'package:moj_trosak/data/models/expense.dart';
import 'package:moj_trosak/data/models/summaries.dart';
import 'package:moj_trosak/features/dashboard/application/dashboard_providers.dart';
import 'package:moj_trosak/features/dashboard/presentation/dashboard_screen.dart';

Widget _wrap(DashboardSummary summary) => ProviderScope(
  overrides: [dashboardSummaryProvider.overrideWith((ref) async => summary)],
  child: MaterialApp(
    theme: AppTheme.light(),
    locale: const Locale('hr'),
    supportedLocales: const [Locale('hr')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: const DashboardScreen(),
  ),
);

void main() {
  setUpAll(() => initializeDateFormatting('hr'));

  testWidgets('prazan dashboard prikazuje nule i poruke', (tester) async {
    await tester.pumpWidget(
      _wrap(
        DashboardSummary(
          month: DateTime(2026, 11),
          monthTotalCents: 0,
          monthCount: 0,
          monthPaidCents: 0,
          monthPaidCount: 0,
          openUnpaidCents: 0,
          openUnpaidCount: 0,
          overdueCount: 0,
          categoryTotals: const [],
          recent: const [],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.text('Studeni 2026.'), findsOneWidget);
    expect(find.text('0,00 €'), findsNWidgets(3));
    expect(find.text(AppStrings.manualEntry), findsOneWidget);
    expect(find.text(AppStrings.noExpensesThisMonth), findsOneWidget);
  });

  testWidgets('dashboard prikazuje iznose, dospjele i najnovije račune', (
    tester,
  ) async {
    final expense = Expense(
      id: 'e1',
      merchantId: 'm1',
      merchantName: 'Konzum',
      categoryName: 'Namirnice',
      type: ExpenseType.retail,
      issueDate: DateTime(2026, 11, 10),
      totalCents: 125000,
      status: PaymentStatus.paid,
      createdAt: DateTime(2026, 11, 10),
      updatedAt: DateTime(2026, 11, 10),
    );

    await tester.pumpWidget(
      _wrap(
        DashboardSummary(
          month: DateTime(2026, 11),
          monthTotalCents: 125000,
          monthCount: 1,
          monthPaidCents: 125000,
          monthPaidCount: 1,
          openUnpaidCents: 4550,
          openUnpaidCount: 1,
          overdueCount: 1,
          categoryTotals: const [
            CategoryTotal(name: 'Namirnice', totalCents: 125000, count: 1),
          ],
          recent: [expense],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('45,50 €'), findsOneWidget);
    expect(find.text(AppStrings.overdueBanner(1)), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Konzum'), 200);
    expect(find.text('Konzum'), findsOneWidget);
    expect(find.text('Namirnice · 10.11.2026.'), findsOneWidget);
  });
}

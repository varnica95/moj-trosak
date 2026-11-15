import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moj_trosak/core/utils/ids.dart';
import 'package:moj_trosak/data/database/app_database.dart';
import 'package:moj_trosak/data/models/enums.dart';
import 'package:moj_trosak/data/models/expense.dart';
import 'package:moj_trosak/data/models/expense_filter.dart';
import 'package:moj_trosak/data/repositories/category_repository.dart';
import 'package:moj_trosak/data/repositories/expense_repository.dart';
import 'package:moj_trosak/data/repositories/merchant_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Testovi rade nad stvarnom SQLite bazom u memoriji (sqflite_common_ffi).
void main() {
  late AppDatabase database;
  late ExpenseRepository repo;
  final now = DateTime(2026, 11, 15, 10, 30);

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
      singleInstance: false,
    );
    repo = ExpenseRepository(database, clock: () => now);
  });

  tearDown(() => database.close());

  Future<int> queueCount([String? table]) async {
    final rows = await database.db.rawQuery(
      table == null
          ? 'SELECT COUNT(*) AS c FROM sync_queue'
          : 'SELECT COUNT(*) AS c FROM sync_queue WHERE entity_type = ?',
      table == null ? null : [table],
    );
    return (rows.first['c']! as num).toInt();
  }

  ExpenseDraft draft({
    String merchant = 'Konzum',
    int cents = 4599,
    PaymentStatus status = PaymentStatus.paid,
    DateTime? issueDate,
    DateTime? dueDate,
    String? categoryKey = 'groceries',
    ExpenseType type = ExpenseType.retail,
  }) => ExpenseDraft(
    merchantName: merchant,
    categoryId: categoryKey == null ? null : Ids.category(categoryKey),
    type: type,
    issueDate: issueDate ?? DateTime(2026, 11, 10),
    dueDate: dueDate,
    totalCents: cents,
    status: status,
  );

  test('početni podaci: kategorije i poznati izdavatelji', () async {
    final categories = await CategoryRepository(
      database,
    ).getExpenseCategories();
    final items = await CategoryRepository(database).getItemCategories();
    final merchants = await MerchantRepository(database).getAll();

    expect(categories.map((c) => c.name), contains('Struja'));
    expect(categories.every((c) => c.group != CategoryGroup.item), isTrue);
    expect(items.map((c) => c.name), contains('Hrana'));
    expect(
      merchants.map((m) => m.name),
      containsAll(['HEP', 'Konzum', 'Lidl', 'DM', 'Zagrebački holding']),
    );
    expect(await queueCount(), 0, reason: 'seed se ne sinkronizira');
  });

  test('kreiranje računa sprema podatke i stavlja ga u red', () async {
    final id = await repo.create(
      draft(merchant: 'Pekara Kruh', categoryKey: 'other'),
    );
    final e = await repo.getById(id);

    expect(e, isNotNull);
    expect(e!.merchantName, 'Pekara Kruh');
    expect(e.totalCents, 4599);
    expect(e.status, PaymentStatus.paid);
    expect(e.paidDate, DateTime(2026, 11, 15), reason: 'zadano: danas');
    expect(e.paidCents, 4599);
    expect(e.version, 1);
    expect(e.syncStatus, SyncStatus.pending);
    expect(await queueCount('expenses'), 1);
    expect(await queueCount('merchants'), 1, reason: 'nova trgovina');
  });

  test('isti izdavatelj s drugačijim pisanjem se ne duplicira', () async {
    await repo.create(draft(merchant: 'Konzum'));
    await repo.create(draft(merchant: '  KONZUM  '));
    final merchants = await MerchantRepository(database).getAll();
    expect(merchants.where((m) => m.name.toLowerCase() == 'konzum').length, 1);
    expect(await queueCount('merchants'), 0, reason: 'seed trgovina');
  });

  test('izmjena povećava verziju i ne duplicira zapis u redu', () async {
    final id = await repo.create(draft());
    await repo.update(id, draft(cents: 9999, status: PaymentStatus.unpaid));
    await repo.update(id, draft(cents: 10000, status: PaymentStatus.unpaid));

    final e = (await repo.getById(id))!;
    expect(e.totalCents, 10000);
    expect(e.version, 3);
    expect(e.paidDate, isNull);
    expect(e.paidCents, 0);
    expect(await queueCount('expenses'), 1);

    final row = (await database.db.query(
      'sync_queue',
      where: 'entity_id = ?',
      whereArgs: [id],
    )).first;
    final payload = jsonDecode(row['payload']! as String) as Map<String, dynamic>;
    expect(payload['total_cents'], 10000);
    expect(payload['version'], 3);
  });

  test('ručna promjena statusa', () async {
    final id = await repo.create(draft(status: PaymentStatus.unpaid));
    expect((await repo.getById(id))!.paidDate, isNull);

    await repo.setStatus(id, PaymentStatus.paid);
    var e = (await repo.getById(id))!;
    expect(e.status, PaymentStatus.paid);
    expect(e.paidDate, DateTime(2026, 11, 15));
    expect(e.paidCents, e.totalCents);

    await repo.setStatus(id, PaymentStatus.unpaid);
    e = (await repo.getById(id))!;
    expect(e.status, PaymentStatus.unpaid);
    expect(e.paidDate, isNull);
    expect(e.paidCents, 0);
  });

  test('meko brisanje skriva račun, ali ostavlja tombstone za sync', () async {
    final id = await repo.create(draft());
    await repo.softDelete(id);

    expect(await repo.getById(id), isNull);
    expect(await repo.getExpenses(), isEmpty);

    final raw = await database.db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
    expect(raw.single['deleted_at'], isNotNull);
    final queued = (await database.db.query(
      'sync_queue',
      where: 'entity_id = ?',
      whereArgs: [id],
    )).single;
    final payload = jsonDecode(queued['payload']! as String) as Map<String, dynamic>;
    expect(payload['deleted_at'], isNotNull);
  });

  test('neispravni podaci se odbijaju', () async {
    await expectLater(repo.create(draft(cents: 0)), throwsArgumentError);
    await expectLater(
      repo.create(draft(merchant: '   ')),
      throwsArgumentError,
    );
    expect(await repo.getExpenses(), isEmpty);
  });

  test('filtriranje po statusu, mjesecu, iznosu i tekstu', () async {
    await repo.create(
      draft(
        merchant: 'Zagrebački holding',
        categoryKey: 'communal',
        type: ExpenseType.utility,
        status: PaymentStatus.unpaid,
        cents: 3500,
        issueDate: DateTime(2026, 10, 3),
      ),
    );
    await repo.create(draft(merchant: 'Lidl', cents: 2000));
    await repo.create(draft(merchant: 'DM', categoryKey: 'drugstore', cents: 900));

    expect((await repo.getExpenses()).length, 3);
    expect(
      (await repo.getExpenses(
        const ExpenseFilter(status: PaymentStatus.unpaid),
      )).single.merchantName,
      'Zagrebački holding',
    );
    expect(
      (await repo.getExpenses(ExpenseFilter(month: DateTime(2026, 11)))).length,
      2,
    );
    expect(
      (await repo.getExpenses(const ExpenseFilter(minCents: 1000))).length,
      2,
    );
    // Pretraga s hrvatskim znakovima, neovisno o velikim/malim slovima.
    expect(
      (await repo.getExpenses(
        const ExpenseFilter(query: 'ZAGREBAČKI'),
      )).single.merchantName,
      'Zagrebački holding',
    );
    // Pretraga po nazivu kategorije.
    expect(
      (await repo.getExpenses(
        const ExpenseFilter(query: 'drogerija'),
      )).single.merchantName,
      'DM',
    );
  });

  test('sažetak za početni ekran', () async {
    await repo.create(draft(cents: 10000)); // plaćeno, studeni
    await repo.create(
      draft(
        merchant: 'HEP',
        categoryKey: 'electricity',
        type: ExpenseType.utility,
        cents: 5000,
        status: PaymentStatus.unpaid,
        dueDate: DateTime(2026, 11, 1), // dospjelo
      ),
    );
    await repo.create(
      draft(
        merchant: 'Voda d.o.o.',
        categoryKey: 'water',
        cents: 2500,
        status: PaymentStatus.unpaid,
        issueDate: DateTime(2026, 10, 20), // prošli mjesec, još otvoreno
      ),
    );

    final s = await repo.getDashboardSummary(DateTime(2026, 11));
    expect(s.monthTotalCents, 15000);
    expect(s.monthCount, 2);
    expect(s.monthPaidCents, 10000);
    expect(s.monthPaidCount, 1);
    expect(s.openUnpaidCents, 7500);
    expect(s.openUnpaidCount, 2);
    expect(s.overdueCount, 1);
    expect(s.categoryTotals.first.name, 'Namirnice');
    expect(s.categoryTotals.first.totalCents, 10000);
    expect(s.recent.length, 3);
  });

  test('mjesečni zbrojevi i usporedba mjeseci', () async {
    await repo.create(draft(cents: 125000, issueDate: DateTime(2026, 10, 5)));
    await repo.create(draft(cents: 142000, issueDate: DateTime(2026, 11, 5)));

    final months = await repo.getMonthlyTotals(2026);
    expect(months.length, 12);
    expect(months[9].totalCents, 125000);
    expect(months[10].totalCents, 142000);
    expect(months[0].totalCents, 0);

    final c = await repo.compareWithPreviousMonth(DateTime(2026, 11));
    expect(c.previous.totalCents, 125000);
    expect(c.current.totalCents, 142000);
    expect(c.differenceCents, 17000);
  });

  test('brisanje svih podataka vraća početno stanje', () async {
    await repo.create(draft(merchant: 'Nova trgovina'));
    await database.wipeAllData();

    expect(await repo.getExpenses(), isEmpty);
    expect(await queueCount(), 0);
    final merchants = await MerchantRepository(database).getAll();
    expect(merchants.map((m) => m.name), isNot(contains('Nova trgovina')));
    expect(merchants.map((m) => m.name), contains('Konzum'));
  });
}

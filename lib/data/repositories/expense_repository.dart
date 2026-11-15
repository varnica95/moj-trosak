import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/ids.dart';
import '../database/app_database.dart';
import '../database/sync_queue_writer.dart';
import '../models/enums.dart';
import '../models/expense.dart';
import '../models/expense_filter.dart';
import '../models/summaries.dart';
import 'merchant_repository.dart';

/// Računi: CRUD, status plaćanja, pretraživanje i agregati.
///
/// Svaka izmjena se u istoj transakciji upisuje i u `sync_queue`.
class ExpenseRepository {
  ExpenseRepository(this._database, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _database;
  final DateTime Function() _clock;

  Database get _db => _database.db;

  static const String _table = 'expenses';

  static const String _selectWithJoins = '''
SELECT e.*,
       m.name AS merchant_name,
       c.name AS category_name,
       c.color AS category_color,
       c.icon AS category_icon
FROM expenses e
JOIN merchants m ON m.id = e.merchant_id
LEFT JOIN categories c ON c.id = e.category_id
''';

  // ---------------------------------------------------------------------------
  // Čitanje
  // ---------------------------------------------------------------------------

  Future<List<Expense>> getExpenses([
    ExpenseFilter filter = const ExpenseFilter(),
  ]) async {
    final where = <String>['e.deleted_at IS NULL'];
    final args = <Object?>[];

    if (filter.status != null) {
      where.add('e.payment_status = ?');
      args.add(filter.status!.dbValue);
    }
    if (filter.month != null) {
      final range = monthRangeDb(filter.month!);
      where.add('e.issue_date >= ? AND e.issue_date < ?');
      args
        ..add(range.start)
        ..add(range.end);
    }
    if (filter.minCents != null) {
      where.add('e.total_cents >= ?');
      args.add(filter.minCents);
    }
    if (filter.maxCents != null) {
      where.add('e.total_cents <= ?');
      args.add(filter.maxCents);
    }

    final rows = await _db.rawQuery(
      '$_selectWithJoins WHERE ${where.join(' AND ')} '
      'ORDER BY e.issue_date DESC, e.created_at DESC',
      args,
    );
    final expenses = rows.map(Expense.fromRow).toList();

    // Tekstualna pretraga radi se u Dartu jer SQLite LIKE ne razlikuje
    // velika/mala slova samo za ASCII (Č, Ć, Š, Ž, Đ ne bi radili).
    final query = filter.query.trim().toLowerCase();
    if (query.isEmpty) return expenses;
    return expenses.where((e) {
      bool has(String? value) =>
          value != null && value.toLowerCase().contains(query);
      return has(e.merchantName) ||
          has(e.categoryName) ||
          has(e.invoiceNumber) ||
          has(e.note);
    }).toList();
  }

  Future<Expense?> getById(String id) async {
    final rows = await _db.rawQuery(
      '$_selectWithJoins WHERE e.id = ? AND e.deleted_at IS NULL LIMIT 1',
      [id],
    );
    return rows.isEmpty ? null : Expense.fromRow(rows.first);
  }

  // ---------------------------------------------------------------------------
  // Pisanje
  // ---------------------------------------------------------------------------

  Future<String> create(ExpenseDraft draft) async {
    _validate(draft);
    final id = Ids.newId();
    final ts = toDbTimestamp(_clock());

    await _db.transaction((txn) async {
      final merchantId = await MerchantRepository.findOrCreate(
        txn,
        name: draft.merchantName,
        type: draft.type,
        defaultCategoryId: draft.categoryId,
        timestamp: ts,
      );
      final row = <String, Object?>{
        'id': id,
        'merchant_id': merchantId,
        ..._draftColumns(draft),
        'currency': AppConstants.currencyCode,
        'version': 1,
        'created_at': ts,
        'updated_at': ts,
        'deleted_at': null,
        'sync_status': SyncStatus.pending.dbValue,
      };
      await txn.insert(_table, row);
      await SyncQueueWriter.enqueueUpsert(
        txn,
        table: _table,
        entityId: id,
        row: row,
        timestamp: ts,
      );
    });
    return id;
  }

  Future<void> update(String id, ExpenseDraft draft) async {
    _validate(draft);
    final ts = toDbTimestamp(_clock());
    await _db.transaction((txn) async {
      final merchantId = await MerchantRepository.findOrCreate(
        txn,
        name: draft.merchantName,
        type: draft.type,
        defaultCategoryId: draft.categoryId,
        timestamp: ts,
      );
      await _applyChanges(txn, id, {
        'merchant_id': merchantId,
        ..._draftColumns(draft),
      }, ts);
    });
  }

  /// Ručna promjena statusa plaćanja.
  Future<void> setStatus(String id, PaymentStatus status) async {
    final ts = toDbTimestamp(_clock());
    await _db.transaction((txn) async {
      final current = await _requireRow(txn, id);
      final total = (current['total_cents']! as num).toInt();
      final changes = switch (status) {
        PaymentStatus.paid => <String, Object?>{
          'payment_status': status.dbValue,
          'paid_date': current['paid_date'] ?? toDbDate(_clock()),
          'paid_cents': total,
        },
        PaymentStatus.unpaid => <String, Object?>{
          'payment_status': status.dbValue,
          'paid_date': null,
          'paid_cents': 0,
        },
        PaymentStatus.partiallyPaid => <String, Object?>{
          'payment_status': status.dbValue,
        },
      };
      await _applyChanges(txn, id, changes, ts);
    });
  }

  /// Meko brisanje (tombstone) – zapis ostaje radi sinkronizacije.
  Future<void> softDelete(String id) async {
    final ts = toDbTimestamp(_clock());
    await _db.transaction((txn) async {
      await _applyChanges(txn, id, {'deleted_at': ts}, ts);
    });
  }

  // ---------------------------------------------------------------------------
  // Agregati
  // ---------------------------------------------------------------------------

  Future<DashboardSummary> getDashboardSummary(DateTime month) async {
    final range = monthRangeDb(month);
    final today = toDbDate(_clock());

    final monthRow = (await _db.rawQuery(
      '''
SELECT COALESCE(SUM(total_cents), 0) AS total_cents,
       COUNT(*) AS expense_count,
       COALESCE(SUM(CASE WHEN payment_status = 'paid' THEN total_cents ELSE 0 END), 0) AS paid_cents,
       COALESCE(SUM(CASE WHEN payment_status = 'paid' THEN 1 ELSE 0 END), 0) AS paid_count
FROM expenses
WHERE deleted_at IS NULL AND issue_date >= ? AND issue_date < ?
''',
      [range.start, range.end],
    )).first;

    final openRow = (await _db.rawQuery(
      '''
SELECT COALESCE(SUM(total_cents - paid_cents), 0) AS open_cents,
       COUNT(*) AS open_count,
       COALESCE(SUM(CASE WHEN due_date IS NOT NULL AND due_date < ? THEN 1 ELSE 0 END), 0) AS overdue_count
FROM expenses
WHERE deleted_at IS NULL AND payment_status != 'paid'
''',
      [today],
    )).first;

    final recentRows = await _db.rawQuery(
      '$_selectWithJoins WHERE e.deleted_at IS NULL '
      'ORDER BY e.created_at DESC LIMIT ?',
      [AppConstants.dashboardRecentLimit],
    );

    return DashboardSummary(
      month: monthStart(month),
      monthTotalCents: _int(monthRow['total_cents']),
      monthCount: _int(monthRow['expense_count']),
      monthPaidCents: _int(monthRow['paid_cents']),
      monthPaidCount: _int(monthRow['paid_count']),
      openUnpaidCents: _int(openRow['open_cents']),
      openUnpaidCount: _int(openRow['open_count']),
      overdueCount: _int(openRow['overdue_count']),
      categoryTotals: await getCategoryTotals(month),
      recent: recentRows.map(Expense.fromRow).toList(),
    );
  }

  Future<List<CategoryTotal>> getCategoryTotals(DateTime month) async {
    final range = monthRangeDb(month);
    final rows = await _db.rawQuery(
      '''
SELECT e.category_id AS category_id,
       c.name AS name,
       c.color AS color,
       c.icon AS icon,
       SUM(e.total_cents) AS total_cents,
       COUNT(*) AS expense_count
FROM expenses e
LEFT JOIN categories c ON c.id = e.category_id
WHERE e.deleted_at IS NULL AND e.issue_date >= ? AND e.issue_date < ?
GROUP BY e.category_id
ORDER BY total_cents DESC
''',
      [range.start, range.end],
    );
    return rows
        .map(
          (r) => CategoryTotal(
            categoryId: r['category_id'] as String?,
            name: r['name'] as String?,
            color: (r['color'] as num?)?.toInt(),
            icon: r['icon'] as String?,
            totalCents: _int(r['total_cents']),
            count: _int(r['expense_count']),
          ),
        )
        .toList();
  }

  /// Ukupno po mjesecima za zadanu godinu (uvijek 12 elemenata).
  Future<List<MonthlyTotal>> getMonthlyTotals(int year) async {
    final rows = await _db.rawQuery(
      '''
SELECT substr(issue_date, 1, 7) AS ym,
       SUM(total_cents) AS total_cents,
       COUNT(*) AS expense_count
FROM expenses
WHERE deleted_at IS NULL AND issue_date >= ? AND issue_date < ?
GROUP BY ym
''',
      [toDbDate(DateTime(year)), toDbDate(DateTime(year + 1))],
    );
    final byKey = {for (final r in rows) r['ym']! as String: r};
    final result = <MonthlyTotal>[];
    for (var m = 1; m <= 12; m++) {
      final month = DateTime(year, m);
      final row = byKey[monthKey(month)];
      result.add(
        MonthlyTotal(
          month: month,
          totalCents: _int(row?['total_cents']),
          count: _int(row?['expense_count']),
        ),
      );
    }
    return result;
  }

  Future<MonthlyTotal> getMonthTotal(DateTime month) async {
    final range = monthRangeDb(month);
    final row = (await _db.rawQuery(
      '''
SELECT COALESCE(SUM(total_cents), 0) AS total_cents, COUNT(*) AS expense_count
FROM expenses
WHERE deleted_at IS NULL AND issue_date >= ? AND issue_date < ?
''',
      [range.start, range.end],
    )).first;
    return MonthlyTotal(
      month: monthStart(month),
      totalCents: _int(row['total_cents']),
      count: _int(row['expense_count']),
    );
  }

  Future<MonthComparison> compareWithPreviousMonth(DateTime month) async {
    final current = await getMonthTotal(month);
    final previous = await getMonthTotal(addMonths(month, -1));
    return MonthComparison(current: current, previous: previous);
  }

  // ---------------------------------------------------------------------------
  // Pomoćne metode
  // ---------------------------------------------------------------------------

  void _validate(ExpenseDraft draft) {
    if (draft.merchantName.trim().isEmpty) {
      throw ArgumentError.value(
        draft.merchantName,
        'merchantName',
        'Naziv izdavatelja je obavezan',
      );
    }
    if (draft.totalCents <= 0) {
      throw ArgumentError.value(
        draft.totalCents,
        'totalCents',
        'Iznos mora biti veći od nule',
      );
    }
  }

  Map<String, Object?> _draftColumns(ExpenseDraft d) {
    final isPaid = d.status == PaymentStatus.paid;
    final paidDate = isPaid ? (d.paidDate ?? _clock()) : null;
    return {
      'category_id': d.categoryId,
      'expense_type': d.type.dbValue,
      'issue_date': toDbDate(d.issueDate),
      'due_date': d.dueDate == null ? null : toDbDate(d.dueDate!),
      'paid_date': paidDate == null ? null : toDbDate(paidDate),
      'total_cents': d.totalCents,
      'paid_cents': isPaid ? d.totalCents : 0,
      'payment_status': d.status.dbValue,
      'invoice_number': _blankToNull(d.invoiceNumber),
      'qr_content': _blankToNull(d.qrContent),
      'note': _blankToNull(d.note),
    };
  }

  Future<Map<String, Object?>> _requireRow(
    DatabaseExecutor txn,
    String id,
  ) async {
    final rows = await txn.query(
      _table,
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) throw StateError('Račun $id ne postoji');
    return rows.first;
  }

  /// Primjenjuje izmjene, povećava `version`, označava zapis za sinkronizaciju
  /// i upisuje puni novi redak u `sync_queue`.
  Future<void> _applyChanges(
    DatabaseExecutor txn,
    String id,
    Map<String, Object?> changes,
    String timestamp,
  ) async {
    final current = await _requireRow(txn, id);
    final version = (current['version']! as num).toInt();
    await txn.update(
      _table,
      {
        ...changes,
        'version': version + 1,
        'updated_at': timestamp,
        'sync_status': SyncStatus.pending.dbValue,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    final updated = await txn.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    await SyncQueueWriter.enqueueUpsert(
      txn,
      table: _table,
      entityId: id,
      row: updated.first,
      timestamp: timestamp,
    );
  }

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  static int _int(Object? value) => (value as num?)?.toInt() ?? 0;
}

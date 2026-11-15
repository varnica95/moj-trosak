import 'package:sqflite/sqflite.dart';

import '../../core/utils/ids.dart';
import '../database/app_database.dart';
import '../database/sync_queue_writer.dart';
import '../models/enums.dart';
import '../models/merchant.dart';

/// Trgovine i izdavatelji računa.
class MerchantRepository {
  MerchantRepository(this._database);

  final AppDatabase _database;

  Future<List<Merchant>> getAll() async {
    final rows = await _database.db.query(
      'merchants',
      where: 'deleted_at IS NULL',
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(Merchant.fromRow).toList();
  }

  /// Vraća ID postojećeg izdavatelja istog (normaliziranog) naziva ili
  /// kreira novog. Poziva se unutar transakcije spremanja računa.
  ///
  /// ID je deterministički prema nazivu, pa se isti izdavatelj nikada ne
  /// duplicira – ni lokalno ni kasnije pri sinkronizaciji.
  static Future<String> findOrCreate(
    DatabaseExecutor db, {
    required String name,
    required ExpenseType type,
    required String timestamp,
    String? defaultCategoryId,
  }) async {
    final cleanName = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    final normalized = normalizeName(cleanName);
    if (normalized.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Naziv ne smije biti prazan');
    }
    final id = Ids.merchant(normalized);

    final existing = await db.query(
      'merchants',
      where: 'id = ? OR normalized_name = ?',
      whereArgs: [id, normalized],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      final row = existing.first;
      final existingId = row['id']! as String;
      if (row['deleted_at'] != null) {
        // Ponovno korištenje ranije obrisanog izdavatelja.
        await db.update(
          'merchants',
          {
            'deleted_at': null,
            'updated_at': timestamp,
            'sync_status': SyncStatus.pending.dbValue,
          },
          where: 'id = ?',
          whereArgs: [existingId],
        );
        await _enqueue(db, existingId, timestamp);
      }
      return existingId;
    }

    await db.insert('merchants', {
      'id': id,
      'name': cleanName,
      'normalized_name': normalized,
      'merchant_type': type.dbValue,
      'default_category_id': defaultCategoryId,
      'oib': null,
      'created_at': timestamp,
      'updated_at': timestamp,
      'deleted_at': null,
      'sync_status': SyncStatus.pending.dbValue,
    });
    await _enqueue(db, id, timestamp);
    return id;
  }

  static Future<void> _enqueue(
    DatabaseExecutor db,
    String id,
    String timestamp,
  ) async {
    final rows = await db.query(
      'merchants',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    await SyncQueueWriter.enqueueUpsert(
      db,
      table: 'merchants',
      entityId: id,
      row: rows.first,
      timestamp: timestamp,
    );
  }
}

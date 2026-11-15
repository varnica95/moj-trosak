import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../core/utils/ids.dart';

/// Upisuje promjene u `sync_queue` unutar iste transakcije kao i samu promjenu.
///
/// Svaka promjena je "upsert" punog retka (i meko brisanje je upsert s
/// postavljenim `deleted_at`). Za isti entitet u redu postoji najviše jedan
/// zapis – novija promjena zamjenjuje stariju. Sinkronizacijski servis
/// (FAZA 5) šalje redak serveru koji ga primjenjuje idempotentno prema ID-u
/// i `version`/`updated_at` polju.
abstract final class SyncQueueWriter {
  static const String operationUpsert = 'upsert';

  static Future<void> enqueueUpsert(
    DatabaseExecutor db, {
    required String table,
    required String entityId,
    required Map<String, Object?> row,
    required String timestamp,
  }) async {
    // DELETE + INSERT umjesto "ON CONFLICT DO UPDATE" jer starije verzije
    // Androida imaju SQLite bez podrške za UPSERT sintaksu.
    await db.delete(
      'sync_queue',
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: [table, entityId],
    );
    await db.insert('sync_queue', {
      'id': Ids.newId(),
      'entity_type': table,
      'entity_id': entityId,
      'operation': operationUpsert,
      'payload': jsonEncode(row),
      'created_at': timestamp,
      'attempts': 0,
      'last_error': null,
    });
  }
}

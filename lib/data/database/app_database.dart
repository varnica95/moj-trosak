import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/date_format.dart';
import 'db_schema.dart';
import 'seed_data.dart';

/// Omotač oko lokalne SQLite baze – primarnog izvora podataka aplikacije.
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  /// Otvara (i po potrebi kreira) bazu.
  ///
  /// [factory] i [path] služe za testove (npr. `databaseFactoryFfi` i
  /// `inMemoryDatabasePath`).
  static Future<AppDatabase> open({
    DatabaseFactory? factory,
    String? path,
    bool singleInstance = true,
  }) async {
    final dbFactory = factory ?? databaseFactory;
    final dbPath =
        path ??
        p.join(
          await dbFactory.getDatabasesPath(),
          AppConstants.databaseFileName,
        );

    final db = await dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: DbSchema.version,
        singleInstance: singleInstance,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await DbSchema.create(db);
          await SeedData.insert(db, toDbTimestamp(DateTime.now()));
        },
        onUpgrade: DbSchema.upgrade,
      ),
    );
    return AppDatabase._(db);
  }

  /// Trajno briše sve lokalne podatke i vraća početne kategorije.
  ///
  /// Napomena: kada se u FAZI 5 uvede oblak, ovo briše samo lokalnu kopiju;
  /// brisanje podataka u oblaku bit će zasebna, jasno označena radnja.
  Future<void> wipeAllData() async {
    await db.transaction((txn) async {
      const tables = [
        'sync_queue',
        'attachments',
        'expense_items',
        'expenses',
        'merchants',
        'categories',
      ];
      for (final table in tables) {
        await txn.delete(table);
      }
      await SeedData.insert(txn, toDbTimestamp(DateTime.now()));
    });
  }

  Future<void> close() => db.close();
}

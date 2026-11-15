import 'package:sqflite/sqflite.dart';

/// Shema lokalne SQLite baze.
///
/// Pravila za sve tablice osim `sync_queue`:
/// * `id` je stabilan UUID (TEXT),
/// * `created_at` / `updated_at` su ISO 8601 UTC vremenske oznake,
/// * `deleted_at` je tombstone za meko brisanje (potrebno za sinkronizaciju),
/// * `sync_status` je `pending` / `synced` / `conflict`.
///
/// Iznosi su u centima (INTEGER), kalendarski datumi `YYYY-MM-DD` (TEXT).
abstract final class DbSchema {
  static const int version = 2;

  static const List<String> _v1 = [
    '''
CREATE TABLE categories (
  id TEXT PRIMARY KEY NOT NULL,
  name TEXT NOT NULL,
  group_type TEXT NOT NULL,
  color INTEGER NOT NULL,
  icon TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_system INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  sync_status TEXT NOT NULL DEFAULT 'pending'
)''',
    '''
CREATE TABLE merchants (
  id TEXT PRIMARY KEY NOT NULL,
  name TEXT NOT NULL,
  normalized_name TEXT NOT NULL UNIQUE,
  merchant_type TEXT NOT NULL,
  default_category_id TEXT REFERENCES categories(id),
  oib TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  sync_status TEXT NOT NULL DEFAULT 'pending'
)''',
    '''
CREATE TABLE expenses (
  id TEXT PRIMARY KEY NOT NULL,
  merchant_id TEXT NOT NULL REFERENCES merchants(id),
  category_id TEXT REFERENCES categories(id),
  expense_type TEXT NOT NULL,
  issue_date TEXT NOT NULL,
  due_date TEXT,
  paid_date TEXT,
  total_cents INTEGER NOT NULL CHECK (total_cents >= 0),
  paid_cents INTEGER NOT NULL DEFAULT 0,
  currency TEXT NOT NULL DEFAULT 'EUR',
  payment_status TEXT NOT NULL,
  invoice_number TEXT,
  qr_content TEXT,
  note TEXT,
  version INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  sync_status TEXT NOT NULL DEFAULT 'pending'
)''',
    'CREATE INDEX idx_expenses_issue_date ON expenses(issue_date)',
    'CREATE INDEX idx_expenses_status ON expenses(payment_status)',
    'CREATE INDEX idx_expenses_merchant ON expenses(merchant_id)',
    '''
CREATE TABLE expense_items (
  id TEXT PRIMARY KEY NOT NULL,
  expense_id TEXT NOT NULL REFERENCES expenses(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  quantity REAL NOT NULL DEFAULT 1,
  unit_price_cents INTEGER,
  total_cents INTEGER NOT NULL,
  category_id TEXT REFERENCES categories(id),
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  sync_status TEXT NOT NULL DEFAULT 'pending'
)''',
    'CREATE INDEX idx_expense_items_expense ON expense_items(expense_id)',
    '''
CREATE TABLE attachments (
  id TEXT PRIMARY KEY NOT NULL,
  expense_id TEXT NOT NULL REFERENCES expenses(id) ON DELETE CASCADE,
  local_path TEXT,
  remote_path TEXT,
  mime_type TEXT NOT NULL,
  size_bytes INTEGER,
  sha256 TEXT,
  upload_status TEXT NOT NULL DEFAULT 'pending',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  sync_status TEXT NOT NULL DEFAULT 'pending'
)''',
    'CREATE INDEX idx_attachments_expense ON attachments(expense_id)',
    // Red promjena za sinkronizaciju. Jedan zapis po entitetu: nova promjena
    // istog entiteta zamjenjuje prethodnu (payload je uvijek puni redak),
    // čime se sprječava višestruko slanje i dupliciranje u oblaku.
    '''
CREATE TABLE sync_queue (
  id TEXT PRIMARY KEY NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  operation TEXT NOT NULL,
  payload TEXT NOT NULL,
  created_at TEXT NOT NULL,
  attempts INTEGER NOT NULL DEFAULT 0,
  last_error TEXT,
  UNIQUE (entity_type, entity_id)
)''',
  ];

  /// Migracije: ključ je verzija na koju se prelazi.
  static const Map<int, List<String>> _migrations = {
    2: [
      // Porez (PDV) prepoznat OCR-om.
      'ALTER TABLE expenses ADD COLUMN tax_cents INTEGER',
      'CREATE INDEX idx_attachments_upload ON attachments(upload_status)',
    ],
  };

  /// Nova instalacija: shema v1 + sve migracije redom.
  static Future<void> create(DatabaseExecutor db) async {
    for (final statement in _v1) {
      await db.execute(statement);
    }
    await upgrade(db, 1, version);
  }

  /// Nadogradnja postojeće baze bez gubitka podataka.
  static Future<void> upgrade(
    DatabaseExecutor db,
    int oldVersion,
    int newVersion,
  ) async {
    for (var v = oldVersion + 1; v <= newVersion; v++) {
      for (final statement in _migrations[v] ?? const <String>[]) {
        await db.execute(statement);
      }
    }
  }
}

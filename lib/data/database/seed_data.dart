import 'package:sqflite/sqflite.dart';

import '../../core/utils/ids.dart';
import '../models/enums.dart';

typedef SeedCategory = ({
  String key,
  String name,
  CategoryGroup group,
  int color,
  String icon,
});

typedef SeedMerchant = ({String name, ExpenseType type, String categoryKey});

/// Početni podaci: ugrađene kategorije i poznati izdavatelji.
///
/// ID-jevi su deterministički (UUID v5), pa su isti na svakom uređaju.
/// Seed zapisi se ne stavljaju u `sync_queue` – server ih u FAZI 5 može
/// kreirati s istim ID-jevima bez konflikta.
abstract final class SeedData {
  static const List<SeedCategory> categories = [
    // Režije
    (key: 'electricity', name: 'Struja', group: CategoryGroup.utility, color: 0xFFF2A900, icon: 'bolt'),
    (key: 'gas', name: 'Plin', group: CategoryGroup.utility, color: 0xFFE4572E, icon: 'flame'),
    (key: 'water', name: 'Voda', group: CategoryGroup.utility, color: 0xFF2D9CDB, icon: 'water'),
    (key: 'building_reserve', name: 'Pričuva za stan', group: CategoryGroup.utility, color: 0xFF6C5CE7, icon: 'building'),
    (key: 'internet_phone', name: 'Internet i telefon', group: CategoryGroup.utility, color: 0xFF00A8A8, icon: 'wifi'),
    (key: 'communal', name: 'Komunalne usluge', group: CategoryGroup.utility, color: 0xFF5B8C5A, icon: 'recycling'),
    (key: 'other_utility', name: 'Ostale režije', group: CategoryGroup.utility, color: 0xFF7D8A96, icon: 'receipt'),
    // Maloprodaja
    (key: 'groceries', name: 'Namirnice', group: CategoryGroup.retail, color: 0xFF2E9E5B, icon: 'cart'),
    (key: 'drugstore', name: 'Drogerija', group: CategoryGroup.retail, color: 0xFFD6457A, icon: 'spa'),
    (key: 'clothing', name: 'Odjeća', group: CategoryGroup.retail, color: 0xFF8E5CD9, icon: 'clothing'),
    (key: 'electronics', name: 'Tehnika', group: CategoryGroup.retail, color: 0xFF3367D6, icon: 'devices'),
    (key: 'household', name: 'Kućanstvo', group: CategoryGroup.retail, color: 0xFFB7791F, icon: 'home'),
    // Općenito
    (key: 'other', name: 'Ostalo', group: CategoryGroup.general, color: 0xFF8896A5, icon: 'category'),
    // Kategorije artikala (koriste se od FAZE 3)
    (key: 'item_food', name: 'Hrana', group: CategoryGroup.item, color: 0xFF2E9E5B, icon: 'food'),
    (key: 'item_drinks', name: 'Piće', group: CategoryGroup.item, color: 0xFF2D9CDB, icon: 'drink'),
    (key: 'item_hygiene', name: 'Higijena', group: CategoryGroup.item, color: 0xFFD6457A, icon: 'spa'),
    (key: 'item_household', name: 'Kućanske potrepštine', group: CategoryGroup.item, color: 0xFFB7791F, icon: 'home'),
    (key: 'item_clothing', name: 'Odjeća', group: CategoryGroup.item, color: 0xFF8E5CD9, icon: 'clothing'),
    (key: 'item_electronics', name: 'Tehnika', group: CategoryGroup.item, color: 0xFF3367D6, icon: 'devices'),
    (key: 'item_other', name: 'Ostalo', group: CategoryGroup.item, color: 0xFF8896A5, icon: 'category'),
  ];

  static const List<SeedMerchant> merchants = [
    (name: 'HEP', type: ExpenseType.utility, categoryKey: 'electricity'),
    (name: 'Zagrebački holding', type: ExpenseType.utility, categoryKey: 'communal'),
    (name: 'Konzum', type: ExpenseType.retail, categoryKey: 'groceries'),
    (name: 'Kaufland', type: ExpenseType.retail, categoryKey: 'groceries'),
    (name: 'Lidl', type: ExpenseType.retail, categoryKey: 'groceries'),
    (name: 'Plodine', type: ExpenseType.retail, categoryKey: 'groceries'),
    (name: 'DM', type: ExpenseType.retail, categoryKey: 'drugstore'),
  ];

  static Future<void> insert(DatabaseExecutor db, String timestamp) async {
    for (var i = 0; i < categories.length; i++) {
      final c = categories[i];
      await db.insert('categories', {
        'id': Ids.category(c.key),
        'name': c.name,
        'group_type': c.group.dbValue,
        'color': c.color,
        'icon': c.icon,
        'sort_order': i,
        'is_system': 1,
        'created_at': timestamp,
        'updated_at': timestamp,
        'deleted_at': null,
        'sync_status': SyncStatus.pending.dbValue,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    for (final m in merchants) {
      final normalized = normalizeName(m.name);
      await db.insert('merchants', {
        'id': Ids.merchant(normalized),
        'name': m.name,
        'normalized_name': normalized,
        'merchant_type': m.type.dbValue,
        'default_category_id': Ids.category(m.categoryKey),
        'oib': null,
        'created_at': timestamp,
        'updated_at': timestamp,
        'deleted_at': null,
        'sync_status': SyncStatus.pending.dbValue,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }
}

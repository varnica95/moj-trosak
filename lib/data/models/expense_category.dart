import 'enums.dart';

/// Kategorija troška ili artikla.
///
/// Naziv `ExpenseCategory` (a ne `Category`) izbjegava sukob s Flutterovom
/// anotacijom `Category` iz `package:flutter/foundation.dart`.
class ExpenseCategory {
  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.group,
    required this.color,
    required this.icon,
    required this.sortOrder,
  });

  factory ExpenseCategory.fromRow(Map<String, Object?> row) => ExpenseCategory(
    id: row['id']! as String,
    name: row['name']! as String,
    group: CategoryGroup.fromDb(row['group_type'] as String?),
    color: (row['color']! as num).toInt(),
    icon: row['icon']! as String,
    sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String name;
  final CategoryGroup group;

  /// ARGB vrijednost boje.
  final int color;

  /// Ključ ikone (vidi `categoryIcon` u shared/widgets).
  final String icon;
  final int sortOrder;
}

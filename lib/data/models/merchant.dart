import 'enums.dart';

/// Trgovina ili izdavatelj računa.
class Merchant {
  const Merchant({
    required this.id,
    required this.name,
    required this.type,
    this.defaultCategoryId,
  });

  factory Merchant.fromRow(Map<String, Object?> row) => Merchant(
    id: row['id']! as String,
    name: row['name']! as String,
    type: ExpenseType.fromDb(row['merchant_type'] as String?),
    defaultCategoryId: row['default_category_id'] as String?,
  );

  final String id;
  final String name;
  final ExpenseType type;
  final String? defaultCategoryId;
}

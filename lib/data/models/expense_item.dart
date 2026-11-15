/// Pojedinačna stavka (artikl) računa, spremljena u bazi.
class ExpenseItem {
  const ExpenseItem({
    required this.id,
    required this.expenseId,
    required this.name,
    required this.quantity,
    required this.totalCents,
    required this.sortOrder,
    this.unitPriceCents,
    this.categoryId,
    this.categoryName,
  });

  factory ExpenseItem.fromRow(Map<String, Object?> r) => ExpenseItem(
    id: r['id']! as String,
    expenseId: r['expense_id']! as String,
    name: r['name']! as String,
    quantity: (r['quantity'] as num?)?.toDouble() ?? 1,
    unitPriceCents: (r['unit_price_cents'] as num?)?.toInt(),
    totalCents: (r['total_cents']! as num).toInt(),
    categoryId: r['category_id'] as String?,
    categoryName: r['category_name'] as String?,
    sortOrder: (r['sort_order'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String expenseId;
  final String name;
  final double quantity;
  final int? unitPriceCents;
  final int totalCents;
  final String? categoryId;
  final String? categoryName;
  final int sortOrder;

  ExpenseItemDraft toDraft() => ExpenseItemDraft(
    name: name,
    quantity: quantity,
    unitPriceCents: unitPriceCents,
    totalCents: totalCents,
    categoryId: categoryId,
  );
}

/// Stavka u obrascu (prije spremanja), npr. prepoznata OCR-om.
class ExpenseItemDraft {
  const ExpenseItemDraft({
    required this.name,
    required this.totalCents,
    this.quantity = 1,
    this.unitPriceCents,
    this.categoryId,
  });

  final String name;
  final double quantity;
  final int? unitPriceCents;
  final int totalCents;
  final String? categoryId;

  ExpenseItemDraft copyWith({
    String? name,
    double? quantity,
    int? unitPriceCents,
    int? totalCents,
    String? categoryId,
    bool clearCategory = false,
    bool clearUnitPrice = false,
  }) => ExpenseItemDraft(
    name: name ?? this.name,
    quantity: quantity ?? this.quantity,
    unitPriceCents: clearUnitPrice
        ? null
        : (unitPriceCents ?? this.unitPriceCents),
    totalCents: totalCents ?? this.totalCents,
    categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
  );
}

/// Formatira količinu bez nepotrebnih decimala: 2 → "2", 1.264 → "1,264".
String formatQuantity(double quantity) {
  if (quantity == quantity.roundToDouble()) return quantity.toInt().toString();
  var s = quantity.toStringAsFixed(3);
  while (s.endsWith('0')) {
    s = s.substring(0, s.length - 1);
  }
  return s.replaceAll('.', ',');
}

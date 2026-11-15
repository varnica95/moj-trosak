import '../database/app_database.dart';
import '../models/enums.dart';
import '../models/expense_category.dart';

/// Kategorije troškova i artikala.
class CategoryRepository {
  CategoryRepository(this._database);

  final AppDatabase _database;

  /// Kategorije koje se mogu dodijeliti računu (bez kategorija artikala).
  Future<List<ExpenseCategory>> getExpenseCategories() async {
    final rows = await _database.db.query(
      'categories',
      where: 'deleted_at IS NULL AND group_type != ?',
      whereArgs: [CategoryGroup.item.dbValue],
      orderBy: 'sort_order, name',
    );
    return rows.map(ExpenseCategory.fromRow).toList();
  }

  /// Kategorije pojedinačnih artikala (koriste se od FAZE 3).
  Future<List<ExpenseCategory>> getItemCategories() async {
    final rows = await _database.db.query(
      'categories',
      where: 'deleted_at IS NULL AND group_type = ?',
      whereArgs: [CategoryGroup.item.dbValue],
      orderBy: 'sort_order, name',
    );
    return rows.map(ExpenseCategory.fromRow).toList();
  }
}

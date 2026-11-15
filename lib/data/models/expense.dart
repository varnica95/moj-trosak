import '../../core/utils/date_format.dart';
import 'enums.dart';

/// Račun / trošak, s pridruženim podacima o izdavatelju i kategoriji.
class Expense {
  const Expense({
    required this.id,
    required this.merchantId,
    required this.merchantName,
    required this.type,
    required this.issueDate,
    required this.totalCents,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.categoryId,
    this.categoryName,
    this.categoryColor,
    this.categoryIcon,
    this.dueDate,
    this.paidDate,
    this.paidCents = 0,
    this.currency = 'EUR',
    this.invoiceNumber,
    this.qrContent,
    this.note,
    this.version = 1,
    this.deletedAt,
    this.syncStatus = SyncStatus.pending,
  });

  /// Gradi model iz retka upita koji spaja `expenses`, `merchants` i
  /// `categories` (vidi `ExpenseRepository`).
  factory Expense.fromRow(Map<String, Object?> r) => Expense(
    id: r['id']! as String,
    merchantId: r['merchant_id']! as String,
    merchantName: (r['merchant_name'] as String?) ?? '',
    categoryId: r['category_id'] as String?,
    categoryName: r['category_name'] as String?,
    categoryColor: (r['category_color'] as num?)?.toInt(),
    categoryIcon: r['category_icon'] as String?,
    type: ExpenseType.fromDb(r['expense_type'] as String?),
    issueDate: fromDbDate(r['issue_date']! as String),
    dueDate: fromDbDateOrNull(r['due_date']),
    paidDate: fromDbDateOrNull(r['paid_date']),
    totalCents: (r['total_cents']! as num).toInt(),
    paidCents: (r['paid_cents'] as num?)?.toInt() ?? 0,
    currency: (r['currency'] as String?) ?? 'EUR',
    status: PaymentStatus.fromDb(r['payment_status'] as String?),
    invoiceNumber: r['invoice_number'] as String?,
    qrContent: r['qr_content'] as String?,
    note: r['note'] as String?,
    version: (r['version'] as num?)?.toInt() ?? 1,
    createdAt: fromDbTimestamp(r['created_at']! as String),
    updatedAt: fromDbTimestamp(r['updated_at']! as String),
    deletedAt: fromDbTimestampOrNull(r['deleted_at']),
    syncStatus: SyncStatus.fromDb(r['sync_status'] as String?),
  );

  final String id;
  final String merchantId;
  final String merchantName;
  final String? categoryId;
  final String? categoryName;
  final int? categoryColor;
  final String? categoryIcon;
  final ExpenseType type;
  final DateTime issueDate;
  final DateTime? dueDate;
  final DateTime? paidDate;
  final int totalCents;
  final int paidCents;
  final String currency;
  final PaymentStatus status;
  final String? invoiceNumber;
  final String? qrContent;
  final String? note;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;

  bool get isPaid => status == PaymentStatus.paid;

  /// Račun je dospio ako nije plaćen, a datum dospijeća je prije `today`.
  bool isOverdue(DateTime today) =>
      !isPaid && dueDate != null && dueDate!.isBefore(dateOnly(today));
}

/// Podaci iz obrasca za kreiranje ili izmjenu računa.
class ExpenseDraft {
  const ExpenseDraft({
    required this.merchantName,
    required this.type,
    required this.issueDate,
    required this.totalCents,
    required this.status,
    this.categoryId,
    this.dueDate,
    this.paidDate,
    this.invoiceNumber,
    this.qrContent,
    this.note,
  });

  final String merchantName;
  final String? categoryId;
  final ExpenseType type;
  final DateTime issueDate;
  final DateTime? dueDate;
  final DateTime? paidDate;
  final int totalCents;
  final PaymentStatus status;
  final String? invoiceNumber;
  final String? qrContent;
  final String? note;
}

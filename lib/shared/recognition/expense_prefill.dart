import '../../data/models/enums.dart';
import '../../data/models/expense_item.dart';

/// Izvor prepoznatih podataka.
enum PrefillSource { qr, ocr }

/// Podaci prepoznati iz QR koda ili fotografije, kojima se popunjava obrazac.
///
/// Ništa se ne sprema automatski: korisnik uvijek pregledava i potvrđuje
/// podatke u obrascu. Polja koja nisu prepoznata ostaju `null`.
class ExpensePrefill {
  const ExpensePrefill({
    required this.source,
    this.merchantName,
    this.categoryKey,
    this.type,
    this.status,
    this.issueDate,
    this.dueDate,
    this.totalCents,
    this.totalConfident = false,
    this.taxCents,
    this.invoiceNumber,
    this.qrContent,
    this.note,
    this.items = const [],
    this.imagePath,
    this.warnings = const [],
  });

  final PrefillSource source;
  final String? merchantName;

  /// Ključ kategorije računa (npr. `groceries`), vidi `Ids.category`.
  final String? categoryKey;
  final ExpenseType? type;
  final PaymentStatus? status;
  final DateTime? issueDate;
  final DateTime? dueDate;
  final int? totalCents;

  /// `true` ako je iznos pročitan iz pouzdanog izvora (QR kod ili redak
  /// "UKUPNO"), `false` ako je procijenjen.
  final bool totalConfident;
  final int? taxCents;
  final String? invoiceNumber;
  final String? qrContent;
  final String? note;
  final List<ExpenseItemDraft> items;

  /// Privremena putanja fotografije računa (prije trajne pohrane).
  final String? imagePath;

  /// Upozorenja za korisnika (što treba provjeriti).
  final List<String> warnings;

  int get itemsTotalCents => items.fold(0, (sum, i) => sum + i.totalCents);
}

import '../../../core/utils/ids.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/expense_item.dart';
import '../../../shared/recognition/expense_prefill.dart';
import '../../../shared/recognition/item_categorizer.dart';
import '../../../shared/recognition/merchant_matcher.dart';
import '../../../shared/recognition/text_normalize.dart';

/// Izvlači podatke iz teksta računa (redova dobivenih OCR-om).
///
/// Sve što se prepozna samo je prijedlog: rezultat uvijek ide u obrazac
/// na provjeru, a nesigurni podaci označeni su upozorenjem.
abstract final class ReceiptTextParser {
  static const String totalNotFoundWarning =
      'Ukupan iznos nije pouzdano prepoznat – provjerite iznos.';
  static const String nothingFoundWarning =
      'Na fotografiji nije prepoznat tekst računa. Pokušajte ponovno uz '
      'bolje osvjetljenje ili unesite podatke ručno.';

  /// Iznos na kraju retka, s opcionalnom oznakom porezne stope (A–E) ili *.
  static final RegExp _trailingAmount = RegExp(
    r'(-?\d{1,3}(?:\.\d{3})+,\d{2}|-?\d+[.,]\d{2})\s*(?:EUR|€)?\s*[A-Ea-e*]?\s*$',
  );

  /// Redak s količinom: "2 x 1,29", "2 KOM x 1,29  2,58", "1,264 kg x 1,25 EUR/kg".
  static final RegExp _quantityLine = RegExp(
    r'^\s*(\d+(?:[.,]\d{1,3})?)\s*(?:KOM|kom|KG|kg|L|l|G|g)?\.?\s*[xX×*]\s*'
    r'(\d+[.,]\d{2})\s*(?:EUR|€)?(?:\s*/\s*\w+)?'
    r'(?:\s+(-?\d+[.,]\d{2}))?\s*[A-Ea-e*]?\s*$',
  );

  static final RegExp _date = RegExp(
    r'(\d{1,2})\s*[./-]\s*(\d{1,2})\s*[./-]\s*(\d{4}|\d{2})(?!\d)',
  );

  /// Hrvatski format broja računa: broj/poslovni prostor/naplatni uređaj.
  static final RegExp _invoiceNumber = RegExp(
    r'(\d{1,10}\s*[/-]\s*[A-Z0-9]{1,20}\s*[/-]\s*\d{1,5})(?![\d./-])',
  );

  /// Oznake retka s ukupnim iznosom, po prioritetu.
  static const List<String> _totalKeywords = [
    'ZA PLATITI',
    'ZA PLACANJE',
    'ZA PLATIT',
    'SVEUKUPNO',
    'UKUPNO EUR',
    'UKUPAN IZNOS',
    'IZNOS RACUNA',
    'UKUPNO',
    'TOTAL',
  ];

  /// Retci koji nisu artikli.
  static const List<String> _nonItemKeywords = [
    'UKUPNO', 'ZA PLATITI', 'PDV', 'OSNOVICA', 'POREZ', 'GOTOVINA',
    'KARTICA', 'KARTICOM', 'POVRAT', 'OIB', 'JIR', 'ZKI', 'RACUN',
    'BLAGAJN', 'KASA', 'DATUM', 'VRIJEME', 'TEL:', 'TEL.', 'TELEFON',
    'FAX', 'ADRESA',
    'HVALA', 'NACIN PLACANJA', 'VISA', 'MASTERCARD', 'MAESTRO', 'DINERS',
    'IBAN', 'D.O.O', 'D.D.', 'POSLOVNI PROSTOR', 'OPERATER', 'KUPAC',
    'TRANSAKCIJ', 'AUTORIZ', 'IZDAO', 'STOPA', 'NAPOJNICA', 'TOTAL',
    'PRIMLJENO', 'OSTATAK', 'EUR/KN', 'TECAJ', 'BODOVI', 'KLUB',
  ];

  static ExpensePrefill parse(List<String> rows, {String? imagePath}) {
    final clean = rows.map((r) => r.trim()).where((r) => r.isNotEmpty).toList();
    if (clean.isEmpty) {
      return ExpensePrefill(
        source: PrefillSource.ocr,
        imagePath: imagePath,
        warnings: const [nothingFoundWarning],
      );
    }
    final folded = clean.map(foldText).toList();
    final warnings = <String>[];

    // Trgovina: poznata oznaka u prvih ~10 redova, inače u cijelom računu.
    final head = clean.take(10).toList();
    final known = MerchantMatcher.match(head) ?? MerchantMatcher.match(clean);
    final merchantName = known?.name ?? _guessMerchant(clean, folded);
    if (known == null) {
      warnings.add('Trgovina nije prepoznata sa sigurnošću – provjerite naziv.');
    }

    // Ukupno.
    final totalHit = _findTotal(clean, folded);
    var totalCents = totalHit?.cents;
    final totalIndex = totalHit?.index ?? clean.length;

    // Artikli: od zaglavlja do retka s ukupnim iznosom.
    final items = _parseItems(clean.sublist(0, totalIndex), folded);

    var totalConfident = totalHit != null;
    if (totalCents == null) {
      final itemsSum = items.fold<int>(0, (s, i) => s + i.totalCents);
      totalCents = itemsSum > 0 ? itemsSum : _largestAmount(clean);
      totalConfident = false;
    }
    if (!totalConfident) warnings.add(totalNotFoundWarning);

    if (items.isEmpty) {
      warnings.add('Artikli nisu prepoznati – možete ih dodati ručno.');
    } else if (totalCents != null) {
      final itemsSum = items.fold<int>(0, (s, i) => s + i.totalCents);
      if (itemsSum != totalCents) {
        warnings.add(
          'Zbroj artikala (${formatCents(itemsSum)}) ne odgovara ukupnom '
          'iznosu (${formatCents(totalCents)}) – provjerite artikle.',
        );
      }
    }

    final date = _findDate(clean);
    if (date == null) warnings.add('Datum računa nije prepoznat.');

    return ExpensePrefill(
      source: PrefillSource.ocr,
      merchantName: merchantName,
      categoryKey: known?.categoryKey ?? 'groceries',
      type: known?.type ?? ExpenseType.retail,
      status: known?.type == ExpenseType.utility
          ? PaymentStatus.unpaid
          : PaymentStatus.paid,
      issueDate: date,
      totalCents: totalCents,
      totalConfident: totalConfident,
      taxCents: _findTax(clean, folded),
      invoiceNumber: _findInvoiceNumber(clean, folded),
      items: items,
      imagePath: imagePath,
      warnings: warnings,
    );
  }

  // ---------------------------------------------------------------------------

  static String? _guessMerchant(List<String> rows, List<String> folded) {
    for (var i = 0; i < rows.length && i < 6; i++) {
      final f = folded[i];
      if (!hasLetters(rows[i], min: 3)) continue;
      if (_trailingAmount.hasMatch(rows[i])) continue;
      if (_containsAny(f, const ['RACUN', 'OIB', 'TEL:', 'TEL.', 'ADRESA', 'DATUM'])) {
        continue;
      }
      return rows[i];
    }
    return null;
  }

  static ({int cents, int index})? _findTotal(
    List<String> rows,
    List<String> folded,
  ) {
    for (final keyword in _totalKeywords) {
      for (var i = 0; i < rows.length; i++) {
        final f = folded[i];
        if (!f.contains(keyword)) continue;
        if (_containsAny(f, const ['PDV', 'OSNOVICA', 'POREZ', 'POPUST'])) {
          continue;
        }
        final onRow = _amountAtEnd(rows[i]);
        if (onRow != null) return (cents: onRow, index: i);
        if (i + 1 < rows.length) {
          final next = _amountAtEnd(rows[i + 1]);
          if (next != null && !hasLetters(rows[i + 1], min: 4)) {
            return (cents: next, index: i);
          }
        }
      }
    }
    return null;
  }

  static List<ExpenseItemDraft> _parseItems(
    List<String> rows,
    List<String> folded,
  ) {
    final items = <ExpenseItemDraft>[];
    String? pendingName;

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final q = _quantityLine.firstMatch(row);
      if (q != null) {
        final qty = _parseQuantity(q.group(1)!);
        final unit = parseMoneyToCents(q.group(2)!);
        if (qty == null || unit == null) continue;
        final explicit = q.group(3) == null ? null : _signedCents(q.group(3)!);
        final total = explicit ?? (qty * unit).round();

        if (pendingName != null) {
          items.add(_item(pendingName, qty, unit, total));
          pendingName = null;
        } else if (items.isNotEmpty &&
            items.last.quantity == 1 &&
            (items.last.totalCents - total).abs() <= 1) {
          // Lidl-stil: "Banane 1,58 A" pa ispod "1,264 kg x 1,25".
          items[items.length - 1] = items.last.copyWith(
            quantity: qty,
            unitPriceCents: unit,
          );
        }
        continue;
      }

      if (_containsAny(folded[i], _nonItemKeywords) || _date.hasMatch(row)) {
        pendingName = null;
        continue;
      }

      final amountMatch = _trailingAmount.firstMatch(row);
      if (amountMatch != null) {
        final name = _cleanName(row.substring(0, amountMatch.start));
        final cents = _signedCents(amountMatch.group(1)!);
        if (cents != null && hasLetters(name)) {
          items.add(_item(name, 1, cents, cents));
          pendingName = null;
        } else if (cents != null && pendingName != null) {
          // Naziv u jednom redu, cijena sama u sljedećem.
          items.add(_item(pendingName, 1, cents, cents));
          pendingName = null;
        }
        continue;
      }

      if (hasLetters(row, min: 3)) {
        pendingName = _cleanName(row);
      }
    }
    return items;
  }

  static ExpenseItemDraft _item(String name, double qty, int unit, int total) {
    final key = ItemCategorizer.categoryKeyFor(name);
    return ExpenseItemDraft(
      name: name,
      quantity: qty,
      unitPriceCents: unit,
      totalCents: total,
      categoryId: key == null ? null : Ids.category(key),
    );
  }

  static DateTime? _findDate(List<String> rows) {
    for (final row in rows) {
      for (final m in _date.allMatches(row)) {
        final d = int.parse(m.group(1)!);
        final mo = int.parse(m.group(2)!);
        var y = int.parse(m.group(3)!);
        if (y < 100) y += 2000;
        if (y < 2000 || y > 2100 || mo < 1 || mo > 12 || d < 1 || d > 31) {
          continue;
        }
        final date = DateTime(y, mo, d);
        if (date.month == mo) return date;
      }
    }
    return null;
  }

  static String? _findInvoiceNumber(List<String> rows, List<String> folded) {
    String? fallback;
    for (var i = 0; i < rows.length; i++) {
      final f = folded[i];
      if (_date.hasMatch(f) && !f.contains('RACUN')) continue;
      final m = _invoiceNumber.firstMatch(f);
      if (m == null) continue;
      final value = m.group(1)!.replaceAll(' ', '');
      if (_containsAny(f, const ['RACUN', 'BR.', 'BROJ'])) return value;
      fallback ??= value;
    }
    return fallback;
  }

  /// PDV: redak "UKUPNO PDV"/"PDV UKUPNO", inače zbroj redaka "PDV xx%".
  static int? _findTax(List<String> rows, List<String> folded) {
    for (var i = 0; i < rows.length; i++) {
      final f = folded[i];
      if (f.contains('PDV') && f.contains('UKUPNO')) {
        final v = _amountAtEnd(rows[i]);
        if (v != null) return v;
      }
    }
    var sum = 0;
    var found = false;
    for (var i = 0; i < rows.length; i++) {
      final f = folded[i];
      if (f.startsWith('PDV') && RegExp(r'\d+\s*%').hasMatch(f)) {
        final v = _amountAtEnd(rows[i]);
        if (v != null) {
          sum += v;
          found = true;
        }
      }
    }
    return found ? sum : null;
  }

  static int? _largestAmount(List<String> rows) {
    int? best;
    for (final row in rows) {
      final v = _amountAtEnd(row);
      if (v != null && (best == null || v > best)) best = v;
    }
    return best;
  }

  static int? _amountAtEnd(String row) {
    final m = _trailingAmount.firstMatch(row);
    return m == null ? null : _signedCents(m.group(1)!);
  }

  static int? _signedCents(String value) {
    final negative = value.startsWith('-');
    final cents = parseMoneyToCents(negative ? value.substring(1) : value);
    if (cents == null) return null;
    return negative ? -cents : cents;
  }

  static double? _parseQuantity(String value) =>
      double.tryParse(value.replaceAll(',', '.'));

  static String _cleanName(String s) => s
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^[\s*#.\-]+|[\s*#.\-]+$'), '')
      .trim();

  static bool _containsAny(String folded, List<String> keywords) =>
      keywords.any(folded.contains);
}

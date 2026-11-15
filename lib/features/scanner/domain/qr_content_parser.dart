import '../../../core/utils/money.dart';
import '../../../data/models/enums.dart';
import '../../../shared/recognition/expense_prefill.dart';
import '../../../shared/recognition/merchant_matcher.dart';

/// Prepoznata vrsta sadržaja QR/2D koda.
enum QrContentType {
  /// QR kod s hrvatskog fiskalnog računa (provjera na porezna.gov.hr).
  fiscalReceipt,

  /// HUB3 2D barkod (PDF417) s hrvatskih uplatnica – režije.
  hub3Payment,

  /// EPC QR kod (SEPA "BCD") za plaćanje.
  epcPayment,

  /// Nepoznat format – sadržaj se samo sprema.
  unknown,
}

/// Rezultat parsiranja sadržaja koda.
class QrParseResult {
  const QrParseResult({required this.type, required this.prefill});

  final QrContentType type;
  final ExpensePrefill prefill;
}

/// Parsira sadržaj QR i drugih 2D kodova s računa i uplatnica.
///
/// Napomena: QR kod fiskalnog računa sadrži samo identifikator (JIR/ZKI),
/// datum i vrijeme te ukupan iznos – NE sadrži naziv trgovine ni artikle.
abstract final class QrContentParser {
  static const String fiscalNoMerchantWarning =
      'QR kod fiskalnog računa ne sadrži naziv trgovine ni artikle. '
      'Odaberite trgovinu ili fotografirajte račun za prepoznavanje artikala.';
  static const String unknownFormatWarning =
      'Format koda nije prepoznat. Sadržaj je spremljen uz račun, '
      'ostale podatke unesite ručno.';
  static const String hrkWarning =
      'Iznos na uplatnici je u kunama (HRK) – provjerite i unesite iznos u eurima.';

  static QrParseResult parse(String raw) {
    final content = raw.trim();
    return _tryFiscal(content) ??
        _tryHub3(content) ??
        _tryEpc(content) ??
        QrParseResult(
          type: QrContentType.unknown,
          prefill: ExpensePrefill(
            source: PrefillSource.qr,
            qrContent: content,
            warnings: const [unknownFormatWarning],
          ),
        );
  }

  // ---------------------------------------------------------------------------
  // Fiskalni račun: https://porezna.gov.hr/rn?jir=...&datv=20261115_1430&izn=1234
  // ---------------------------------------------------------------------------

  static QrParseResult? _tryFiscal(String content) {
    final uri = Uri.tryParse(content);
    if (uri == null || !uri.host.toLowerCase().contains('porezna')) return null;

    final params = {
      for (final e in uri.queryParameters.entries) e.key.toLowerCase(): e.value,
    };
    final hasId = params.containsKey('jir') || params.containsKey('zki');
    if (!hasId) return null;

    final issueDate = _parseFiscalDate(params['datv']);
    final total = _parseFiscalAmount(params['izn']);
    final warnings = <String>[fiscalNoMerchantWarning];
    if (total == null) {
      warnings.add('Iznos nije pronađen u QR kodu – unesite ga ručno.');
    }

    return QrParseResult(
      type: QrContentType.fiscalReceipt,
      prefill: ExpensePrefill(
        source: PrefillSource.qr,
        type: ExpenseType.retail,
        status: PaymentStatus.paid,
        issueDate: issueDate,
        totalCents: total,
        totalConfident: total != null,
        qrContent: content,
        warnings: warnings,
      ),
    );
  }

  /// `datv` u formatu `yyyyMMdd_HHmm`.
  static DateTime? _parseFiscalDate(String? value) {
    if (value == null) return null;
    final m = RegExp(r'^(\d{4})(\d{2})(\d{2})').firstMatch(value);
    if (m == null) return null;
    return _validDate(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
    );
  }

  /// `izn` je iznos bez decimalnog separatora (zadnje dvije znamenke su
  /// centi), npr. `1234` = 12,34 €. Podržan je i zapis s separatorom.
  static int? _parseFiscalAmount(String? value) {
    if (value == null || value.isEmpty) return null;
    if (RegExp(r'^\d+$').hasMatch(value)) return int.parse(value);
    return parseMoneyToCents(value);
  }

  // ---------------------------------------------------------------------------
  // HUB3 (PDF417 na uplatnicama)
  // ---------------------------------------------------------------------------

  static QrParseResult? _tryHub3(String content) {
    final lines = content.split(RegExp(r'\r?\n'));
    if (lines.isEmpty || !lines.first.trim().toUpperCase().startsWith('HRVHUB3')) {
      return null;
    }
    String field(int i) => i < lines.length ? lines[i].trim() : '';

    final currency = field(1).toUpperCase();
    final amountDigits = field(2);
    final total = RegExp(r'^\d+$').hasMatch(amountDigits)
        ? int.parse(amountDigits)
        : null;
    final recipient = field(6);
    final iban = field(9);
    final model = field(10);
    final reference = field(11);
    final description = field(13);

    final known = MerchantMatcher.match([recipient, description]);
    final warnings = <String>[];
    if (currency == 'HRK') warnings.add(hrkWarning);
    if (total == null || total == 0) {
      warnings.add('Iznos nije pronađen na uplatnici – unesite ga ručno.');
    }

    final noteParts = [
      if (description.isNotEmpty) 'Opis: $description',
      if (iban.isNotEmpty) 'IBAN: $iban',
    ];

    return QrParseResult(
      type: QrContentType.hub3Payment,
      prefill: ExpensePrefill(
        source: PrefillSource.qr,
        merchantName: known?.name ?? _nullIfEmpty(recipient),
        categoryKey: known?.categoryKey ?? 'other_utility',
        type: known?.type ?? ExpenseType.utility,
        status: PaymentStatus.unpaid,
        totalCents: currency == 'HRK' ? null : total,
        totalConfident: currency != 'HRK' && total != null && total > 0,
        invoiceNumber: _nullIfEmpty('$model $reference'.trim()),
        qrContent: content,
        note: noteParts.isEmpty ? null : noteParts.join('\n'),
        warnings: warnings,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EPC QR (SEPA): BCD / verzija / charset / SCT / BIC / naziv / IBAN / EUR12.34 / ...
  // ---------------------------------------------------------------------------

  static QrParseResult? _tryEpc(String content) {
    final lines = content.split(RegExp(r'\r?\n'));
    if (lines.length < 7 || lines.first.trim() != 'BCD') return null;
    String field(int i) => i < lines.length ? lines[i].trim() : '';

    final name = field(5);
    final iban = field(6);
    final amountField = field(7).toUpperCase();
    int? total;
    final amountMatch = RegExp(r'^EUR(\d+(?:\.\d{1,2})?)$').firstMatch(amountField);
    if (amountMatch != null) total = parseMoneyToCents(amountMatch.group(1)!);
    final reference = field(9);
    final text = field(10);

    final known = MerchantMatcher.match([name, text]);
    return QrParseResult(
      type: QrContentType.epcPayment,
      prefill: ExpensePrefill(
        source: PrefillSource.qr,
        merchantName: known?.name ?? _nullIfEmpty(name),
        categoryKey: known?.categoryKey ?? 'other_utility',
        type: known?.type ?? ExpenseType.utility,
        status: PaymentStatus.unpaid,
        totalCents: total,
        totalConfident: total != null,
        invoiceNumber: _nullIfEmpty(reference),
        qrContent: content,
        note: [
          if (text.isNotEmpty) 'Opis: $text',
          if (iban.isNotEmpty) 'IBAN: $iban',
        ].join('\n').ifEmptyNull,
        warnings: [
          if (total == null) 'Iznos nije pronađen u QR kodu – unesite ga ručno.',
        ],
      ),
    );
  }

  static DateTime? _validDate(int y, int m, int d) {
    if (y < 2000 || y > 2100 || m < 1 || m > 12 || d < 1 || d > 31) {
      return null;
    }
    final date = DateTime(y, m, d);
    return date.month == m ? date : null;
  }

  static String? _nullIfEmpty(String s) => s.trim().isEmpty ? null : s.trim();
}

extension on String {
  String? get ifEmptyNull => isEmpty ? null : this;
}

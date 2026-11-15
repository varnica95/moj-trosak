import 'package:flutter_test/flutter_test.dart';
import 'package:moj_trosak/data/models/enums.dart';
import 'package:moj_trosak/features/scanner/domain/qr_content_parser.dart';

void main() {
  group('fiskalni račun', () {
    test('JIR, datum i iznos u centima', () {
      final r = QrContentParser.parse(
        'https://porezna.gov.hr/rn?jir=7c5d1e2a-1111-2222-3333-444455556666'
        '&datv=20261115_1432&izn=4599',
      );
      expect(r.type, QrContentType.fiscalReceipt);
      expect(r.prefill.totalCents, 4599);
      expect(r.prefill.totalConfident, isTrue);
      expect(r.prefill.issueDate, DateTime(2026, 11, 15));
      expect(r.prefill.status, PaymentStatus.paid);
      expect(r.prefill.merchantName, isNull);
      expect(r.prefill.warnings, contains(QrContentParser.fiscalNoMerchantWarning));
      expect(r.prefill.qrContent, contains('jir='));
    });

    test('ZKI i iznos s decimalnim zarezom', () {
      final r = QrContentParser.parse(
        'https://porezna.gov.hr/rn/?zki=abcdef0123456789abcdef0123456789'
        '&datv=20260301_0905&izn=12,50',
      );
      expect(r.type, QrContentType.fiscalReceipt);
      expect(r.prefill.totalCents, 1250);
      expect(r.prefill.issueDate, DateTime(2026, 3, 1));
    });

    test('neispravan datum se ignorira', () {
      final r = QrContentParser.parse(
        'https://porezna.gov.hr/rn?jir=x&datv=20261340_0000&izn=100',
      );
      expect(r.prefill.issueDate, isNull);
      expect(r.prefill.totalCents, 100);
    });
  });

  group('HUB3 uplatnica', () {
    const hub3 = 'HRVHUB30\n'
        'EUR\n'
        '000000000004325\n'
        'IVAN HORVAT\n'
        'ILICA 1\n'
        '10000 ZAGREB\n'
        'HEP ELEKTRA D.O.O.\n'
        'ULICA GRADA VUKOVARA 37\n'
        '10000 ZAGREB\n'
        'HR1210010051863000160\n'
        'HR01\n'
        '1234567-890123\n'
        'ELEC\n'
        'Racun za struju 10/2026';

    test('iznos, primatelj, model i poziv na broj', () {
      final r = QrContentParser.parse(hub3);
      expect(r.type, QrContentType.hub3Payment);
      expect(r.prefill.totalCents, 4325);
      expect(r.prefill.totalConfident, isTrue);
      expect(r.prefill.merchantName, 'HEP');
      expect(r.prefill.categoryKey, 'electricity');
      expect(r.prefill.type, ExpenseType.utility);
      expect(r.prefill.status, PaymentStatus.unpaid);
      expect(r.prefill.invoiceNumber, 'HR01 1234567-890123');
      expect(r.prefill.note, contains('HR1210010051863000160'));
      expect(r.prefill.warnings, isEmpty);
    });

    test('nepoznat primatelj ostaje kao naziv', () {
      final r = QrContentParser.parse(
        hub3.replaceFirst('HEP ELEKTRA D.O.O.', 'STAMBENA ZGRADA ILICA 1'),
      );
      expect(r.prefill.merchantName, 'STAMBENA ZGRADA ILICA 1');
      expect(r.prefill.categoryKey, 'other_utility');
    });

    test('iznos u kunama traži ručni unos', () {
      final r = QrContentParser.parse(hub3.replaceFirst('EUR', 'HRK'));
      expect(r.prefill.totalCents, isNull);
      expect(r.prefill.warnings, contains(QrContentParser.hrkWarning));
    });
  });

  test('EPC QR (SEPA)', () {
    final r = QrContentParser.parse(
      'BCD\n002\n1\nSCT\n\nA1 Hrvatska d.o.o.\nHR1723600001101234565\n'
      'EUR29.99\n\nHR00 123456\nRacun 11/2026',
    );
    expect(r.type, QrContentType.epcPayment);
    expect(r.prefill.totalCents, 2999);
    expect(r.prefill.merchantName, 'A1');
    expect(r.prefill.categoryKey, 'internet_phone');
    expect(r.prefill.invoiceNumber, 'HR00 123456');
  });

  test('nepoznat sadržaj se sprema s upozorenjem', () {
    final r = QrContentParser.parse('https://example.com/nesto');
    expect(r.type, QrContentType.unknown);
    expect(r.prefill.qrContent, 'https://example.com/nesto');
    expect(r.prefill.totalCents, isNull);
    expect(r.prefill.warnings, [QrContentParser.unknownFormatWarning]);
  });
}

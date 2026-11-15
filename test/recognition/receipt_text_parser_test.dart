import 'package:flutter_test/flutter_test.dart';
import 'package:moj_trosak/core/utils/ids.dart';
import 'package:moj_trosak/data/models/enums.dart';
import 'package:moj_trosak/features/receipt_ocr/domain/ocr_row_builder.dart';
import 'package:moj_trosak/features/receipt_ocr/domain/receipt_text_parser.dart';
import 'package:moj_trosak/shared/recognition/merchant_matcher.dart';

void main() {
  group('OcrRowBuilder', () {
    test('spaja lijevi i desni stupac u isti red', () {
      const lines = [
        OcrLine(text: '1,29 A', left: 300, top: 101, right: 360, bottom: 121),
        OcrLine(text: 'MLIJEKO 1L', left: 10, top: 100, right: 120, bottom: 120),
        OcrLine(text: 'KRUH', left: 10, top: 130, right: 60, bottom: 150),
        OcrLine(text: '0,99 A', left: 300, top: 132, right: 360, bottom: 152),
      ];
      expect(OcrRowBuilder.buildRows(lines), [
        'MLIJEKO 1L  1,29 A',
        'KRUH  0,99 A',
      ]);
    });

    test('prazni retci se izostavljaju', () {
      expect(
        OcrRowBuilder.buildRows(const [
          OcrLine(text: '  ', left: 0, top: 0, right: 1, bottom: 10),
        ]),
        isEmpty,
      );
    });
  });

  group('ReceiptTextParser', () {
    test('Konzum račun: trgovina, datum, broj, artikli, ukupno, PDV', () {
      final p = ReceiptTextParser.parse(const [
        'KONZUM plus d.o.o.',
        'Marijana Čavića 1a, Zagreb',
        'OIB: 29955634590',
        'Račun br: 1234/P101/3',
        'Datum: 15.11.2026 14:32',
        'MLIJEKO TRAJNO 2,8% 1L',
        '2 x 1,29  2,58 A',
        'KRUH BIJELI 500G  0,99 A',
        'COCA COLA 1,5L  1,79 A',
        'UKUPNO EUR  5,36',
        'PDV 25%  4,29  1,07',
        'Kartica  5,36',
      ]);

      expect(p.merchantName, 'Konzum');
      expect(p.categoryKey, 'groceries');
      expect(p.type, ExpenseType.retail);
      expect(p.status, PaymentStatus.paid);
      expect(p.issueDate, DateTime(2026, 11, 15));
      expect(p.invoiceNumber, '1234/P101/3');
      expect(p.totalCents, 536);
      expect(p.totalConfident, isTrue);
      expect(p.taxCents, 107);

      expect(p.items.length, 3);
      expect(p.items[0].name, 'MLIJEKO TRAJNO 2,8% 1L');
      expect(p.items[0].quantity, 2);
      expect(p.items[0].unitPriceCents, 129);
      expect(p.items[0].totalCents, 258);
      expect(p.items[0].categoryId, Ids.category('item_food'));
      expect(p.items[1].name, 'KRUH BIJELI 500G');
      expect(p.items[1].totalCents, 99);
      expect(p.items[2].categoryId, Ids.category('item_drinks'));
      expect(p.itemsTotalCents, 536);
      expect(p.warnings, isEmpty);
    });

    test('Lidl stil: količina ispod artikla i vaganje', () {
      final p = ReceiptTextParser.parse(const [
        'Lidl Hrvatska d.o.o. k.d.',
        '03.10.2026',
        'Banane  1,58 A',
        '1,264 kg x 1,25 EUR/kg',
        'Jogurt  0,59 A',
        'ZA PLATITI  2,17',
      ]);
      expect(p.merchantName, 'Lidl');
      expect(p.issueDate, DateTime(2026, 10, 3));
      expect(p.totalCents, 217);
      expect(p.items.length, 2);
      expect(p.items[0].name, 'Banane');
      expect(p.items[0].quantity, closeTo(1.264, 0.0001));
      expect(p.items[0].unitPriceCents, 125);
      expect(p.items[0].totalCents, 158);
    });

    test('ukupno u sljedećem retku i popust', () {
      final p = ReceiptTextParser.parse(const [
        'TRGOVINA KOD MATE',
        'Sir gauda  4,50',
        'Popust  -0,50',
        'SVEUKUPNO',
        '4,00',
      ]);
      expect(p.merchantName, 'TRGOVINA KOD MATE');
      expect(p.totalCents, 400);
      expect(p.totalConfident, isTrue);
      expect(p.items.map((i) => i.totalCents), [450, -50]);
      expect(
        p.warnings,
        contains('Trgovina nije prepoznata sa sigurnošću – provjerite naziv.'),
      );
    });

    test('bez retka UKUPNO: iznos se procjenjuje i označava', () {
      final p = ReceiptTextParser.parse(const [
        'DM drogerie markt',
        'Šampon  3,99',
        'Pasta za zube  2,49',
      ]);
      expect(p.merchantName, 'DM');
      expect(p.totalCents, 648);
      expect(p.totalConfident, isFalse);
      expect(p.warnings, contains(ReceiptTextParser.totalNotFoundWarning));
      expect(p.items[0].categoryId, Ids.category('item_hygiene'));
    });

    test('nesukladan zbroj artikala daje upozorenje', () {
      final p = ReceiptTextParser.parse(const [
        'PLODINE d.d.',
        'Riža  1,99',
        'UKUPNO  9,99',
      ]);
      expect(p.totalCents, 999);
      expect(p.warnings.any((w) => w.startsWith('Zbroj artikala')), isTrue);
    });

    test('prazan tekst', () {
      final p = ReceiptTextParser.parse(const [], imagePath: '/tmp/a.jpg');
      expect(p.totalCents, isNull);
      expect(p.imagePath, '/tmp/a.jpg');
      expect(p.warnings, [ReceiptTextParser.nothingFoundWarning]);
    });
  });

  test('MerchantMatcher prepoznaje bez dijakritika i cijele riječi', () {
    expect(MerchantMatcher.match(['ZAGREBAČKI HOLDING d.o.o.'])?.name,
        'Zagrebački holding');
    expect(MerchantMatcher.match(['SPARTAK sport']), isNull);
    expect(MerchantMatcher.match(['INTERSPAR Zagreb'])?.name, 'Spar');
  });
}

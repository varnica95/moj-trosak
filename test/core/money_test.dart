import 'package:flutter_test/flutter_test.dart';
import 'package:moj_trosak/core/utils/money.dart';

void main() {
  group('formatCents', () {
    test('formatira hrvatski zapis s tisućicama', () {
      expect(formatCents(125000), '1.250,00 €');
      expect(formatCents(5), '0,05 €');
      expect(formatCents(123456789), '1.234.567,89 €');
      expect(formatCents(0), '0,00 €');
    });

    test('bez simbola i negativni iznosi', () {
      expect(formatCents(4999, withSymbol: false), '49,99');
      expect(formatCents(-1250), '-12,50 €');
    });

    test('razlika s predznakom', () {
      expect(formatSignedCents(17000), '+170,00 €');
      expect(formatSignedCents(-1250), '-12,50 €');
      expect(formatSignedCents(0), '0,00 €');
    });
  });

  group('parseMoneyToCents', () {
    test('decimalni zarez i točka', () {
      expect(parseMoneyToCents('49,99'), 4999);
      expect(parseMoneyToCents('49.99'), 4999);
      expect(parseMoneyToCents('12,5'), 1250);
      expect(parseMoneyToCents('12'), 1200);
      expect(parseMoneyToCents(',50'), 50);
    });

    test('separatori tisućica', () {
      expect(parseMoneyToCents('1.250,50'), 125050);
      expect(parseMoneyToCents('1,250.50'), 125050);
      expect(parseMoneyToCents('1.250'), 125000);
      expect(parseMoneyToCents('1.250.000'), 125000000);
    });

    test('ignorira valutu i razmake', () {
      expect(parseMoneyToCents(' 1 250,00 € '), 125000);
      expect(parseMoneyToCents('15,00 EUR'), 1500);
    });

    test('odbija neispravan unos', () {
      expect(parseMoneyToCents(''), isNull);
      expect(parseMoneyToCents('abc'), isNull);
      expect(parseMoneyToCents('-5'), isNull);
      expect(parseMoneyToCents('1,2,3'), isNull);
      expect(parseMoneyToCents('12,345'), isNull);
      expect(parseMoneyToCents('12.3456'), isNull);
    });

    test('centsToInput je inverz parsiranja', () {
      for (final cents in [1, 99, 100, 4999, 125050]) {
        expect(parseMoneyToCents(centsToInput(cents)), cents);
      }
    });
  });
}

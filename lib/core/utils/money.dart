/// Rad s novčanim iznosima.
///
/// Svi iznosi se interno čuvaju kao cijeli broj centi (`int`) kako bi se
/// izbjegle greške zaokruživanja s `double`.
library;

final RegExp _digits = RegExp(r'^\d+$');
final RegExp _whitespace = RegExp(r'\s');

/// Formatira iznos u centima u hrvatski format, npr. `1.250,00 €`.
String formatCents(int cents, {bool withSymbol = true}) {
  final negative = cents < 0;
  final abs = cents.abs();
  final euros = abs ~/ 100;
  final rest = abs % 100;
  final text =
      '${negative ? '-' : ''}${_groupThousands(euros)},'
      '${rest.toString().padLeft(2, '0')}';
  return withSymbol ? '$text €' : text;
}

/// Formatira razliku s predznakom, npr. `+170,00 €` ili `-12,50 €`.
String formatSignedCents(int cents) {
  if (cents > 0) return '+${formatCents(cents)}';
  return formatCents(cents);
}

/// Pretvara iznos u tekst za uređivanje u polju za unos, npr. `1250,00`.
String centsToInput(int cents) {
  final abs = cents.abs();
  final sign = cents < 0 ? '-' : '';
  return '$sign${abs ~/ 100},${(abs % 100).toString().padLeft(2, '0')}';
}

/// Parsira korisnički unos u cente.
///
/// Podržava hrvatski (`1.250,50`) i engleski (`1,250.50`) zapis, decimalni
/// zarez ili točku (`12,5`, `12.50`) te ignorira oznaku valute i razmake.
/// Vraća `null` za neispravan ili negativan unos.
int? parseMoneyToCents(String input) {
  var s = input
      .replaceAll('€', '')
      .replaceAll(RegExp('eur', caseSensitive: false), '')
      .replaceAll(_whitespace, '');
  if (s.isEmpty || s.startsWith('-')) return null;
  if (s.startsWith('+')) s = s.substring(1);

  final lastComma = s.lastIndexOf(',');
  final lastDot = s.lastIndexOf('.');

  String integerPart;
  String fractionPart = '';

  if (lastComma >= 0 && lastDot >= 0) {
    // Oba separatora: zadnji je decimalni, drugi su tisućice.
    final decimalSeparator = lastComma > lastDot ? ',' : '.';
    final thousandsSeparator = decimalSeparator == ',' ? '.' : ',';
    final normalized = s.replaceAll(thousandsSeparator, '');
    final parts = normalized.split(decimalSeparator);
    if (parts.length != 2) return null;
    integerPart = parts[0];
    fractionPart = parts[1];
  } else if (lastComma >= 0) {
    final parts = s.split(',');
    if (parts.length != 2) return null;
    integerPart = parts[0];
    fractionPart = parts[1];
  } else if (lastDot >= 0) {
    final parts = s.split('.');
    if (parts.length == 2 && parts[1].length <= 2) {
      integerPart = parts[0];
      fractionPart = parts[1];
    } else if (parts.skip(1).every((p) => p.length == 3)) {
      // Točke kao separatori tisućica, npr. 1.250 ili 1.250.000
      integerPart = parts.join();
    } else {
      return null;
    }
  } else {
    integerPart = s;
  }

  if (integerPart.isEmpty) integerPart = '0';
  if (!_digits.hasMatch(integerPart)) return null;
  if (fractionPart.isNotEmpty && !_digits.hasMatch(fractionPart)) return null;
  if (fractionPart.length > 2) return null;

  final euros = int.parse(integerPart);
  final cents = int.parse(fractionPart.padRight(2, '0'));
  return euros * 100 + cents;
}

String _groupThousands(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    buffer.write(digits[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
  }
  return buffer.toString();
}

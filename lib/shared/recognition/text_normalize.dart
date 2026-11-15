/// Pomoćne funkcije za usporedbu teksta s računa.
///
/// OCR često pogrešno pročita ili izostavi dijakritike, pa se za
/// prepoznavanje ključnih riječi uspoređuje "presavijeni" oblik:
/// velika slova bez dijakritika (Č/Ć → C, Š → S, Ž → Z, Đ → D).
library;

const Map<String, String> _diacritics = {
  'Č': 'C',
  'Ć': 'C',
  'Š': 'S',
  'Ž': 'Z',
  'Đ': 'D',
  'Ü': 'U',
  'Ö': 'O',
  'Ä': 'A',
};

String foldText(String input) {
  final upper = input.toUpperCase();
  final buffer = StringBuffer();
  for (final rune in upper.runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(_diacritics[ch] ?? ch);
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

bool hasLetters(String s, {int min = 2}) =>
    RegExp(r'[A-Za-zČĆŠŽĐčćšžđ]').allMatches(s).length >= min;

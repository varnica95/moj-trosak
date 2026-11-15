/// Redak teksta koji je OCR prepoznao, s položajem na slici (u pikselima).
class OcrLine {
  const OcrLine({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;

  double get centerY => (top + bottom) / 2;
  double get height => bottom - top;
}

/// Spaja OCR retke u vizualne redove računa.
///
/// ML Kit lijevi stupac (nazivi artikala) i desni stupac (cijene) često
/// vraća kao zasebne blokove. Ovdje se retci grupiraju prema vertikalnom
/// položaju i spajaju slijeva nadesno, pa "MLIJEKO 1L" i "1,29 A" postaju
/// jedan red "MLIJEKO 1L  1,29 A".
abstract final class OcrRowBuilder {
  static List<String> buildRows(List<OcrLine> lines) {
    final sorted = [...lines.where((l) => l.text.trim().isNotEmpty)]
      ..sort((a, b) => a.centerY.compareTo(b.centerY));

    final rows = <List<OcrLine>>[];
    for (final line in sorted) {
      final row = rows.isEmpty ? null : rows.last;
      if (row != null && _sameRow(row, line)) {
        row.add(line);
      } else {
        rows.add([line]);
      }
    }

    return [
      for (final row in rows)
        (row..sort((a, b) => a.left.compareTo(b.left)))
            .map((l) => l.text.trim())
            .join('  '),
    ];
  }

  static bool _sameRow(List<OcrLine> row, OcrLine line) {
    final rowCenter =
        row.map((l) => l.centerY).reduce((a, b) => a + b) / row.length;
    final rowHeight =
        row.map((l) => l.height).reduce((a, b) => a + b) / row.length;
    final tolerance =
        0.5 * (rowHeight < line.height ? rowHeight : line.height);
    return (line.centerY - rowCenter).abs() <= tolerance;
  }
}

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../../shared/recognition/expense_prefill.dart';
import '../domain/ocr_row_builder.dart';
import '../domain/receipt_text_parser.dart';

/// OCR računa pomoću Google ML Kit Text Recognition.
///
/// Prepoznavanje se izvodi u potpunosti NA UREĐAJU – fotografija se ne
/// šalje nikakvom vanjskom servisu.
class ReceiptOcrService {
  Future<ExpensePrefill> recognize(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      final lines = <OcrLine>[
        for (final block in result.blocks)
          for (final line in block.lines)
            OcrLine(
              text: line.text,
              left: line.boundingBox.left,
              top: line.boundingBox.top,
              right: line.boundingBox.right,
              bottom: line.boundingBox.bottom,
            ),
      ];
      final rows = OcrRowBuilder.buildRows(lines);
      return ReceiptTextParser.parse(rows, imagePath: imagePath);
    } finally {
      await recognizer.close();
    }
  }
}

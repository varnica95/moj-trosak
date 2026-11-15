import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/receipt_ocr_service.dart';

final receiptOcrServiceProvider = Provider<ReceiptOcrService>(
  (ref) => ReceiptOcrService(),
);

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../shared/recognition/expense_prefill.dart';
import '../application/ocr_providers.dart';

/// Fotografiranje ili odabir fotografije računa i OCR prepoznavanje.
///
/// Vraća prepoznate podatke za obrazac ili `null` ako je korisnik odustao.
/// Ako OCR ne uspije, fotografija se svejedno vraća kako bi se mogla
/// spremiti uz ručno unesene podatke.
Future<ExpensePrefill?> captureReceipt(
  BuildContext context,
  WidgetRef ref,
  ImageSource source,
) async {
  final XFile? file;
  try {
    file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2400,
      maxHeight: 3200,
      imageQuality: 90,
    );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.cameraUnavailable)),
      );
    }
    return null;
  }
  if (file == null || !context.mounted) return null;

  final ocr = ref.read(receiptOcrServiceProvider);
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(width: 20),
            Expanded(child: Text(AppStrings.recognizingText)),
          ],
        ),
      ),
    ),
  );

  try {
    return await ocr.recognize(file.path);
  } catch (_) {
    return ExpensePrefill(
      source: PrefillSource.ocr,
      imagePath: file.path,
      warnings: const [AppStrings.ocrFailed],
    );
  } finally {
    navigator.pop();
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';

/// Kartica "Skeniraj".
///
/// U FAZI 1 skener NIJE implementiran. Ekran to jasno govori i nudi
/// jedinu radnju koja stvarno radi – ručni unos. QR skener (mobile_scanner)
/// dodaje se u FAZI 2, a OCR (Google ML Kit) u FAZI 3.
class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.navScan)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 16),
          Icon(
            Icons.qr_code_scanner,
            size: 72,
            color: AppColors.primary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.scanNotAvailableTitle,
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.scanNotAvailableBody,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.qr_code_2),
                  title: Text(AppStrings.scanPlannedQr),
                  subtitle: Text(AppStrings.scanPlannedQrPhase),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.document_scanner_outlined),
                  title: Text(AppStrings.scanPlannedOcr),
                  subtitle: Text(AppStrings.scanPlannedOcrPhase),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push(AppRoutes.newExpense),
            icon: const Icon(Icons.edit_note),
            label: const Text(AppStrings.manualEntry),
          ),
        ],
      ),
    );
  }
}

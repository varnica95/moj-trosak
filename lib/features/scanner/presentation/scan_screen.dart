import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../receipt_ocr/presentation/receipt_capture.dart';

/// Kartica "Skeniraj": QR/barkod, fotografija računa (OCR) ili ručni unos.
class ScanScreen extends ConsumerWidget {
  const ScanScreen({super.key});

  Future<void> _photo(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    final prefill = await captureReceipt(context, ref, source);
    if (prefill == null || !context.mounted) return;
    context.push(AppRoutes.newExpense, extra: prefill);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.navScan)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _OptionCard(
            icon: Icons.qr_code_scanner,
            title: AppStrings.scanQrTitle,
            subtitle: AppStrings.scanQrSubtitle,
            onTap: () => context.push(AppRoutes.scanQr),
          ),
          const SizedBox(height: 12),
          _OptionCard(
            icon: Icons.photo_camera_outlined,
            title: AppStrings.scanPhotoTitle,
            subtitle: AppStrings.scanPhotoSubtitle,
            onTap: () => _photo(context, ref, ImageSource.camera),
          ),
          const SizedBox(height: 12),
          _OptionCard(
            icon: Icons.photo_library_outlined,
            title: AppStrings.scanGalleryTitle,
            subtitle: AppStrings.scanGallerySubtitle,
            onTap: () => _photo(context, ref, ImageSource.gallery),
          ),
          const SizedBox(height: 12),
          _OptionCard(
            icon: Icons.edit_note,
            title: AppStrings.manualEntry,
            subtitle: AppStrings.manualEntrySubtitle,
            onTap: () => context.push(AppRoutes.newExpense),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_outline, size: 18, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.scanPrivacyNote,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          foregroundColor: AppColors.primary,
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

/// Upozorenja nakon skeniranja/OCR-a: što korisnik treba provjeriti.
class ScanWarnings extends StatelessWidget {
  const ScanWarnings({super.key, required this.warnings, this.onDismiss});

  final List<String> warnings;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    if (warnings.isEmpty) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    return Card(
      color: AppColors.unpaid.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.fact_check_outlined, color: AppColors.unpaid),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.checkRecognized,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final w in warnings)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('• $w', style: textTheme.bodySmall),
                    ),
                ],
              ),
            ),
            if (onDismiss != null)
              IconButton(
                tooltip: AppStrings.close,
                icon: const Icon(Icons.close, size: 18),
                onPressed: onDismiss,
              ),
          ],
        ),
      ),
    );
  }
}

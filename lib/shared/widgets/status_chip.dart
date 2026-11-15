import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/enums.dart';

/// Oznaka statusa plaćanja: plaćeno (zeleno), neplaćeno (narančasto),
/// dospjelo (crveno).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.dueDate});

  final PaymentStatus status;
  final DateTime? dueDate;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final overdue =
        status != PaymentStatus.paid &&
        dueDate != null &&
        dueDate!.isBefore(today);

    final (label, color) = switch (status) {
      PaymentStatus.paid => (AppStrings.statusPaid, AppColors.paid),
      _ when overdue => (AppStrings.statusOverdue, AppColors.overdue),
      _ => (status.label, AppColors.unpaid),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

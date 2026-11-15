import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/utils/money.dart';
import '../../../../data/models/expense.dart';
import '../../../../shared/widgets/category_icons.dart';
import '../../../../shared/widgets/status_chip.dart';

/// Redak računa u popisu.
class ExpenseTile extends StatelessWidget {
  const ExpenseTile({super.key, required this.expense, this.onTap});

  final Expense expense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(expense.categoryColor, context);
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      onTap: onTap ?? () => context.push(AppRoutes.expenseDetail(expense.id)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.14),
        foregroundColor: color,
        child: Icon(categoryIcon(expense.categoryIcon), size: 20),
      ),
      title: Text(
        expense.merchantName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${expense.categoryName ?? AppStrings.uncategorized} · '
        '${formatDate(expense.issueDate)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatCents(expense.totalCents),
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          StatusChip(status: expense.status, dueDate: expense.dueDate),
        ],
      ),
    );
  }
}

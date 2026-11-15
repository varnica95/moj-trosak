import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/utils/money.dart';
import '../../data/models/summaries.dart';
import 'category_icons.dart';

/// Potrošnja po kategorijama s horizontalnim trakama udjela.
class CategoryBreakdown extends StatelessWidget {
  const CategoryBreakdown({
    super.key,
    required this.totals,
    required this.totalCents,
  });

  final List<CategoryTotal> totals;
  final int totalCents;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        for (final t in totals)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Builder(
              builder: (context) {
                final color = categoryColor(t.color, context);
                final share = totalCents == 0 ? 0.0 : t.totalCents / totalCents;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(categoryIcon(t.icon), size: 18, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t.name ?? AppStrings.uncategorized,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          '${(share * 100).round()} %',
                          style: textTheme.bodySmall,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          formatCents(t.totalCents),
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: share.clamp(0.0, 1.0),
                      minHeight: 6,
                      color: color,
                      backgroundColor: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}

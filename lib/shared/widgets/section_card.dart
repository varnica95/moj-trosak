import 'package:flutter/material.dart';

/// Kartica s naslovom sekcije i sadržajem.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.childPadding = const EdgeInsets.fromLTRB(16, 0, 16, 16),
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry childPadding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 12, trailing == null ? 16 : 4, 8),
            child: SizedBox(
              height: 40,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ),
          Padding(padding: childPadding, child: child),
        ],
      ),
    );
  }
}

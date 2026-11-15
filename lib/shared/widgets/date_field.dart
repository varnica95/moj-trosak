import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/utils/date_format.dart';

/// Polje za odabir datuma (prikaz DD.MM.YYYY.).
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.allowClear = false,
    this.icon = Icons.event_outlined,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool allowClear;
  final IconData icon;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 10, 12, 31),
    );
    if (picked != null) onChanged(DateUtils.dateOnly(picked));
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _pick(context),
      child: InputDecorator(
        isEmpty: value == null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: allowClear && value != null
              ? IconButton(
                  tooltip: AppStrings.clearDate,
                  icon: const Icon(Icons.clear),
                  onPressed: () => onChanged(null),
                )
              : null,
        ),
        child: Text(value == null ? '' : formatDate(value!)),
      ),
    );
  }
}

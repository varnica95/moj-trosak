import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import 'empty_state.dart';

/// Jedinstven prikaz stanja učitavanja, greške i podataka.
class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({super.key, required this.value, required this.data});

  final AsyncValue<T> value;
  final Widget Function(T data) data;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => const Center(child: CircularProgressIndicator()),
      // Detalji greške se namjerno ne prikazuju niti logiraju (mogu
      // sadržavati osobne/financijske podatke).
      error: (error, stackTrace) => const Center(
        child: EmptyState(
          icon: Icons.error_outline,
          message: AppStrings.errorLoading,
        ),
      ),
    );
  }
}

extension AsyncValueDataX<T> on AsyncValue<T> {
  /// Trenutni podaci ili `null` ako još nisu dostupni.
  T? get dataOrNull => hasValue ? requireValue : null;
}

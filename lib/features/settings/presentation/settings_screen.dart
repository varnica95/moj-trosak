import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers.dart';
import '../../../shared/widgets/section_card.dart';

/// Postavke. U FAZI 1 prikazuje stvarne postavke i omogućuje brisanje
/// lokalnih podataka. Prijava, sinkronizacija i izvoz dolaze kasnije.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmWipe(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: AppColors.overdue),
        title: const Text(AppStrings.wipeDataTitle),
        content: const Text(AppStrings.wipeDataMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.overdue,
              minimumSize: const Size(64, 40),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(AppStrings.wipeDataConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(appDatabaseProvider).wipeAllData();
    await ref.read(attachmentStorageProvider).deleteAll();
    ref.read(dataRevisionProvider.notifier).bump();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text(AppStrings.wipeDataDone)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.navSettings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const SectionCard(
            title: AppStrings.settingsGeneral,
            childPadding: EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.euro),
                  title: Text(AppStrings.currency),
                  trailing: Text('EUR (€)'),
                ),
                ListTile(
                  leading: Icon(Icons.calendar_today_outlined),
                  title: Text(AppStrings.dateFormat),
                  trailing: Text('DD.MM.YYYY.'),
                ),
                ListTile(
                  leading: Icon(Icons.language),
                  title: Text(AppStrings.language),
                  trailing: Text(AppStrings.languageCroatian),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionCard(
            title: AppStrings.settingsStorage,
            childPadding: EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.phone_android),
                  title: Text(AppStrings.storageLocal),
                  subtitle: Text(AppStrings.storageLocalDescription),
                ),
                ListTile(
                  leading: Icon(Icons.document_scanner_outlined),
                  title: Text(AppStrings.ocrOnDevice),
                  subtitle: Text(AppStrings.ocrOnDeviceDescription),
                ),
                ListTile(
                  leading: Icon(Icons.cloud_off_outlined),
                  title: Text(AppStrings.cloudSync),
                  subtitle: Text(AppStrings.cloudSyncNotYet),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: AppStrings.settingsData,
            childPadding: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(
                Icons.delete_forever_outlined,
                color: AppColors.overdue,
              ),
              title: const Text(
                AppStrings.wipeDataTitle,
                style: TextStyle(color: AppColors.overdue),
              ),
              subtitle: const Text(AppStrings.wipeDataSubtitle),
              onTap: () => _confirmWipe(context, ref),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text(AppStrings.about),
              subtitle: const Text(
                '${AppConstants.appVersion} · ${AppConstants.developmentPhase}',
              ),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: AppConstants.appName,
                applicationVersion:
                    '${AppConstants.appVersion} (${AppConstants.developmentPhase})',
                applicationLegalese: AppStrings.aboutLegalese,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'data/database/app_database.dart';
import 'data/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting(AppConstants.localeCode);
  Intl.defaultLocale = AppConstants.localeCode;

  final database = await AppDatabase.open();

  runApp(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
      child: const MojTrosakApp(),
    ),
  );
}

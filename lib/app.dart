import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/expense_provider.dart';
import 'providers/settings_provider.dart';
import 'models/app_settings.dart';
import 'screens/main_shell.dart';
import 'services/expense_repository.dart';
import 'services/settings_repository.dart';
import 'theme/app_theme.dart';

/// Root widget for SpendTrack.
///
/// The [ExpenseRepository] implementation is injected here so the app stays
/// testable and the persistence layer can be replaced without touching the UI.
class SpendTrackApp extends StatelessWidget {
  const SpendTrackApp({
    super.key,
    required this.repository,
    this.settingsRepository,
  });

  final ExpenseRepository repository;
  final SettingsRepository? settingsRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ExpenseProvider(repository: repository)..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(
            repository:
                settingsRepository ??
                (repository is SettingsRepository
                    ? repository as SettingsRepository
                    : InMemorySettingsRepository()),
          )..initialize(),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
          title: 'SpendTrack',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode == AppThemeMode.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          home: const MainShell(),
        ),
      ),
    );
  }
}

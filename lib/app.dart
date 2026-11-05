import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/expense_provider.dart';
import 'screens/main_shell.dart';
import 'services/expense_repository.dart';
import 'theme/app_theme.dart';

/// Root widget for SpendTrack.
///
/// The [ExpenseRepository] implementation is injected here so the app stays
/// testable and the persistence layer can be replaced without touching the UI.
class SpendTrackApp extends StatelessWidget {
  const SpendTrackApp({super.key, required this.repository});

  final ExpenseRepository repository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ExpenseProvider(repository: repository)..initialize(),
      child: MaterialApp(
        title: 'SpendTrack',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        themeMode: ThemeMode.light,
        home: const MainShell(),
      ),
    );
  }
}

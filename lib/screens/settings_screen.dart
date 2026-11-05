import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_currency.dart';
import '../models/app_settings.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../utils/currency_context.dart';
import '../utils/formatters.dart';
import '../widgets/app_card.dart';

/// Theme, currency, app information, and destructive data actions.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmClear(BuildContext context) async {
    final expenses = context.read<ExpenseProvider>();
    if (!expenses.hasExpenses) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('There are no expenses to clear.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.delete_sweep_rounded, color: context.palette.danger),
        title: const Text('Clear all expenses?'),
        content: Text(
          'This will permanently delete all ${expenses.expenseCount} '
          'expenses from this device. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('settings-clear-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: context.palette.danger,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    final cleared = await expenses.clearExpenses();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            cleared
                ? 'All expenses cleared.'
                : expenses.errorMessage ?? 'Could not clear expenses.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final expenses = context.watch<ExpenseProvider>();

    return SafeArea(
      bottom: false,
      child: ListView(
        key: const Key('settings-list'),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'Personalize SpendTrack for you',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 22),
          _SectionTitle(title: 'Preferences'),
          const SizedBox(height: 10),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: _LeadingIcon(
                    icon: settings.themeMode == AppThemeMode.dark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                  ),
                  title: const Text('Appearance'),
                  subtitle: Text(settings.themeMode.label),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<AppThemeMode>(
                      key: const Key('settings-theme-select'),
                      value: settings.themeMode,
                      items: AppThemeMode.values
                          .map(
                            (mode) => DropdownMenuItem(
                              value: mode,
                              child: Text(mode.label),
                            ),
                          )
                          .toList(),
                      onChanged: (mode) {
                        if (mode != null) settings.setThemeMode(mode);
                      },
                    ),
                  ),
                ),
                const Divider(indent: 64),
                ListTile(
                  leading: const _LeadingIcon(icon: Icons.payments_rounded),
                  title: const Text('Currency'),
                  subtitle: Text(settings.currency.label),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<AppCurrency>(
                      key: const Key('settings-currency-select'),
                      value: settings.currency,
                      items: AppCurrency.values
                          .map(
                            (currency) => DropdownMenuItem(
                              value: currency,
                              child: Text(currency.code),
                            ),
                          )
                          .toList(),
                      onChanged: (currency) {
                        if (currency != null) settings.setCurrency(currency);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (settings.errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              settings.errorMessage!,
              style: TextStyle(color: context.palette.danger),
            ),
          ],
          const SizedBox(height: 24),
          _SectionTitle(title: 'Data'),
          const SizedBox(height: 10),
          AppCard(
            padding: EdgeInsets.zero,
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                key: const Key('settings-clear-expenses'),
                leading: _LeadingIcon(
                  icon: Icons.delete_outline_rounded,
                  danger: true,
                ),
                title: Text(
                  'Clear all expenses',
                  style: TextStyle(color: context.palette.danger),
                ),
                subtitle: Text('${expenses.expenseCount} saved on this device'),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: context.palette.textMuted,
                ),
                onTap: () => _confirmClear(context),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle(title: 'About'),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: context.palette.brand,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 27,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'SpendTrack',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Personal expense tracking, stored locally on your device.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                const Divider(),
                _InfoRow(label: 'Version', value: '1.0.0'),
                _InfoRow(label: 'Storage', value: 'Local SQLite database'),
                _InfoRow(
                  label: 'Example format',
                  value: formatCurrency(1234.56, currency: context.currency),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) =>
      Text(title, style: Theme.of(context).textTheme.titleMedium);
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({required this.icon, this.danger = false});
  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 38,
    decoration: BoxDecoration(
      color: danger ? context.palette.dangerSoft : context.palette.accentSoft,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(
      icon,
      size: 19,
      color: danger ? context.palette.danger : context.palette.accent,
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(value, style: Theme.of(context).textTheme.labelLarge),
      ],
    ),
  );
}

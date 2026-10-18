import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utilities/responsive_utils.dart';
import '../../core/utilities/settings_state.dart';
import '../../l10n/app_localizations.dart';

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsState>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appearance)),
      body: Builder(
        builder: (context) {
          final r = ResponsiveUtils(context);
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: r.maxContentWidth),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // === DARK MODE ===
                  _buildSectionHeader(l10n.darkMode, theme),
                  _buildSettingsCard(
                    children: [
                      _buildSwitchTile(
                        icon: settings.darkMode
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        iconColor: settings.darkMode ? Colors.indigo : Colors.amber,
                        title: l10n.darkMode,
                        subtitle: l10n.darkModeDescription,
                        value: settings.darkMode,
                        onChanged: (value) => settings.setDarkMode(value),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // === LANGUAGE ===
                  _buildSectionHeader(l10n.language, theme),
                  _buildSettingsCard(
                    children: [
                      _buildSettingsTile(
                        icon: Icons.language_rounded,
                        iconColor: Colors.blue,
                        title: l10n.language,
                        subtitle: _getLanguageName(settings.locale.languageCode),
                        onTap: () => _showLanguageDialog(context, settings),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // === FONT ===
                  _buildSectionHeader(l10n.fontFamily, theme),
                  _buildSettingsCard(
                    children: [
                      _buildSettingsTile(
                        icon: Icons.font_download_rounded,
                        iconColor: Colors.purple,
                        title: l10n.fontFamily,
                        subtitle: settings.fontFamily,
                        onTap: () => _showFontFamilySheet(context, settings),
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildSettingsTile(
                        icon: Icons.format_size_rounded,
                        iconColor: Colors.teal,
                        title: l10n.fontSize,
                        subtitle: settings.getFontSizeName(),
                        onTap: () => _showFontSizeSheet(context, settings),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // === PREVIEW ===
                  _buildSectionHeader('Preview', theme),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 0,
                    color: Colors.grey.withValues(alpha: 0.08),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'The quick brown fox jumps over the lazy dog',
                            style: TextStyle(
                              fontFamily: settings.fontFamily,
                              fontSize: settings.fontSize + 2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Dari: دری یک زبان فارسی است\nPashto: پښتو یو ژبه ده\nEnglish: English is a global language',
                            style: TextStyle(
                              fontFamily: settings.fontFamily,
                              fontSize: settings.fontSize,
                              height: 1.5,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Size: ${settings.fontSize.round()}pt • Family: ${settings.fontFamily}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      color: Colors.grey.withValues(alpha: 0.08),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500))
          : null,
      trailing: Switch.adaptive(value: value, onChanged: onChanged),
      onTap: () => onChanged(!value),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500))
          : null,
      trailing: Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'fa': return 'دری (Dari)';
      case 'ps': return 'پښتو (Pashto)';
      default: return 'English';
    }
  }

  void _showLanguageDialog(BuildContext context, SettingsState settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: SettingsState.availableLanguages.map((lang) {
            return RadioListTile<String>(
              title: Text(lang['nativeName']!),
              subtitle: Text(lang['name']!),
              value: lang['code']!,
              groupValue: settings.locale.languageCode,
              onChanged: (value) {
                if (value != null) settings.setLanguage(value);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(ctx)!.cancel)),
        ],
      ),
    );
  }

  /// Full-screen bottom sheet for font family selection
  void _showFontFamilySheet(BuildContext context, SettingsState settings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => Scaffold(
          appBar: AppBar(
            title: const Text('Font Family'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done'),
              ),
            ],
          ),
          body: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: SettingsState.availableFonts.length,
            itemBuilder: (context, index) {
              final font = SettingsState.availableFonts[index];
              final isSelected = settings.fontFamily == font['name'];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 0,
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Aa',
                        style: TextStyle(
                          fontFamily: font['name'],
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    font['displayName']!,
                    style: TextStyle(
                      fontFamily: font['name'],
                      fontSize: 18,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    font['name']!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary)
                      : Icon(Icons.radio_button_unchecked, color: Colors.grey.shade400),
                  onTap: () {
                    settings.setFontFamily(font['name']!);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Full-screen bottom sheet for font size selection
  void _showFontSizeSheet(BuildContext context, SettingsState settings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(ctx)!.fontSize,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to change — preview updates instantly',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ...SettingsState.fontSizes.entries.map((entry) {
                final isSelected = settings.fontSize == entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    elevation: 0,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                        : Colors.grey.withValues(alpha: 0.06),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${entry.value.round()}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: entry.value,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '${entry.value.round()}pt',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary)
                          : Icon(Icons.radio_button_unchecked, color: Colors.grey.shade400),
                      onTap: () {
                        settings.setFontSize(entry.value);
                      },
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

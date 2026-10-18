import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/security/backup_encryption.dart';
import '../../core/utilities/settings_state.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _storageInfo = '';

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dbFile = File('${dir.path}/workspace.sqlite');
      final dbSize = await dbFile.exists() ? await dbFile.length() : 0;

      final notesCount = await database.getNotesCount();
      final tasksCount = await database.getTasksCount();
      final filesCount = await database.getFilesCount();
      final remindersCount = await database.getRemindersCount();

      final totalItems = notesCount + tasksCount + filesCount + remindersCount;
      final sizeKb = dbSize ~/ 1024;
      final sizeStr = sizeKb > 1024
          ? '${(sizeKb / 1024).toStringAsFixed(1)} MB'
          : '$sizeKb KB';

      if (!mounted) return;
      setState(() {
        _storageInfo = '$totalItems items · $sizeStr';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _storageInfo = 'N/A');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsState>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // === APPEARANCE SECTION ===
          _buildSectionHeader(l10n.appearance, theme),

          // Dark Mode
          _buildSettingsTile(
            icon: settings.darkMode ? Icons.dark_mode : Icons.light_mode,
            iconColor: settings.darkMode ? Colors.indigo : Colors.amber,
            title: l10n.darkMode,
            subtitle: l10n.darkModeDescription,
            trailing: Switch(
              value: settings.darkMode,
              onChanged: (value) => settings.setDarkMode(value),
            ),
          ),

          // Language
          _buildSettingsTile(
            icon: Icons.language,
            iconColor: Colors.blue,
            title: l10n.language,
            subtitle: _getLanguageName(settings.locale.languageCode),
            onTap: () => _showLanguageDialog(context, settings),
          ),

          // Font Family
          _buildSettingsTile(
            icon: Icons.font_download,
            iconColor: Colors.purple,
            title: l10n.fontFamily,
            subtitle: settings.fontFamily,
            onTap: () => _showFontFamilyDialog(context, settings),
          ),

          // Font Size
          _buildSettingsTile(
            icon: Icons.format_size,
            iconColor: Colors.teal,
            title: l10n.fontSize,
            subtitle: settings.getFontSizeName(),
            onTap: () => _showFontSizeDialog(context, settings),
          ),

          const Divider(height: 32),

          // === DATA SECTION ===
          _buildSectionHeader(l10n.data, theme),

          _buildSettingsTile(
            icon: Icons.storage,
            iconColor: Colors.blueGrey,
            title: l10n.storageUsage,
            subtitle: _storageInfo.isEmpty ? '...' : _storageInfo,
          ),

          _buildSettingsTile(
            icon: Icons.backup,
            iconColor: Colors.teal,
            title: l10n.backupAndRestore,
            subtitle: l10n.backupAndRestoreDescription,
            onTap: () => context.push('/backup'),
          ),

          _buildSettingsTile(
            icon: Icons.delete_sweep,
            iconColor: Colors.red,
            title: l10n.clearTrash,
            subtitle: l10n.clearTrashDescription,
            onTap: () => _clearTrash(context),
          ),

          _buildSettingsTile(
            icon: Icons.info_outline,
            iconColor: Colors.grey,
            title: l10n.clearCache,
            subtitle: l10n.clearCacheDescription,
            onTap: () => _clearCache(context),
          ),

          const Divider(height: 32),

          // === NOTIFICATIONS SECTION ===
          _buildSectionHeader(l10n.notifications, theme),

          Consumer<SettingsState>(
            builder: (context, settings, _) => _buildSettingsTile(
              icon: Icons.notifications,
              iconColor: Colors.amber,
              title: l10n.notifications,
              subtitle: settings.notificationsEnabled
                  ? l10n.notificationsDescription
                  : l10n.notificationsDisabled,
              trailing: Switch(
                value: settings.notificationsEnabled,
                onChanged: (value) => settings.setNotificationsEnabled(value),
              ),
            ),
          ),

          _buildSettingsTile(
            icon: Icons.notifications_active,
            iconColor: Colors.deepOrange,
            title: l10n.notificationSound,
            subtitle: l10n.defaultSound,
            onTap: () => context.push('/settings/notifications'),
          ),

          Consumer<SettingsState>(
            builder: (context, settings, _) => _buildSettingsTile(
              icon: Icons.vibration,
              iconColor: Colors.pink,
              title: l10n.vibration,
              subtitle: l10n.vibrationDescription,
              trailing: Switch(
                value: settings.vibrationEnabled,
                onChanged: (value) => settings.setVibrationEnabled(value),
              ),
            ),
          ),

          const Divider(height: 32),

          // === SECURITY SECTION ===
          _buildSectionHeader(l10n.security, theme),

          _buildSettingsTile(
            icon: Icons.lock,
            iconColor: Colors.deepPurple,
            title: l10n.appLock,
            subtitle: l10n.appLockDescription,
            onTap: () => context.push('/app-lock-setup'),
          ),

          Consumer<SettingsState>(
            builder: (context, settings, _) => _buildSettingsTile(
              icon: Icons.enhanced_encryption,
              iconColor: Colors.indigo,
              title: l10n.encryptBackups,
              subtitle: settings.encryptBackups ? 'Enabled' : l10n.encryptBackupsDescription,
              onTap: () => BackupEncryption.toggle(context, !settings.encryptBackups),
              trailing: Switch(
                value: settings.encryptBackups,
                onChanged: (value) => BackupEncryption.toggle(context, value),
              ),
            ),
          ),

          const Divider(height: 32),

          // === ABOUT SECTION ===
          _buildSectionHeader(l10n.about, theme),

          _buildSettingsTile(
            icon: Icons.info_outline,
            iconColor: Colors.blue,
            title: l10n.version,
            subtitle: '1.0.0',
          ),

          _buildSettingsTile(
            icon: Icons.privacy_tip_outlined,
            iconColor: Colors.green,
            title: l10n.privacyPolicy,
            subtitle: l10n.howWeHandleData,
            onTap: () => context.push('/settings/privacy-policy'),
          ),

          _buildSettingsTile(
            icon: Icons.description_outlined,
            iconColor: Colors.orange,
            title: l10n.termsOfService,
            onTap: () => context.push('/settings/terms'),
          ),

          _buildSettingsTile(
            icon: Icons.star_outline,
            iconColor: Colors.amber,
            title: l10n.rateApp,
            subtitle: l10n.rateAppDescription,
            onTap: _rateApp,
          ),

          // Privacy Notice
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.shield, size: 32, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  l10n.yourPrivateWorkspace,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.noAccountRequired,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right, size: 20) : null),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
        ],
      ),
    );
  }

  void _showFontFamilyDialog(BuildContext context, SettingsState settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.fontFamily),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: SettingsState.availableFonts.map((font) {
            return RadioListTile<String>(
              title: Text(font['displayName']!, style: TextStyle(fontFamily: font['name'])),
              value: font['name']!,
              groupValue: settings.fontFamily,
              onChanged: (value) {
                if (value != null) settings.setFontFamily(value);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
        ],
      ),
    );
  }

  void _showFontSizeDialog(BuildContext context, SettingsState settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.fontSize),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: SettingsState.fontSizes.entries.map((entry) {
            return RadioListTile<double>(
              title: Text(entry.key, style: TextStyle(fontSize: entry.value)),
              value: entry.value,
              groupValue: settings.fontSize,
              onChanged: (value) {
                if (value != null) settings.setFontSize(value);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
        ],
      ),
    );
  }

  void _clearTrash(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final count = await database.getTrashedCount();
      if (!mounted) return;

      if (count == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noTrashedItems)),
        );
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.clearTrashConfirm),
          content: Text(l10n.trashedItemsCount(count)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: Text(l10n.delete),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        await database.clearAllTrashed();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.trashCleared)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.error)),
      );
    }
  }

  Future<void> _rateApp() async {
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.openStoreListing();
        return;
      }
    } catch (_) {}
    try {
      await launchUrl(
        Uri.parse('https://play.google.com/store/apps/details?id=com.example.note_app'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the store. Please rate us on Google Play.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _clearCache(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      for (final file in files) {
        try {
          await file.delete(recursive: true);
        } catch (_) {}
      }      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cacheCleared)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cacheCleared)),
      );
    }
  }
}

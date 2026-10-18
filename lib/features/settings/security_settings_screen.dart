import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/security/backup_encryption.dart';
import '../../core/utilities/responsive_utils.dart';
import '../../core/utilities/settings_state.dart';
import '../../l10n/app_localizations.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _isProcessing = false;

  Future<void> _toggleEncryptBackups(bool enable) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    final ok = await BackupEncryption.toggle(context, enable);
    if (mounted) setState(() => _isProcessing = false);
    if (!ok && mounted) {
      // Refresh so a failed disable attempt keeps the switch consistent.
      context.read<SettingsState>().notifyListeners();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.security)),
      body: Builder(
        builder: (context) {
          final r = ResponsiveUtils(context);
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: r.maxContentWidth),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // === APP LOCK ===
                  _buildSectionHeader(l10n.appLock, theme),
                  _buildSettingsCard(
                    children: [
                      _buildSettingsTile(
                        icon: Icons.lock_rounded,
                        iconColor: Colors.deepPurple,
                        title: l10n.appLock,
                        subtitle: l10n.appLockDescription,
                        onTap: () => context.push('/app-lock-setup'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // === ENCRYPTION ===
                  _buildSectionHeader(l10n.encryptBackups, theme),
                  _buildSettingsCard(
                    children: [
                       Consumer<SettingsState>(
                         builder: (context, settings, _) {
                           return _buildSettingsTile(
                             icon: Icons.enhanced_encryption_rounded,
                             iconColor: Colors.indigo,
                             title: l10n.encryptBackups,
                             subtitle: settings.encryptBackups
                                 ? 'Enabled — backups are encrypted with your password'
                                 : l10n.encryptBackupsDescription,
                             onTap: _isProcessing
                                 ? null
                                 : () => _toggleEncryptBackups(!settings.encryptBackups),
                             trailing: _isProcessing
                                 ? const SizedBox(
                                     width: 24,
                                     height: 24,
                                     child: CircularProgressIndicator(strokeWidth: 2),
                                   )
                                 : Switch.adaptive(
                                     value: settings.encryptBackups,
                                     onChanged: _toggleEncryptBackups,
                                   ),
                           );
                         },
                       ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // === DATA PROTECTION ===
                  _buildSectionHeader('Data Protection', theme),
                  _buildSettingsCard(
                    children: [
                      _buildInfoTile(
                        icon: Icons.shield_rounded,
                        color: Colors.green,
                        title: 'On-Device Storage',
                        subtitle: 'All data is stored locally on your device',
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildInfoTile(
                        icon: Icons.lock_clock_rounded,
                        color: Colors.blue,
                        title: 'No Cloud Sync',
                        subtitle: 'Your data never leaves your device',
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildInfoTile(
                        icon: Icons.enhanced_encryption_rounded,
                        color: Colors.indigo,
                        title: 'AES-256 Encryption',
                        subtitle: 'Military-grade encryption for vault items',
                      ),
                    ],
                  ),
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

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
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
      trailing: trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade400)
              : null),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
    );
  }
}

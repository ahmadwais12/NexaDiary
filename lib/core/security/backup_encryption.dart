import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../utilities/settings_state.dart';
import 'encryption_service.dart';

/// Shared logic for toggling backup encryption from anywhere in the app
/// (Security settings page and the quick switch on the Settings page).
class BackupEncryption {
  BackupEncryption._();

  static const Duration _disposeDelay = Duration(milliseconds: 500);

  static Future<bool> toggle(BuildContext context, bool enable) async {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.read<SettingsState>();
    try {
      if (enable) {
        final password = await _showPasswordDialog(
          context,
          title: l10n.encryptBackups,
          hint: 'Enter encryption password',
          icon: Icons.enhanced_encryption_rounded,
        );
        if (password == null || password.isEmpty) return false;

        final hash = await EncryptionService().hashPin(password);
        await settings.setEncryptBackups(enabled: true, keyHash: hash);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Backup encryption enabled'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return true;
      } else {
        // Disabling: verify current password when one is set
        if (settings.encryptBackupsKeyHash.isNotEmpty) {
          final password = await _showPasswordDialog(
            context,
            title: 'Disable Encryption',
            hint: 'Enter current password to disable',
            icon: Icons.lock_open_rounded,
          );
          if (password == null || password.isEmpty) return false;

          final verified =
              await EncryptionService().verifyPin(password, settings.encryptBackupsKeyHash);
          if (!verified) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('❌ Incorrect password'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return false;
          }
        }

        await settings.setEncryptBackups(enabled: false, keyHash: '');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Backup encryption disabled'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return true;
      }
    } catch (e) {
      debugPrint('[BackupEncryption] Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
        );
      }
      return false;
    }
  }

  static Future<String?> _showPasswordDialog(
    BuildContext context, {
    required String title,
    required String hint,
    required IconData icon,
  }) async {
    final controller = TextEditingController();
    bool obscure = true;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          icon: Icon(icon, size: 36, color: Theme.of(ctx).colorScheme.primary),
          title: Text(title),
          content: TextField(
            controller: controller,
            obscureText: obscure,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: const Icon(Icons.key_rounded),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setDialogState(() => obscure = !obscure),
              ),
            ),
            autofocus: true,
            onSubmitted: (_) => Navigator.pop(ctx, controller.text),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
    // Dispose after the dialog's exit animation finishes.
    Future.delayed(_disposeDelay, controller.dispose);
    return result;
  }
}

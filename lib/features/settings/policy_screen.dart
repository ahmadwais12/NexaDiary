import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

enum PolicyType { privacy, terms }

/// Full-screen viewer for Privacy Policy and Terms of Service.
class PolicyScreen extends StatelessWidget {
  final PolicyType type;

  const PolicyScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isPrivacy = type == PolicyType.privacy;
    final title = isPrivacy ? l10n.privacyPolicy : l10n.termsOfService;
    final sections = isPrivacy ? _privacySections(theme) : _termsSections(theme);

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: sections.length,
            itemBuilder: (context, index) {
              final (heading, body) = sections[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            heading,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 36),
                      child: Text(
                        body,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.65,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<(String, String)> _privacySections(ThemeData theme) => [
        (
          'Overview',
          'NexaDiary respects your privacy. This policy explains what data the app '
              'stores, where it lives, and how it is protected. By using NexaDiary you '
              'agree to this policy.',
        ),
        (
          'Data We Collect',
          'We do not collect any personal data. All content you create — notes, tasks, '
              'files, reminders, and calendar events — is stored locally on your device '
              'only. The app has no servers and no cloud sync.',
        ),
        (
          'Permissions',
          'The app requests access to storage (for backups and attachments), camera and '
              'microphone (for photos, videos, and voice notes), notifications (for '
              'reminders), and exact alarms (for reliable reminders). These permissions '
              'are used solely for in-app features and never to transmit your data.',
        ),
        (
          'Encryption',
          'Vault items are encrypted with AES-256. When you enable backup encryption, '
              'your backup files are encrypted with a password that only you know. Your '
              'password is never stored in plain form and cannot be recovered by us.',
        ),
        (
          'Third-Party Services',
          'NexaDiary does not share data with third parties. Advertising, if shown, is '
              'served on-device without attaching it to your identity or your content.',
        ),
        (
          'Data Deletion',
          'You can delete individual items or clear all app data at any time from your '
              "device's system settings. Deleted items move to Trash first, and "
              'permanent deletion removes them irrecoverably.',
        ),
        (
          'Changes',
          'If this policy changes, updates will appear within the app. Continued use of '
              'the app after changes means you accept the revised policy.',
        ),
      ];

  List<(String, String)> _termsSections(ThemeData theme) => [
        (
          'Acceptance',
          'By installing or using NexaDiary you agree to these terms. If you do not '
              'agree, please discontinue use of the app.',
        ),
        (
          'License',
          'You are granted a limited, non-exclusive, non-transferable license to use '
              'NexaDiary for personal productivity on devices you own or control.',
        ),
        (
          'Your Content',
          'You keep full ownership of everything you create in the app. You are '
              'responsible for keeping backups of important content; encrypted backups '
              'cannot be restored without your password.',
        ),
        (
          'Acceptable Use',
          'Do not use the app for unlawful purposes or attempt to reverse-engineer, '
              'redistribute, or resell any part of it.',
        ),
        (
          'Disclaimer',
          'The app is provided "as is" without warranties of any kind. While we strive '
              'for reliability, we are not liable for data loss, missed reminders, or '
              'damages arising from use of the app.',
        ),
        (
          'Termination',
          'You may stop using the app at any time by uninstalling it, which also '
              'removes all locally stored data.',
        ),
        (
          'Contact',
          'For questions about these terms, reach out through the support contact '
              'listed on the About page.',
        ),
      ];
}

import 'package:flutter/material.dart';

import '../../core/utilities/responsive_utils.dart';
import '../../l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final r = ResponsiveUtils(context);

    final sections = [
      _PolicySection(
        icon: Icons.cloud_off_rounded,
        color: Colors.blue,
        title: 'No Account Required',
        content:
            'NexaDiary does not require you to create an account. We do not collect your name, email address, or any personal identifiers. The app works fully offline and anonymously.',
      ),
      _PolicySection(
        icon: Icons.phone_android_rounded,
        color: Colors.green,
        title: 'Local Data Storage',
        content:
            'All your notes, tasks, reminders, files, and media are stored locally on your device only. Your data never leaves your phone unless you explicitly create a backup and choose to share it.',
      ),
      _PolicySection(
        icon: Icons.lock_rounded,
        color: Colors.deepPurple,
        title: 'Security',
        content:
            'Your data can be protected with a PIN code and biometric authentication (fingerprint/face). Backups can be encrypted. All data is stored in your device\'s private app storage which other apps cannot access.',
      ),
      _PolicySection(
        icon: Icons.campaign_rounded,
        color: Colors.orange,
        title: 'Advertising',
        content:
            'The app displays ads through Google AdMob. Google may collect device identifiers and usage data to serve relevant ads as described in Google\'s Privacy Policy. You can manage ad personalization in your Google settings.',
      ),
      _PolicySection(
        icon: Icons.share_rounded,
        color: Colors.teal,
        title: 'Data Sharing',
        content:
            'We do not sell, rent, or share your personal notes or files with anyone. Only anonymous usage statistics required by the advertising SDK may be processed by Google.',
      ),
      _PolicySection(
        icon: Icons.folder_delete_rounded,
        color: Colors.red,
        title: 'Data Deletion',
        content:
            'You have full control over your data. Deleting the app permanently removes all local data including notes, files, and backups stored within the app.',
      ),
      _PolicySection(
        icon: Icons.update_rounded,
        color: Colors.indigo,
        title: 'Changes to This Policy',
        content:
            'We may update this Privacy Policy from time to time. Changes will be posted on this page with an updated effective date.',
      ),
      _PolicySection(
        icon: Icons.email_rounded,
        color: Colors.pink,
        title: 'Contact Us',
        content:
            'If you have any questions about this Privacy Policy, please contact us at support@nexadiary.app.',
      ),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor:
                isDark ? const Color(0xFF1A1A2E) : const Color(0xFF635BFF),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                AppLocalizations.of(context)!.privacyPolicy,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF1A1A2E), const Color(0xFF2D2B55)]
                        : [const Color(0xFF635BFF), const Color(0xFF8B83FF)],
                  ),
                ),
                child: Center(
                  child: Icon(Icons.privacy_tip_rounded,
                      size: 72, color: Colors.white.withValues(alpha: 0.25)),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: r.maxContentWidth),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 22,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'NexaDiary is designed to be private by default — your data stays on your device.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...sections.map((s) => _buildSectionCard(theme, s)),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Last updated: August 2026',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(ThemeData theme, _PolicySection section) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: section.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(section.icon, color: section.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    section.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                      height: 1.5,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicySection {
  final IconData icon;
  final Color color;
  final String title;
  final String content;
  const _PolicySection({
    required this.icon,
    required this.color,
    required this.title,
    required this.content,
  });
}

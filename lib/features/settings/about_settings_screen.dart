import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';

import '../../core/utilities/responsive_utils.dart';
import '../../l10n/app_localizations.dart';

class AboutSettingsScreen extends StatelessWidget {
  const AboutSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.about)),
      body: Builder(
        builder: (context) {
          final r = ResponsiveUtils(context);
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: r.maxContentWidth),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // === APP INFO ===
                  _buildSectionHeader('App Info', theme),
                  _buildSettingsCard(
                    children: [
                      _buildSettingsTile(
                        icon: Icons.numbers_rounded,
                        iconColor: Colors.blue,
                        title: l10n.version,
                        subtitle: '1.0.0',
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildSettingsTile(
                        icon: Icons.privacy_tip_rounded,
                        iconColor: Colors.green,
                        title: l10n.privacyPolicy,
                        subtitle: l10n.howWeHandleData,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PrivacyPolicyScreen(),
                          ),
                        ),
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildSettingsTile(
                        icon: Icons.description_rounded,
                        iconColor: Colors.orange,
                        title: l10n.termsOfService,
                        subtitle: 'Terms and conditions',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TermsOfServiceScreen(),
                          ),
                        ),
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildSettingsTile(
                        icon: Icons.star_rounded,
                        iconColor: Colors.amber,
                        title: l10n.rateApp,
                        subtitle: l10n.rateAppDescription,
                        onTap: () => _rateApp(context),
                      ),
                    ],
                  ),

                  // === ABOUT APP DESCRIPTION ===
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.shield_rounded,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.aboutApp,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.aboutDescription,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade500,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            )
          : null,
      trailing: onTap != null
          ? Icon(Icons.chevron_right_rounded,
              size: 20, color: Colors.grey.shade400)
          : null,
      onTap: onTap,
    );
  }

  Future<void> _rateApp(BuildContext context) async {
    final inAppReview = InAppReview.instance;

    try {
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      } else {
        // Fallback: open store listing directly
        await inAppReview.openStoreListing(
          appStoreId: '1234567890', // Replace with your iOS App Store ID
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open rating: $e')),
        );
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════
// Full-Screen Privacy Policy Page
// ═══════════════════════════════════════════════════════════

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.privacy_tip_rounded,
                  size: 48,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'NexaDiary Privacy Policy',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Last updated: January 2024',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ),
            const SizedBox(height: 32),

            // Introduction
            _buildIntroCard(theme),
            const SizedBox(height: 24),

            // Sections
            _buildExpandableSection(
              context: context,
              icon: Icons.storage_rounded,
              title: 'Data Collection',
              content: '''We collect information that you provide directly to us, such as when you:

• Create an account or profile
• Use our services to create notes, tasks, or reminders
• Contact us for support or feedback
• Participate in surveys or promotions

The types of information we may collect include:
• Personal identifiers (name, email address)
• User-generated content (notes, tasks, files)
• Device information (device type, operating system)
• Usage data (features used, time spent)''',
              theme: theme,
            ),
            _buildExpandableSection(
              context: context,
              icon: Icons.analytics_rounded,
              title: 'Data Usage',
              content: '''We use the information we collect to:

• Provide, maintain, and improve our services
• Process and complete transactions
• Send technical notices and support messages
• Respond to your comments and questions
• Develop new products and services
• Detect, prevent, and address technical issues
• Monitor and analyze usage patterns and trends''',
              theme: theme,
            ),
            _buildExpandableSection(
              context: context,
              icon: Icons.phone_android_rounded,
              title: 'Data Storage & Security',
              content: '''Your data is stored securely on your device using industry-standard encryption. We do not store your personal notes, tasks, or other content on our servers unless you explicitly choose to use our backup feature.

Security measures include:
• AES-256 encryption for stored data
• Biometric authentication support
• Secure PIN protection
• Local-only storage (no cloud sync by default)
• Regular security audits''',
              theme: theme,
            ),
            _buildExpandableSection(
              context: context,
              icon: Icons.share_rounded,
              title: 'Data Sharing',
              content: '''We do not sell or rent your personal information to third parties. We may share your information only in the following circumstances:

• With your explicit consent
• For legal reasons or to comply with laws
• To protect our rights, privacy, safety, or property
• In connection with a merger, acquisition, or sale of assets
• With service providers who assist in our operations (under strict confidentiality)''',
              theme: theme,
            ),
            _buildExpandableSection(
              context: context,
              icon: Icons.gavel_rounded,
              title: 'Your Rights',
              content: '''You have the right to:

• Access your personal data
• Correct inaccurate data
• Delete your data and account
• Export your data
• Opt-out of data collection
• Withdraw consent at any time

To exercise these rights, please contact us using the information below.''',
              theme: theme,
            ),
            _buildExpandableSection(
              context: context,
              icon: Icons.contact_support_rounded,
              title: 'Contact Us',
              content: '''If you have any questions about this Privacy Policy, please contact us:

Email: privacy@nexadiary.app
Website: https://nexadiary.app/privacy
Address: Kabul, Afghanistan''',
              theme: theme,
            ),

            const SizedBox(height: 40),

            // Footer
            Center(
              child: TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back to About'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'At NexaDiary, we are committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy explains how we collect, use, and safeguard your data when you use our application.',
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
        ),
      ),
    );
  }

  Widget _buildExpandableSection({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String content,
    required ThemeData theme,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.grey.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Full-Screen Terms of Service Page
// ═══════════════════════════════════════════════════════════

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.description_rounded,
                  size: 48,
                  color: Colors.orange,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'NexaDiary Terms of Service',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Effective date: January 2024',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ),
            const SizedBox(height: 32),

            // Introduction
            Card(
              elevation: 0,
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Welcome to NexaDiary. By accessing or using our application, you agree to be bound by these Terms of Service. Please read them carefully before using the app.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sections
            _buildExpandableSection(
              context: context,
              icon: Icons.handshake_rounded,
              title: 'Acceptance of Terms',
              content: '''By accessing and using NexaDiary, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the application.

These terms constitute a legally binding agreement between you and NexaDiary.''',
              theme: theme,
            ),
            _buildExpandableSection(
              context: context,
              icon: Icons.app_settings_alt_rounded,
              title: 'Use License',
              content: '''Permission is granted to temporarily use NexaDiary for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not:

• Modify or copy the materials
• Use the materials for any commercial purpose
• Attempt to decompile or reverse engineer any software
• Remove any copyright or other proprietary notations
• Transfer the materials to another person

This license shall automatically terminate if you violate any of these restrictions.''',
              theme: theme,
            ),
            _buildExpandableSection(
              context: context,
              icon: Icons.account_circle_rounded,
              title: 'User Responsibilities',
              content: '''As a user of NexaDiary, you are responsible for:

• Maintaining the confidentiality of your account credentials
• All activities that occur under your account
• Ensuring your device meets the minimum system requirements
• Keeping your app updated to the latest version
• Backing up your data regularly

You agree not to use the app for any unlawful purpose or in any way that could damage the application or its services.''',
              theme: theme,
            ),
            _buildExpandableSection(
              context: context,
              icon: Icons.copyright_rounded,
              title: 'Intellectual Property',
              content: '''All content, features, and functionality of NexaDiary are owned by us and are protected by international copyright, trademark, patent, trade secret, and other intellectual property laws.

You may not reproduce, distribute, modify, create derivative works of, publicly display, or in any way exploit any of the content or materials without prior written permission.''',
              theme: theme,
            ),
            _buildExpandableSection(
              context: context,
              icon: Icons.warning_amber_rounded,
              title: 'Limitation of Liability',
              content: '''In no event shall NexaDiary be liable for any damages arising out of the use or inability to use the materials on this application, even if we have been notified of the possibility of such damages.

The materials and services are provided "as is" without warranties of any kind, either express or implied.''',
              theme: theme,
            ),
            _buildExpandableSection(
              context: context,
              icon: Icons.update_rounded,
              title: 'Modifications',
              content: '''We reserve the right to revise these terms of service at any time without notice. By using this application, you are agreeing to be bound by the current version of these terms.

We will notify users of any material changes through the application or via email.''',
              theme: theme,
            ),
            _buildExpandableSection(
              context: context,
              icon: Icons.flag_rounded,
              title: 'Governing Law',
              content: '''These terms and conditions are governed by and construed in accordance with the laws of Afghanistan, and you irrevocably submit to the exclusive jurisdiction of the courts in that State.

Any disputes arising from these terms shall be resolved through negotiation first, then through binding arbitration if necessary.''',
              theme: theme,
            ),
            _buildExpandableSection(
              context: context,
              icon: Icons.contact_support_rounded,
              title: 'Contact Information',
              content: '''For any questions regarding these Terms of Service, please contact us:

Email: legal@nexadiary.app
Website: https://nexadiary.app/terms
Address: Kabul, Afghanistan''',
              theme: theme,
            ),

            const SizedBox(height: 40),

            // Footer
            Center(
              child: TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back to About'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableSection({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String content,
    required ThemeData theme,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.grey.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/utilities/app_theme.dart';
import '../../core/utilities/settings_state.dart';
import '../../l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const int _totalPages = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish() async {
    final settings = context.read<SettingsState>();
    await settings.setOnboardingComplete(true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.onboardingDone),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.go('/home');
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLastPage = _currentPage == _totalPages - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: _finish, child: Text(l10n.skip)),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: [
                  _WelcomePage(l10n: l10n),
                  _LanguagePage(l10n: l10n),
                  _ThemePage(l10n: l10n),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalPages, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.primaryColor
                              : Theme.of(context).colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: isLastPage
                          ? _finish
                          : () => _goToPage(_currentPage + 1),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text(isLastPage ? l10n.getStarted : l10n.next),
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

class _WelcomePage extends StatelessWidget {
  final AppLocalizations l10n;
  const _WelcomePage({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      header: Container(
        width: 170,
        height: 170,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.all(20),
        child: Image.asset(
          'assets/logo/NexaDiary_mark.png',
          fit: BoxFit.contain,
        ),
      ),
      title: l10n.welcomeTitle,
      message: l10n.welcomeMessage,
    );
  }
}

class _LanguagePage extends StatelessWidget {
  final AppLocalizations l10n;
  const _LanguagePage({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    final theme = Theme.of(context);

    return _PageScaffold(
      icon: Icons.language,
      iconColors: [Colors.blue, Colors.blueAccent],
      title: l10n.chooseLanguageTitle,
      message: l10n.chooseLanguageMessage,
      child: Column(
        children: SettingsState.availableLanguages.map((lang) {
          final selected = settings.locale.languageCode == lang['code'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SelectableCard(
              selected: selected,
              onTap: () => settings.setLanguage(lang['code']!),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  lang['code'] == 'en' ? Icons.g_translate : Icons.translate,
                  color: theme.colorScheme.primary,
                ),
              ),
              title: lang['nativeName']!,
              subtitle: lang['name']!,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ThemePage extends StatelessWidget {
  final AppLocalizations l10n;
  const _ThemePage({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();

    return _PageScaffold(
      icon: Icons.palette_outlined,
      iconColors: [Colors.deepPurple, AppTheme.accentColor],
      title: l10n.chooseThemeTitle,
      message: l10n.chooseThemeMessage,
      child: Row(
        children: [
          Expanded(
            child: _ThemeCard(
              label: l10n.lightTheme,
              icon: Icons.light_mode,
              color: Colors.amber,
              background: const Color(0xFFF8FAFC),
              foreground: const Color(0xFF1F2937),
              selected: !settings.darkMode,
              onTap: () => settings.setDarkMode(false),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _ThemeCard(
              label: l10n.darkTheme,
              icon: Icons.dark_mode,
              color: Colors.indigo,
              background: const Color(0xFF0F172A),
              foreground: const Color(0xFFF1F5F9),
              selected: settings.darkMode,
              onTap: () => settings.setDarkMode(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageScaffold extends StatelessWidget {
  final IconData icon;
  final List<Color> iconColors;
  final Widget? header;
  final String title;
  final String message;
  final Widget? child;

  const _PageScaffold({
    this.icon = Icons.note_alt_outlined,
    this.iconColors = const [AppTheme.primaryColor, AppTheme.secondaryColor],
    this.header,
    required this.title,
    required this.message,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 12),
          if (header != null)
            header!
          else
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: iconColors,
                ),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Icon(icon, size: 48, color: Colors.white),
            ),
          const SizedBox(height: 28),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          ?child,
        ],
      ),
    );
  }
}

class _SelectableCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget leading;
  final String title;
  final String subtitle;

  const _SelectableCard({
    required this.selected,
    required this.onTap,
    required this.leading,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.08)
          : theme.cardTheme.color ?? theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color background;
  final Color foreground;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
    required this.foreground,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.08)
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 210,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: color),
                      const Spacer(),
                      Container(
                        width: 60,
                        height: 6,
                        decoration: BoxDecoration(
                          color: foreground.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 40,
                        height: 6,
                        decoration: BoxDecoration(
                          color: foreground.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 20,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

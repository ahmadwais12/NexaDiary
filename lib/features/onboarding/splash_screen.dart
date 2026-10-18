import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/utilities/app_theme.dart';
import '../../core/utilities/responsive_utils.dart';
import '../../core/utilities/settings_state.dart';
import '../../l10n/app_localizations.dart';
import '../lock/app_lock_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  bool _showLock = false;
  bool _settingsLoaded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _redirect();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _redirect() async {
    final settings = context.read<SettingsState>();
    try {
      await Future.wait<void>([
        settings.loadSettings().timeout(
          const Duration(seconds: 5),
          onTimeout: () {},
        ),
        Future<void>.delayed(const Duration(seconds: 3)),
      ]);
    } catch (_) {
      // If settings loading fails, proceed anyway
    }
    if (!mounted) return;
    setState(() => _settingsLoaded = true);
    if (!settings.isOnboardingComplete) {
      context.go('/onboarding');
    } else if (settings.isAppLockEnabled) {
      setState(() => _showLock = true);
    } else {
      context.go('/home');
    }
  }

  void _onUnlocked() {
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_settingsLoaded && _showLock) {
      return AppLockScreen(onUnlocked: _onUnlocked);
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFEEF2FF),
              Color(0xFFE0E7FF),
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Builder(
                    builder: (ctx) {
                      final r = ResponsiveUtils(ctx);
                      final logoSize = r.isIpad ? 260.0 : (r.isTablet ? 220.0 : 190.0);
                      return SizedBox(
                        width: logoSize,
                        height: logoSize,
                        child: Image.asset(
                          'assets/logo/NexaDiary_mark.png',
                          fit: BoxFit.contain,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Builder(
                    builder: (ctx) {
                      final r = ResponsiveUtils(ctx);
                      return Text(
                        'NexaDiary',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: r.isIpad ? 42 : (r.isTablet ? 36 : 32),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.yourPrivateWorkspaceTagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.primaryColor.withValues(alpha: 0.7),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

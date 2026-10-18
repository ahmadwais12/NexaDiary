import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/ads/ad_service.dart';
import 'core/ads/mandatory_ad_screen.dart';
import 'core/database/app_database.dart';
import 'core/notifications/alarm_screen.dart';
import 'core/notifications/expiry_checker.dart';
import 'core/notifications/notification_service.dart';
import 'core/storage/file_storage_service.dart';
import 'core/utilities/app_router.dart';
import 'core/utilities/app_theme.dart';
import 'core/utilities/settings_state.dart';
import 'features/lock/app_lock_screen.dart';
import 'l10n/app_localizations.dart';

late AppDatabase database;
late FileStorageService fileStorageService;
late NotificationService notificationService;
late AdService adService;
late ExpiryChecker expiryChecker;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize core services
  database = AppDatabase();
  fileStorageService = FileStorageService();
  notificationService = NotificationService();

  // Initialize file storage with timeout
  try {
    await fileStorageService.initialize().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint('FileStorageService init timed out');
      },
    );
  } catch (e) {
    debugPrint('FileStorageService init failed: $e');
  }

  // Initialize notifications with timeout
  try {
    await notificationService.initialize().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint('NotificationService init timed out');
      },
    );
  } catch (e) {
    debugPrint('NotificationService init failed: $e');
  }

  // Request notification permission so alarms work even when app is closed
  try {
    await notificationService.requestPermission();
  } catch (e) {
    debugPrint('Notification permission request failed: $e');
  }

  // Initialize expiry checker for auto-updating expired items
  expiryChecker = ExpiryChecker(
    database: database,
    notificationService: notificationService,
  );
  // Run initial check and start periodic checks
  expiryChecker.checkExpiredItems();
  expiryChecker.startPeriodicCheck();

  // Initialize ad service
  adService = AdService();
  try {
    await adService.initialize().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('AdService init timed out');
      },
    );
  } catch (e) {
    debugPrint('AdService init failed: $e');
  }

  // Start loading ad in background — don't block runApp
  adService.loadAd();

  runApp(const WorkspaceApp());
}

class WorkspaceApp extends StatefulWidget {
  const WorkspaceApp({super.key});

  @override
  State<WorkspaceApp> createState() => _WorkspaceAppState();
}

class _WorkspaceAppState extends State<WorkspaceApp>
    with WidgetsBindingObserver {
  static const _splashDuration = Duration(seconds: 3);

  final SettingsState _settingsState = SettingsState();
  bool _launchAdShown = false;
  bool _adScreenShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _settingsState.loadSettings();

    // Set up ad callbacks
    adService.onAdCompleted = _onAdCompleted;
    adService.onIntervalAdTriggered = _onIntervalAdTriggered;

    // Set up real alarm callback — shows full-screen alarm when alarm fires
    notificationService.onAlarmRinging = _showAlarmScreen;

    _showLaunchAdAfterSplash();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Timer? _adPollTimer;

  /// Wait for splash to finish, then show ad.
  /// Polls every 500ms until ad is loaded or 15s timeout.
  void _showLaunchAdAfterSplash() {
    Timer(_splashDuration, () {
      if (!mounted || _launchAdShown) return;
      _launchAdShown = true;
      _pollForAd(retries: 0);
    });
  }

  void _pollForAd({required int retries}) {
    if (!mounted || _adScreenShowing) {
      _adPollTimer?.cancel();
      return;
    }

    // Check context
    final navState = appRouter.routerDelegate.navigatorKey.currentState;
    if (navState == null) {
      debugPrint('[Main] Nav state null, retry ${retries + 1}');
      if (retries < 30) {
        Future.delayed(const Duration(milliseconds: 500), () => _pollForAd(retries: retries + 1));
      }
      return;
    }

    // Check ad
    if (adService.adLoaded && !adService.isShowingAd) {
      _adPollTimer?.cancel();
      debugPrint('[Main] Ad ready, showing launch ad');
      _showMandatoryAdScreen();
      return;
    }

    // Retry
    debugPrint('[Main] Waiting for ad (attempt ${retries + 1})');
    if (retries < 30) {
      Future.delayed(const Duration(milliseconds: 500), () => _pollForAd(retries: retries + 1));
    } else {
      debugPrint('[Main] Ad not ready after 15s, skipping');
    }
  }

  /// Called when a viewing period completes (ad screen can be closed).
  void _onAdCompleted() {
    debugPrint('[Main] Ad viewing period completed');
  }

  /// Called by AdService when a 15-minute interval triggers a new ad.
  void _onIntervalAdTriggered() {
    if (_adScreenShowing) return;
    debugPrint('[Main] Interval ad triggered');
    // Retry with context wait since this can fire anytime
    _showMandatoryAdScreen();
  }

  bool _alarmScreenShowing = false;

  /// Push the full-screen alarm when an alarm fires.
  void _showAlarmScreen(AlarmSettings alarmSettings) {
    final navState = appRouter.routerDelegate.navigatorKey.currentState;
    if (navState == null) {
      debugPrint('[Main] Navigator null, cannot show alarm screen');
      return;
    }
    if (_alarmScreenShowing) return;

    _alarmScreenShowing = true;
    debugPrint('[Main] Pushing AlarmScreen for alarm ${alarmSettings.id}');
    navState.push(
      PageRouteBuilder(
        opaque: true,
        barrierDismissible: false,
        pageBuilder: (context, _, __) => AlarmScreen(
          alarmSettings: alarmSettings,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ).then((_) {
      _alarmScreenShowing = false;
      debugPrint('[Main] Alarm screen dismissed');
    });
  }

  /// Push the mandatory ad screen.
  void _showMandatoryAdScreen() {
    final navState = appRouter.routerDelegate.navigatorKey.currentState;
    if (navState == null) {
      debugPrint('[Main] Navigator state is null, cannot push ad screen');
      return;
    }
    if (_adScreenShowing) return;

    _adScreenShowing = true;
    debugPrint('[Main] Pushing MandatoryAdScreen');
    navState.push(
      PageRouteBuilder(
        opaque: true,
        barrierDismissible: false,
        pageBuilder: (context, _, __) => MandatoryAdScreen(adService: adService),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ).then((_) {
      _adScreenShowing = false;
      debugPrint('[Main] Ad screen dismissed, user back on app');
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Manage ad timer lifecycle
    if (state == AppLifecycleState.paused) {
      adService.onPause();
    } else if (state == AppLifecycleState.resumed) {
      adService.onResume();
    }

    // App lock lifecycle
    if (state == AppLifecycleState.paused && _settingsState.isAppLockEnabled) {
      _lockedFromBackground = true;
    }
    if (state == AppLifecycleState.resumed && _lockedFromBackground && _settingsState.isAppLockEnabled) {
      _lockedFromBackground = false;
      _showReLockScreen();
    }

    // Check expired items when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      expiryChecker.checkExpiredItems();
    }
  }

  bool _lockedFromBackground = false;

  void _showReLockScreen() {
    final navigatorKey = appRouter.routerDelegate.navigatorKey;
    final context = navigatorKey.currentContext;
    if (context == null) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (context, _, __) => AppLockScreen(
          onUnlocked: () => Navigator.of(context).pop(),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _settingsState,
      child: Consumer<SettingsState>(
        builder: (context, settings, _) {
          return MaterialApp.router(
            title: 'NexaDiary',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme.copyWith(
              textTheme: AppTheme.lightTheme.textTheme.copyWith(
                bodyLarge: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  fontFamily: settings.fontFamily,
                  fontSize: settings.fontSize,
                ),
                bodyMedium: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontFamily: settings.fontFamily,
                  fontSize: settings.fontSize,
                ),
                bodySmall: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  fontFamily: settings.fontFamily,
                ),
                titleLarge: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontFamily: settings.fontFamily,
                ),
                titleMedium: AppTheme.lightTheme.textTheme.titleMedium
                    ?.copyWith(fontFamily: settings.fontFamily),
                titleSmall: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                  fontFamily: settings.fontFamily,
                ),
              ),
            ),
            darkTheme: AppTheme.darkTheme.copyWith(
              textTheme: AppTheme.darkTheme.textTheme.copyWith(
                bodyLarge: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                  fontFamily: settings.fontFamily,
                  fontSize: settings.fontSize,
                ),
                bodyMedium: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                  fontFamily: settings.fontFamily,
                  fontSize: settings.fontSize,
                ),
                bodySmall: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                  fontFamily: settings.fontFamily,
                ),
                titleLarge: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                  fontFamily: settings.fontFamily,
                ),
                titleMedium: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                  fontFamily: settings.fontFamily,
                ),
                titleSmall: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                  fontFamily: settings.fontFamily,
                ),
              ),
            ),
            themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
            locale: settings.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}

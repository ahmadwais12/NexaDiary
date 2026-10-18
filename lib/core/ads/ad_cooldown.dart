import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// Manages ad display cooldown, launch count, and frequency limiting.
///
/// All ad settings are hardcoded:
/// - Ads are always enabled
/// - Ad interval: 30 seconds
/// - Ads shown after every 15 minutes of usage
/// - Minimum ad display time: 3 seconds
/// - Maximum ad display time: >6 seconds
class AdCooldown {
  static const bool _adsAlwaysEnabled = true;
  static const int _adIntervalSeconds = 30;
  static const int _showAdAfterMinutes = 15;
  static const int _minimumAdDisplaySeconds = 3;
  // Maximum ad display time: >6 seconds (handled by ad SDK)

  final AppDatabase _database;

  AdCooldown(this._database);

  /// Check if an ad should be shown based on all conditions.
  Future<bool> shouldShowAd() async {
    final adSettingsData = await _database.getAdSettings();

    if (!_adsAlwaysEnabled) return false;

    // Check if enough time has passed since last ad (ad interval: 30 seconds)
    if (adSettingsData.lastAdShownAt != null) {
      final timeSinceLastAd = DateTime.now().difference(adSettingsData.lastAdShownAt!);
      final cooldown = Duration(seconds: _adIntervalSeconds);

      if (timeSinceLastAd < cooldown) {
        return false;
      }
    }

    // Check if app has been used for at least the minimum time
    // Ads shown after every 15 minutes of usage
    if (adSettingsData.launchCount > 0) {
      final launchInterval = Duration(minutes: _showAdAfterMinutes);
      final timeSinceLastAd = adSettingsData.lastAdShownAt != null
          ? DateTime.now().difference(adSettingsData.lastAdShownAt!)
          : Duration.zero;

      if (timeSinceLastAd < launchInterval) {
        return false;
      }
    }

    return true;
  }

  /// Increment the launch count after app startup.
  Future<void> onAppLaunch() async {
    await _syncConfiguredDefaults();
    await _database.incrementLaunchCount();
  }

  /// Record that an ad was shown.
  Future<void> onAdShown() async {
    await _database.recordAdShown();
  }

  /// Get current ad settings.
  Future<AdSetting> getSettings() async {
    await _syncConfiguredDefaults();
    return _database.getAdSettings();
  }

  Future<void> _syncConfiguredDefaults() async {
    final current = await _database.getAdSettings();
    if (current.adsEnabled == _adsAlwaysEnabled &&
        current.minimumAdIntervalMinutes == _showAdAfterMinutes &&
        current.minimumLaunchesBeforeAds == _minimumAdDisplaySeconds) {
      return;
    }

    await _database.updateAdSettings(
      AdSettingsCompanion(
        id: Value(current.id),
        adsEnabled: const Value(_adsAlwaysEnabled),
        minimumAdIntervalMinutes: const Value(_showAdAfterMinutes),
        minimumLaunchesBeforeAds: const Value(_minimumAdDisplaySeconds),
      ),
    );
  }

  /// Update ad interval.
  Future<void> setInterval(int minutes) async {
    await _syncConfiguredDefaults();
  }

  /// Update minimum launches before ads.
  Future<void> setMinimumLaunches(int count) async {
    await _syncConfiguredDefaults();
  }

  /// Enable or disable ads.
  Future<void> setAdsEnabled(bool enabled) async {
    await _syncConfiguredDefaults();
  }
}

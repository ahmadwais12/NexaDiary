import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Ad configuration constants and test IDs.
class AdConfig {
  AdConfig._();

  // Test Ad Unit IDs (development only)
  // Replace with production IDs before release
  static const String testAdUnitIdAndroid =
      'ca-app-pub-3940256099942544/9257395921';
  static const String testAdUnitIdIos = 'ca-app-pub-3940256099942544/5575463023';

  static const String testInterstitialAdUnitIdAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String testInterstitialAdUnitIdIos =
      'ca-app-pub-3940256099942544/4411468910';

  // Production Ad Unit IDs (placeholder - replace before release)
  static const String productionAdUnitIdAndroid =
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String productionAdUnitIdIos =
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String productionInterstitialAdUnitIdAndroid =
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String productionInterstitialAdUnitIdIos =
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';

  // Default values
  static const int defaultAdIntervalSeconds = 30;
  static const int defaultShowAdAfterMinutes = 15;
  static const int defaultMinimumAdDisplaySeconds = 3;
  static const int defaultMaximumAdDisplaySeconds = 6;
  static const Duration adExpirationDuration = Duration(hours: 4);
  static const Duration reachabilityTimeout = Duration(seconds: 3);

  /// Get the appropriate ad unit ID based on build mode.
  static String get appOpenAdUnitId {
    const bool isProduction = bool.fromEnvironment('dart.vm.product');
    if (isProduction) {
      return _isIOS ? productionAdUnitIdIos : productionAdUnitIdAndroid;
    } else {
      return _isIOS ? testAdUnitIdIos : testAdUnitIdAndroid;
    }
  }

  static String get interstitialAdUnitId {
    const bool isProduction = bool.fromEnvironment('dart.vm.product');
    if (isProduction) {
      return _isIOS
          ? productionInterstitialAdUnitIdIos
          : productionInterstitialAdUnitIdAndroid;
    } else {
      return _isIOS ? testInterstitialAdUnitIdIos : testInterstitialAdUnitIdAndroid;
    }
  }

  static bool get _isIOS {
    if (kIsWeb) return false;
    return Platform.isIOS;
  }
}

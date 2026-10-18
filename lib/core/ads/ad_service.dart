import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

/// Callback type for when an ad has been completed/dismissed.
typedef OnAdCompleted = void Function();

/// Callback for when the interval ad should be shown (needs screen push).
typedef OnIntervalAdTriggered = void Function();

/// A complete, reusable interstitial ad service.
///
/// Shows a single interstitial ad at app launch and every [intervalMinutes].
/// The user can dismiss the ad after it finishes loading and displaying.
class AdService extends ChangeNotifier {
  // --- Configuration ---
  static const int intervalMinutes = 15;
  static const int maxAds = 1;

  // --- State ---
  bool _isInitialized = false;
  bool _isShowingAd = false;

  // Ad
  InterstitialAd? _interstitialAd;
  bool _adLoaded = false;

  // Viewing state
  bool _viewingPeriodActive = false;
  bool _viewingPeriodComplete = false;

  // 15-minute interval timer
  Timer? _intervalTimer;
  int _secondsSinceLastAd = 0;
  bool _isPaused = false;
  bool _intervalTimerRunning = false;

  // Callbacks
  OnAdCompleted? onAdCompleted;
  OnIntervalAdTriggered? onIntervalAdTriggered;
  bool _onAdCompletedFired = false;

  // --- Getters ---
  bool get isInitialized => _isInitialized;
  bool get isShowingAd => _isShowingAd;
  bool get adLoaded => _adLoaded;
  bool get viewingPeriodActive => _viewingPeriodActive;
  bool get viewingPeriodComplete => _viewingPeriodComplete;
  int get secondsSinceLastAd => _secondsSinceLastAd;
  bool get isPaused => _isPaused;
  bool get intervalTimerRunning => _intervalTimerRunning;

  int get secondsUntilNextAd =>
      (intervalMinutes * 60) - _secondsSinceLastAd;

  // ========================================================================
  // Initialization
  // ========================================================================

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('[AdService] Initialized');
    } catch (e) {
      debugPrint('[AdService] Failed to initialize: $e');
    }
  }

  // ========================================================================
  // Internet check
  // ========================================================================

  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ========================================================================
  // Loading (batch pre-load)
  // ========================================================================

  Future<void> loadAd() async {
    if (_adLoaded) return;
    if (!await _hasInternet()) {
      debugPrint('[AdService] No internet — skipping ad load');
      return;
    }

    debugPrint('[AdService] Loading interstitial ad (unit: ${AdConfig.interstitialAdUnitId})...');

    try {
      await InterstitialAd.load(
        adUnitId: AdConfig.interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _adLoaded = true;
            debugPrint('[AdService] Ad loaded successfully');
            notifyListeners();
          },
          onAdFailedToLoad: (error) {
            debugPrint('[AdService] Ad failed to load: ${error.message}');
            _adLoaded = false;
            notifyListeners();
          },
        ),
      );
    } catch (e) {
      debugPrint('[AdService] Error loading ad: $e');
      _adLoaded = false;
    }
  }

  // ========================================================================
  // Show next ad
  // ========================================================================

  bool showAd() {
    final ad = _interstitialAd;
    if (ad == null) {
      debugPrint('[AdService] No ad available to show');
      return false;
    }

    _isShowingAd = true;
    _onAdCompletedFired = false;

    debugPrint('[AdService] Showing ad');

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('[AdService] Ad displayed');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdService] Ad dismissed');
        ad.dispose();
        _interstitialAd = null;
        _adLoaded = false;
        _isShowingAd = false;
        _viewingPeriodComplete = true;
        _viewingPeriodActive = false;
        _onAdDismissed();
        notifyListeners();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdService] Ad failed to show: ${error.message}');
        ad.dispose();
        _interstitialAd = null;
        _adLoaded = false;
        _isShowingAd = false;
        _viewingPeriodComplete = true;
        _viewingPeriodActive = false;
        _onAdDismissed();
        notifyListeners();
      },
    );

    ad.show();
    notifyListeners();
    return true;
  }

  // ========================================================================
  // Show ad (single ad flow)
  // ========================================================================

  void startAd() {
    if (_viewingPeriodActive) return;

    _viewingPeriodActive = true;
    _viewingPeriodComplete = false;
    _onAdCompletedFired = false;

    debugPrint('[AdService] Ad flow started');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showAd();
    });
  }

  /// User taps close after ad finishes.
  void dismissAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _adLoaded = false;
    _isShowingAd = false;
    _viewingPeriodActive = false;
    _onAdDismissed();
    notifyListeners();
  }

  // ========================================================================
  // 15-minute interval timer
  // ========================================================================

  void startIntervalTimer() {
    if (_intervalTimerRunning) return;
    _intervalTimerRunning = true;
    _secondsSinceLastAd = 0;
    _intervalTimer?.cancel();
    _intervalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;
      _secondsSinceLastAd++;
      if (_secondsSinceLastAd >= intervalMinutes * 60) {
        timer.cancel();
        _intervalTimerRunning = false;
        _triggerIntervalAd();
      }
      notifyListeners();
    });
    debugPrint('[AdService] Interval timer started (${intervalMinutes}min)');
  }

  void _triggerIntervalAd() {
    if (_isShowingAd || _viewingPeriodActive) return;
    debugPrint('[AdService] 15-min interval reached — requesting ad screen');

    // Pre-load one ad, then notify main.dart to push the MandatoryAdScreen
    _loadThenShowInterval();
  }

  Future<void> _loadThenShowInterval() async {
    _adLoaded = false;
    _interstitialAd = null;
    await loadAd();

    if (_adLoaded && !_isShowingAd && !_viewingPeriodActive) {
      debugPrint('[AdService] Notifying listener to show interval ad screen');
      onIntervalAdTriggered?.call();
    } else {
      debugPrint('[AdService] No ad available for interval, retrying in 30s');
      Timer(const Duration(seconds: 30), () {
        if (!_viewingPeriodActive && !_isShowingAd) {
          _triggerIntervalAd();
        }
      });
    }
  }

  void _resetIntervalTimer() {
    _intervalTimerRunning = false;
    startIntervalTimer();
  }

  // ========================================================================
  // Lifecycle
  // ========================================================================

  void onPause() {
    _isPaused = true;
    debugPrint('[AdService] Paused');
  }

  void onResume() {
    _isPaused = false;
    debugPrint('[AdService] Resumed');
  }

  // ========================================================================
  // Internal
  // ========================================================================

  void _onAdDismissed() {
    if (!_onAdCompletedFired) {
      _onAdCompletedFired = true;
      onAdCompleted?.call();
    }
    _resetIntervalTimer();
  }

  // ========================================================================
  // Cleanup
  // ========================================================================

  @override
  void dispose() {
    _intervalTimer?.cancel();
    _interstitialAd?.dispose();
    super.dispose();
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../network/network_service.dart';
import 'ad_cooldown.dart';
import 'ad_config.dart';
import 'ad_service.dart';
import 'mandatory_ad_screen.dart';

class AppOpenAdManager {
  final NetworkService _networkService;
  final AdCooldown _adCooldown;
  final AdService _adService;

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;

  bool get isAdAvailable => _appOpenAd != null;
  bool get isShowingAd => _isShowingAd;

  AppOpenAdManager({
    required NetworkService networkService,
    required AdCooldown adCooldown,
    required AdService adService,
  })  : _networkService = networkService,
        _adCooldown = adCooldown,
        _adService = adService;

  Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('Failed to initialize MobileAds: $e');
    }
  }

  Future<void> loadAd() async {
    if (_appOpenAd != null) return;

    try {
      await AppOpenAd.load(
        adUnitId: AdConfig.appOpenAdUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenAd = ad;
            debugPrint('App Open Ad loaded');
          },
          onAdFailedToLoad: (error) {
            debugPrint('App Open Ad failed to load: ${error.message}');
            _appOpenAd = null;
          },
        ),
      );
    } catch (e) {
      debugPrint('Error loading App Open Ad: $e');
      _appOpenAd = null;
    }
  }

  Future<bool> showAdIfAvailable({BuildContext? context}) async {
    if (_isShowingAd) return false;

    final isOnline = await _networkService.checkInternet();
    if (!isOnline) return false;

    final shouldShow = await _adCooldown.shouldShowAd();
    if (!shouldShow) return false;

    if (context != null && context.mounted) {
      _isShowingAd = true;
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: true,
          barrierDismissible: false,
          pageBuilder: (context, _, __) => MandatoryAdScreen(
            adService: _adService,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
      return true;
    }

    if (_appOpenAd == null) return false;

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        debugPrint('App Open Ad shown');
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        _appOpenAd = null;
        ad.dispose();
        _adCooldown.onAdShown();
        loadAd();
        debugPrint('App Open Ad dismissed');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        _appOpenAd = null;
        ad.dispose();
        debugPrint('App Open Ad failed to show: ${error.message}');
      },
    );

    try {
      await _appOpenAd!.show();
      return true;
    } catch (e) {
      debugPrint('Error showing App Open Ad: $e');
      return false;
    }
  }

  Future<bool> shouldAttemptAd() async {
    final isOnline = await _networkService.checkInternet();
    if (!isOnline) return false;
    final shouldShow = await _adCooldown.shouldShowAd();
    if (!shouldShow) return false;
    return true;
  }

  void dispose() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../utilities/app_theme.dart';
import 'ad_service.dart';

/// Full-screen mandatory ad display.
///
/// Shows a single interstitial ad. The user can close it
/// once the ad has been displayed and dismissed by the SDK.
/// If the ad fails to load/show, auto-dismisses after a timeout.
class MandatoryAdScreen extends StatefulWidget {
  final AdService adService;
  const MandatoryAdScreen({super.key, required this.adService});

  @override
  State<MandatoryAdScreen> createState() => _MandatoryAdScreenState();
}

class _MandatoryAdScreenState extends State<MandatoryAdScreen> {
  bool _adStarted = false;
  bool _adDismissed = false;
  bool _showCloseButton = false;
  Timer? _timeoutTimer;
  Timer? _closeButtonTimer;

  @override
  void initState() {
    super.initState();
    widget.adService.addListener(_onAdServiceUpdate);

    // Start the ad on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_adStarted && mounted) {
        _adStarted = true;
        widget.adService.startAd();
      }
    });

    // Safety timeout: if ad doesn't load/show within 10s, show close button anyway
    _timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && !_adDismissed) {
        debugPrint('[MandatoryAd] Timeout reached, showing close button');
        setState(() => _showCloseButton = true);
      }
    });
  }

  void _onAdServiceUpdate() {
    if (!mounted) return;

    final adService = widget.adService;

    // If ad was dismissed by SDK (user tapped SDK close button), auto-pop
    if (adService.viewingPeriodComplete && !_adDismissed) {
      debugPrint('[MandatoryAd] Ad dismissed by SDK, auto-popping');
      _adDismissed = true;
      adService.dismissAd();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }

    // If ad is now showing, cancel the timeout (ad displayed successfully)
    if (adService.isShowingAd) {
      _timeoutTimer?.cancel();
    }
  }

  void _close() {
    if (_adDismissed) {
      widget.adService.dismissAd();
    }
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _closeButtonTimer?.cancel();
    widget.adService.removeListener(_onAdServiceUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Loading indicator while ad is loading
            if (!widget.adService.isShowingAd && !_adDismissed)
              const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),

            // Close button — only shown as fallback if ad failed/timed out
            if (_showCloseButton && !widget.adService.isShowingAd)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 16,
                child: GestureDetector(
                  onTap: _close,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.black87,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

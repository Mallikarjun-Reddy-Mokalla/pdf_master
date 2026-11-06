import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/ads/ad_constants.dart';

class AdService {
  static final AdService instance = AdService._internal();
  AdService._internal();

  bool _isInitialized = false;

  // Interstitial Ad
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  DateTime? _lastInterstitialShownAt;
  static const Duration _interstitialCooldown = Duration(seconds: 45);

  // App Open Ad
  AppOpenAd? _appOpenAd;
  bool _isAppOpenLoading = false;
  DateTime? _appOpenLoadTime;
  bool _isShowingAppOpenAd = false;

  // Rewarded Ad
  RewardedAd? _rewardedAd;
  bool _isRewardedLoading = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('[AdService] Google Mobile Ads SDK initialized successfully.');

      // Preload ads
      loadInterstitialAd();
      loadAppOpenAd();
      loadRewardedAd();
    } catch (e) {
      debugPrint('[AdService] Error initializing MobileAds: $e');
    }
  }

  // ==========================================
  // APP OPEN AD
  // ==========================================
  void loadAppOpenAd() {
    if (_isAppOpenLoading || isAppOpenAdAvailable) return;
    _isAppOpenLoading = true;

    AppOpenAd.load(
      adUnitId: AdConstants.appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _appOpenLoadTime = DateTime.now();
          _isAppOpenLoading = false;
          debugPrint('[AdService] AppOpenAd loaded successfully.');
        },
        onAdFailedToLoad: (error) {
          _appOpenAd = null;
          _isAppOpenLoading = false;
          debugPrint('[AdService] AppOpenAd failed to load: $error');
        },
      ),
    );
  }

  bool get isAppOpenAdAvailable {
    if (_appOpenAd == null || _appOpenLoadTime == null) return false;
    // App open ads expire after 4 hours
    return DateTime.now().difference(_appOpenLoadTime!) < const Duration(hours: 4);
  }

  void showAppOpenAdIfAvailable({VoidCallback? onComplete}) {
    if (!isAppOpenAdAvailable || _isShowingAppOpenAd) {
      loadAppOpenAd();
      onComplete?.call();
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAppOpenAd = true;
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAppOpenAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
        onComplete?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAppOpenAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
        onComplete?.call();
      },
    );

    _appOpenAd!.show();
  }

  // ==========================================
  // INTERSTITIAL AD
  // ==========================================
  void loadInterstitialAd() {
    if (_isInterstitialLoading || _interstitialAd != null) return;
    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: AdConstants.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          debugPrint('[AdService] InterstitialAd loaded successfully.');
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isInterstitialLoading = false;
          debugPrint('[AdService] InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  void showInterstitialAd({
    required VoidCallback onComplete,
    bool respectCooldown = true,
  }) {
    if (respectCooldown && _lastInterstitialShownAt != null) {
      final elapsed = DateTime.now().difference(_lastInterstitialShownAt!);
      if (elapsed < _interstitialCooldown) {
        debugPrint('[AdService] Skipping interstitial: inside cooldown period ($elapsed).');
        onComplete();
        return;
      }
    }

    if (_interstitialAd == null) {
      debugPrint('[AdService] Interstitial ad not ready, executing callback directly.');
      loadInterstitialAd();
      onComplete();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _lastInterstitialShownAt = DateTime.now();
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
        onComplete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
        onComplete();
      },
    );

    _interstitialAd!.show();
  }

  // ==========================================
  // REWARDED AD
  // ==========================================
  void loadRewardedAd() {
    if (_isRewardedLoading || _rewardedAd != null) return;
    _isRewardedLoading = true;

    RewardedAd.load(
      adUnitId: AdConstants.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoading = false;
          debugPrint('[AdService] RewardedAd loaded successfully.');
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isRewardedLoading = false;
          debugPrint('[AdService] RewardedAd failed to load: $error');
        },
      ),
    );
  }

  void showRewardedAd({
    required Function(RewardItem reward) onUserEarnedReward,
    VoidCallback? onDismissed,
  }) {
    if (_rewardedAd == null) {
      debugPrint('[AdService] RewardedAd not ready.');
      loadRewardedAd();
      onDismissed?.call();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        onDismissed?.call();
      },
    );

    _rewardedAd!.show(onUserEarnedReward: (adWithoutView, reward) {
      onUserEarnedReward(reward);
    });
  }
}


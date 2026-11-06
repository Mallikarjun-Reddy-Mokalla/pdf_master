import 'dart:io';

class AdConstants {
  AdConstants._();

  // App ID
  static const String appId = 'ca-app-pub-3205766023147752~7389546525';

  // Live Ad Unit IDs provided by user
  static const String liveBannerAdUnitId = 'ca-app-pub-3205766023147752/4188668119';
  static const String liveInterstitialAdUnitId = 'ca-app-pub-3205766023147752/3973045692';
  static const String liveRewardedAdUnitId = 'ca-app-pub-3205766023147752/5344857175';
  static const String liveAppOpenAdUnitId = 'ca-app-pub-3205766023147752/7524297957';
  static const String liveNativeAdUnitId = 'ca-app-pub-3205766023147752/3305851342';

  // Getters for release
  static String get bannerAdUnitId => liveBannerAdUnitId;
  static String get interstitialAdUnitId => liveInterstitialAdUnitId;
  static String get rewardedAdUnitId => liveRewardedAdUnitId;
  static String get appOpenAdUnitId => liveAppOpenAdUnitId;
  static String get nativeAdUnitId => liveNativeAdUnitId;
}


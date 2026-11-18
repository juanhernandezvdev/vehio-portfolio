import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

class AdService {
  static final AdService instance = AdService._internal();
  AdService._internal();

  // IDs de Producción de Unity Ads
  final String _gameId = Platform.isAndroid 
      ? '800400370' // Game ID de producción Android
      : '800400371'; // iOS ID genérico (en caso de compilación futura)
      
  final String _interstitialAdUnitId = Platform.isAndroid 
      ? 'BP_Interstitial_Android'
      : 'Interstitial_iOS';

  DateTime? _lastAdShownTime;

  // FLAG CRÍTICA: Bloquea anuncios si el usuario abre paneles de pago nativos
  static bool isBypassingAppOpenAd = false;

  Future<void> init() async {
    // Inicializar Unity Ads
    UnityAds.init(
      gameId: _gameId,
      testMode: kDebugMode, // True en desarrollo, False en producción automáticamente
      onComplete: () {
        _loadInterstitialAd();
      },
      onFailed: (error, message) {
        debugPrint('Unity Ads Initialization Failed: $error $message');
      },
    );
  }

  // --- DESTROYER PARA USUARIOS PREMIUM ---
  void destroyAds() {
    // En Unity Ads no hay un destroy global de memoria como en Meta o AdMob,
    // simplemente dejamos de llamarlos desde el provider y evitamos cargarlos.
  }

  // --- INTERSTITIAL AD ---
  void _loadInterstitialAd() {
    UnityAds.load(
      placementId: _interstitialAdUnitId,
      onComplete: (placementId) {},
      onFailed: (placementId, error, message) {
        debugPrint('Unity Ads Load Failed: $error $message');
      },
    );
  }

  void showInterstitialAd() {
    if (isBypassingAppOpenAd) return;

    // Cooldown de 3 minutos para no molestar al usuario con demasiados anuncios
    if (_lastAdShownTime != null && DateTime.now().difference(_lastAdShownTime!) < const Duration(minutes: 3)) {
      return;
    }

    UnityAds.showVideoAd(
      placementId: _interstitialAdUnitId,
      onComplete: (placementId) {
        _lastAdShownTime = DateTime.now();
        _loadInterstitialAd();
      },
      onFailed: (placementId, error, message) {
        _loadInterstitialAd();
      },
      onStart: (placementId) {},
      onClick: (placementId) {},
      onSkipped: (placementId) {
        _lastAdShownTime = DateTime.now();
        _loadInterstitialAd();
      },
    );
  }
}

// Reactor del ciclo de vida (En Unity no hay "App Open Ads" nativos como en Google, 
// por lo que usamos el Intersticial estándar al reabrir la app como reemplazo)
class AppLifecycleReactor extends WidgetsBindingObserver {
  final AdService adService;
  final bool Function() isPremiumCheck;

  AppLifecycleReactor({required this.adService, required this.isPremiumCheck});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !isPremiumCheck()) {
      adService.showInterstitialAd();
    }
  }
}
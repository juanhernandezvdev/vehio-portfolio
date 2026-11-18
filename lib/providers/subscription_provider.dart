import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/revenuecat_service.dart';
import '../services/ad_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  
  static const String _secretSalt = "Vehio_2026_x!y@z#"; // Semilla de seguridad
  
  bool _isPremium = false;
  bool _isLoading = true;
  List<Package> _packages = [];

  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;
  List<Package> get packages => _packages;

  SubscriptionProvider() {
    RevenueCatService.onCustomerInfoUpdated = _updateStateFromCustomerInfo;
    _init();
  }

  Future<void> _init() async {
    await _verifyOfflineState();
    await _fetchPackages();
    
    // Obtenemos estado inicial del servidor
    try {
      CustomerInfo info = await Purchases.getCustomerInfo();
      _updateStateFromCustomerInfo(info);
    } catch (_) {
      _isLoading = false;
      notifyListeners();
    }
  }

  // LÓGICA OFFLINE FAIL-SAFE Cifrada
  Future<void> _verifyOfflineState() async {
    try {
      String? savedStatus = await _storage.read(key: 'sub_status');
      String? savedDate = await _storage.read(key: 'sub_date');
      String? savedHash = await _storage.read(key: 'sub_hash');

      if (savedStatus == 'premium' && savedDate != null && savedHash != null) {
        // 1. Verificamos que el archivo no fue manipulado localmente
        String expectedHash = _generateHash(savedStatus!, savedDate);
        if (expectedHash == savedHash) {
          
          // 2. Verificamos la regla de 72 horas sin internet
          DateTime lastVerified = DateTime.parse(savedDate);
          if (DateTime.now().difference(lastVerified).inHours <= 72) {
            _setPremiumState(true);
            return;
          }
        }
      }
    } catch (_) {}
    _setPremiumState(false);
  }

  Future<void> _saveSecureState(bool premium) async {
    String status = premium ? 'premium' : 'free';
    String date = DateTime.now().toIso8601String();
    String hash = _generateHash(status, date);

    await _storage.write(key: 'sub_status', value: status);
    await _storage.write(key: 'sub_date', value: date);
    await _storage.write(key: 'sub_hash', value: hash);
  }

  String _generateHash(String status, String date) {
    var bytes = utf8.encode(status + date + _secretSalt);
    return sha256.convert(bytes).toString();
  }

  void _updateStateFromCustomerInfo(CustomerInfo info) {
    bool isActive = info.entitlements.all[RevenueCatService.entitlementId]?.isActive == true;
    _setPremiumState(isActive);
    _saveSecureState(isActive);
    _isLoading = false;
    notifyListeners();
  }

  void _setPremiumState(bool state) {
    _isPremium = state;
    if (_isPremium) {
      AdService.instance.destroyAds(); // Limpiamos anuncios de memoria si es premium
    } else {
      AdService.instance.showInterstitialAd(); // Lanzamos un anuncio o lo preparamos
    }
  }

  Future<void> _fetchPackages() async {
    _packages = await RevenueCatService.fetchOfferings();
    notifyListeners();
  }

  // Wrapper para compras asegurando el Bypass de Anuncios
  Future<bool> buyPackage(Package package) async {
    _isLoading = true;
    notifyListeners();
    
    AdService.isBypassingAppOpenAd = true; // Bloquea anuncios nativos
    try {
      bool success = await RevenueCatService.purchasePackage(package);
      if (success) _setPremiumState(true);
      return success;
    } finally {
      Future.delayed(const Duration(seconds: 2), () {
        AdService.isBypassingAppOpenAd = false;
      });
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> restorePurchases() async {
    _isLoading = true;
    notifyListeners();
    
    AdService.isBypassingAppOpenAd = true;
    try {
      bool success = await RevenueCatService.restorePurchases();
      if (success) _setPremiumState(true);
      return success;
    } finally {
      Future.delayed(const Duration(seconds: 2), () {
        AdService.isBypassingAppOpenAd = false;
      });
      _isLoading = false;
      notifyListeners();
    }
  }
}
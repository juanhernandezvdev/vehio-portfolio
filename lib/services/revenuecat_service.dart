import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

// Importación condicional segura de dart:io para evitar errores en Web
import 'dart:io' if (dart.library.html) 'io_stub.dart';

class RevenueCatService {
  // TODO: Reemplazar con tus llaves reales de RevenueCat
  static const String _appleApiKey = 'appl_api_key_aqui';
  static const String _googleApiKey = 'goog_UcpBYgxjTOHVmNXYYaqGqvuZhdc'; // Llave de Producción de RevenueCat
  static const String entitlementId = 'premium';

  // Callback para inyectar actualizaciones al Provider
  static void Function(CustomerInfo)? onCustomerInfoUpdated;

  /// Inicializa RevenueCat. 
  /// Controla plataformas no soportadas (como Web o Windows) para evitar [MissingPluginException].
  static Future<void> init() async {
    if (kIsWeb) {
      debugPrint('[RevenueCat] RevenueCat no está disponible en Web.');
      return;
    }

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await Purchases.setLogLevel(LogLevel.warn);

        PurchasesConfiguration? configuration;
        if (Platform.isAndroid) {
          configuration = PurchasesConfiguration(_googleApiKey);
        } else if (Platform.isIOS) {
          configuration = PurchasesConfiguration(_appleApiKey);
        }

        if (configuration != null) {
          await Purchases.configure(configuration);
          
          Purchases.addCustomerInfoUpdateListener((customerInfo) {
            if (onCustomerInfoUpdated != null) {
              onCustomerInfoUpdated!(customerInfo);
            }
          });
        }
      }
    } catch (e, stackTrace) {
      // Captura y previene que el MissingPluginException tire la aplicación
      debugPrint('[ERR_REVENUECAT_INIT] Error al inicializar RevenueCat: $e');
    }
  }

  static Future<void> login(String uid) async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await Purchases.logIn(uid);
      }
    } catch (e) {
      // Ignorar fallo de red
    }
  }

  static Future<void> logout() async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await Purchases.logOut();
      }
    } catch (e) {}
  }

  static Future<List<Package>> fetchOfferings() async {
    if (kIsWeb) return [];
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        Offerings offerings = await Purchases.getOfferings();
        if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) {
          return offerings.current!.availablePackages;
        }
      }
    } on PlatformException catch (_) {}
    return [];
  }

  static Future<bool> purchasePackage(Package package) async {
    if (kIsWeb) return false;
    try {
      final result = await Purchases.purchasePackage(package);
      return result.customerInfo.entitlements.all[entitlementId]?.isActive == true;
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        throw Exception(e.message ?? 'Error desconocido de facturación');
      }
      return false;
    }
  }

  static Future<bool> restorePurchases() async {
    if (kIsWeb) return false;
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all[entitlementId]?.isActive == true;
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Fallo al restaurar compras');
    }
  }
}

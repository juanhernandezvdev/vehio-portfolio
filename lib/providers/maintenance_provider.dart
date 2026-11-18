import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../models/maintenance_model.dart';

/// [MaintenanceProvider]
/// -----------------------------------------------------------------------------
/// PROPÓSITO: Administra el estado global de los mantenimientos vehiculares,
/// cálculos de salud del vehículo y operaciones CRUD con persistencia local (Hive).
/// 
/// SECCIÓN DE CAMBIOS:
/// - Modifica aquí si necesitas agregar nuevas reglas de cálculo de desgaste o 
///   conectar sincronización con Firestore.
/// 
/// CONTROL DE ERRORES:
/// - Cada operación de almacenamiento incluye códigos de error estructurados 
///   ([ERR_MAINT_...]) para trazabilidad en consola y Firebase Crashlytics.
/// -----------------------------------------------------------------------------
class MaintenanceProvider extends ChangeNotifier {
  final String _boxName = 'maintenances_box';
  List<Maintenance> _maintenances = [];
  
  // Almacena el último código o mensaje de error para depuración en UI
  String? _lastError;
  String? get lastError => _lastError;

  List<Maintenance> getVehicleMaintenances(String vehicleKey) {
    return _maintenances.where((m) => m.vehicleKey == vehicleKey).toList();
  }

  double getTotalExpenses(String vehicleKey) {
    return getVehicleMaintenances(vehicleKey)
        .fold(0.0, (sum, item) => sum + item.cost);
  }

  // Algoritmo de Salud Vehicular basado en Criticidad de Repuestos
  double calculateVehicleHealth(int currentMileage, int nextGeneralService, String vehicleKey) {
    double health = 1.0;

    int generalMilesLeft = nextGeneralService - currentMileage;
    if (generalMilesLeft < 0) {
      health -= 0.30;
    } else if (generalMilesLeft < 2000) {
      health -= 0.10;
    }

    final history = getVehicleMaintenances(vehicleKey);
    
    // MEJORA DEL ALGORITMO: Solo evaluar la última refacción de cada tipo
    // Evita que 3 cambios de aceite antiguos y vencidos destruyan el % de salud
    Map<String, Maintenance> latestMaintenances = {};
    for (var m in history) {
      final titleLower = m.title.trim().toLowerCase();
      if (!latestMaintenances.containsKey(titleLower) || m.mileageAtService > latestMaintenances[titleLower]!.mileageAtService) {
        latestMaintenances[titleLower] = m;
      }
    }

    for (var item in latestMaintenances.values) {
      // Los elementos estéticos no influyen en la salud mecánica del vehículo
      if (item.category == 'Estética') continue;

      if (item.nextReviewMileage != null) {
        int itemMilesLeft = item.nextReviewMileage! - currentMileage;

        if (itemMilesLeft <= 0) {
          String titleLower = item.title.toLowerCase();

          if (titleLower.contains('aceite') ||
              titleLower.contains('freno') ||
              titleLower.contains('pastilla') ||
              titleLower.contains('correa') ||
              titleLower.contains('caucho') ||
              titleLower.contains('neumatico') ||
              titleLower.contains('tiempo')) {
            health -= 0.35;
          } else if (titleLower.contains('bateria') ||
              titleLower.contains('batería') ||
              titleLower.contains('bujia') ||
              titleLower.contains('bobina') ||
              titleLower.contains('amortiguador') ||
              titleLower.contains('bomba')) {
            health -= 0.20;
          } else {
            health -= 0.08;
          }
        } else if (itemMilesLeft < 1000) {
          health -= 0.05;
        }
      }
    }

    return health.clamp(0.0, 1.0);
  }

  /// Carga los mantenimientos desde la base de datos local Hive.
  /// Código de error asociado: [ERR_MAINT_LOAD]
  Future<void> loadMaintenances() async {
    try {
      var box = Hive.box<Maintenance>(_boxName);
      _maintenances = box.values.toList();
      _maintenances.sort((a, b) => b.date.compareTo(a.date));
      _lastError = null;
      notifyListeners();
    } catch (e, stackTrace) {
      _lastError = "[ERR_MAINT_LOAD] Error al cargar mantenimientos: $e";
      debugPrint(_lastError);
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Fallo en loadMaintenances');
      notifyListeners();
    }
  }

  /// Agrega un nuevo registro de mantenimiento.
  /// Código de error asociado: [ERR_MAINT_ADD]
  Future<void> addMaintenance(Maintenance maintenance) async {
    try {
      var box = Hive.box<Maintenance>(_boxName);
      await box.add(maintenance);
      await loadMaintenances();
    } catch (e, stackTrace) {
      _lastError = "[ERR_MAINT_ADD] Error al guardar mantenimiento: $e";
      debugPrint(_lastError);
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Fallo en addMaintenance');
      throw Exception(_lastError);
    }
  }

  /// Edita un mantenimiento existente.
  /// Código de error asociado: [ERR_MAINT_EDIT]
  Future<void> editMaintenance(int index, Maintenance updatedMaintenance) async {
    try {
      var box = Hive.box<Maintenance>(_boxName);
      await box.putAt(index, updatedMaintenance);
      await loadMaintenances();
    } catch (e, stackTrace) {
      _lastError = "[ERR_MAINT_EDIT] Error al actualizar mantenimiento en índice $index: $e";
      debugPrint(_lastError);
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Fallo en editMaintenance');
      throw Exception(_lastError);
    }
  }

  /// Elimina un registro de mantenimiento.
  /// Código de error asociado: [ERR_MAINT_DEL]
  Future<void> deleteMaintenance(int index) async {
    try {
      var box = Hive.box<Maintenance>(_boxName);
      await box.deleteAt(index);
      await loadMaintenances();
    } catch (e, stackTrace) {
      _lastError = "[ERR_MAINT_DEL] Error al eliminar mantenimiento en índice $index: $e";
      debugPrint(_lastError);
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Fallo en deleteMaintenance');
      throw Exception(_lastError);
    }
  }
}

import 'package:hive_flutter/hive_flutter.dart';
// Importa aquí tus modelos (Vehicle, Maintenance, etc.)

class LocalStorageService {
  static Future<void> init() async {
    // Inicializa Hive optimizado para Flutter (gestiona las rutas de directorios locales de forma segura)
    await Hive.initFlutter();

    // Registrar los adaptadores generados (asegúrate de tenerlos generados con build_runner)
    // Hive.registerAdapter(VehicleAdapter());
    // Hive.registerAdapter(MaintenanceAdapter());

    // Abrir las cajas en paralelo para reducir el tiempo de carga a la mitad
    await Future.wait([
      Hive.openBox('vehicles_box'),
      Hive.openBox('maintenances_box'),
      Hive.openBox('fuel_box'),
      Hive.openBox('documents_box'),
    ]);
  }
}
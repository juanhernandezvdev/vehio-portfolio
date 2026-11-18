import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/vehicle_model.dart';
import '../models/maintenance_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    
    await _plugin.initialize(initSettings);

    // Solicitar permisos en Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> processAlerts(List<Vehicle> vehicles, List<Maintenance> maintenances) async {
    // Cancelamos las alertas programadas previas para no duplicar
    await _plugin.cancelAll();

    bool hasExpired = false;
    bool hasExpiringSoon = false;
    
    List<String> expiredItems = [];
    List<String> expiringSoonItems = [];

    // 1. Evaluar Salud Global de Vehículos
    for (var v in vehicles) {
      int milesLeft = v.nextServiceMileage - v.mileage;
      if (milesLeft <= 0) {
        hasExpired = true;
        expiredItems.add('${v.brand} ${v.model}');
      } else if (milesLeft <= 500) {
        hasExpiringSoon = true;
        expiringSoonItems.add('${v.brand} ${v.model}');
      }
    }

    // 2. Evaluar Mantenimientos/Repuestos (Solo evaluamos el más reciente de cada tipo)
    Map<String, Maintenance> latestMaint = {};
    for (var m in maintenances) {
      String key = '${m.vehicleKey}_${m.title}';
      if (!latestMaint.containsKey(key) || m.date.isAfter(latestMaint[key]!.date)) {
        latestMaint[key] = m;
      }
    }

    for (var m in latestMaint.values) {
      if (m.nextReviewMileage != null) {
        var vehicle = vehicles.where((v) => '${v.brand}_${v.model}_${v.year}' == m.vehicleKey).firstOrNull;
        if (vehicle != null) {
          int milesLeft = m.nextReviewMileage! - vehicle.mileage;
          if (milesLeft <= 0) {
            hasExpired = true;
            expiredItems.add('${m.title} (${vehicle.brand})');
          } else if (milesLeft <= 500) {
            hasExpiringSoon = true;
            expiringSoonItems.add('${m.title} (${vehicle.brand})');
          }
        }
      }
    }

    // --- DISPARAR ALERTAS ---

    // A) Recordatorio DIARIO si hay algo Vencido/Crítico
    if (hasExpired) {
      String details = expiredItems.join(', ');
      await _plugin.periodicallyShow(
        0,
        '🚨 Vehio: ¡Atención Urgente!',
        'Tienes ${expiredItems.length} elemento(s) vencido(s). Toca para ver detalles.',
        RepeatInterval.daily,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'vehio_critical_alerts',
            'Alertas Críticas',
            channelDescription: 'Recordatorios diarios de servicios vencidos',
            importance: Importance.max,
            priority: Priority.high,
            color: Color(0xFFE50914),
          ),
        ),
      );
    }

    // B) Advertencia ÚNICA para lo que está a punto de expirar
    if (hasExpiringSoon) {
      String details = expiringSoonItems.join(', ');
      await _plugin.show(
        1,
        '⚠️ Vehio: Servicio Próximo',
        'Tienes ${expiringSoonItems.length} servicio(s) por vencer (menos de 500 km).',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'vehio_warning_alerts',
            'Advertencias Próximas',
            channelDescription: 'Avisos de servicios a punto de vencer',
            importance: Importance.high,
            priority: Priority.high,
            color: Colors.orange,
          ),
        ),
      );
    }
  }
}

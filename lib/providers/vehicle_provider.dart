import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/vehicle_model.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class VehicleProvider extends ChangeNotifier {
  final String _boxName = 'vehicles_box';
  List<Vehicle> _vehicles = [];

  List<Vehicle> get vehicles => _vehicles;

  // Cargar los vehículos al iniciar (Cifrado con Secure Storage)
  Future<void> loadVehicles() async {
    const secureStorage = FlutterSecureStorage();

    // 1. Buscamos si ya existe una llave criptográfica guardada
    String? encryptionKeyString = await secureStorage.read(key: 'hive_key');

    // 2. Si no existe, generamos una llave AES de 256 bits y la guardamos segura
    if (encryptionKeyString == null) {
      final key = Hive.generateSecureKey();
      await secureStorage.write(key: 'hive_key', value: base64UrlEncode(key));
      encryptionKeyString = await secureStorage.read(key: 'hive_key');
    }

    // 3. Decodificamos la llave y abrimos la caja blindada de Hive
    final encryptionKeyUint8List = base64Url.decode(encryptionKeyString!);

    var box = await Hive.openBox<Vehicle>(
      _boxName,
      encryptionCipher: HiveAesCipher(encryptionKeyUint8List),
    );

    _vehicles = box.values.toList();
    notifyListeners();
  }

  // Agregar un vehículo nuevo (Local + Sincronización en la Nube con Firestore)
  Future<void> addVehicle(Vehicle vehicle) async {
    var box = Hive.box<Vehicle>(_boxName);

    // 1. Guardar localmente en Hive
    await box.add(vehicle);
    _vehicles = box.values.toList();
    notifyListeners();

    // 2. Sincronizar en Firestore de forma segura bajo el usuario autenticado
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Usamos el id del vehículo o generamos uno basado en la clave de Hive si fuese nulo
        final vehicleId = (vehicle.id != null && vehicle.id!.isNotEmpty)
            ? vehicle.id!
            : box.keyAt(box.length - 1).toString(); // <--- Corregido el signo menos (-) aquí

        // Lanzamos la escritura en la nube en segundo plano sin bloquear (Fire and forget)
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('vehicles')
            .doc(vehicleId)
            .set(vehicle.toMap())
            .catchError((e) => debugPrint("Error al sincronizar el vehículo: \$e"));
      }
    } catch (e) {
      debugPrint("Error al sincronizar el vehículo en la nube: $e");
      // No interrumpimos la experiencia local si falla la red, pero queda registrado
    }
  }

  // Eliminar un vehículo (Local y opcionalmente en Firestore)
  Future<void> deleteVehicle(int index) async {
    var box = Hive.box<Vehicle>(_boxName);

    // Opcional: Obtener el vehículo antes de borrarlo para extraer su ID y eliminarlo también de Firestore
    final vehicle = box.getAt(index);

    await box.deleteAt(index);
    _vehicles = box.values.toList();
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && vehicle != null && vehicle.id != null) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('vehicles')
            .doc(vehicle.id!)
            .delete()
            .catchError((e) => debugPrint("Error al eliminar el vehículo de la nube: \$e"));
      }
    } catch (e) {
      debugPrint("Error al eliminar el vehículo de la nube: $e");
    }
  }
}
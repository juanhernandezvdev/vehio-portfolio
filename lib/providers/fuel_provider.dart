import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/fuel_model.dart';

class FuelProvider extends ChangeNotifier {
  final String _boxName = 'fuel_box';
  List<FuelLog> _fuelLogs = [];

  List<FuelLog> getVehicleFuelLogs(String vehicleKey) {
    return _fuelLogs.where((f) => f.vehicleKey == vehicleKey).toList();
  }

  double getTotalFuelCost(String vehicleKey) {
    return getVehicleFuelLogs(vehicleKey).fold(0.0, (sum, item) => sum + item.totalCost);
  }

  Future<void> loadFuelLogs() async {
    var box = Hive.box<FuelLog>(_boxName);
    _fuelLogs = box.values.toList();
    _fuelLogs.sort((a, b) => b.date.compareTo(a.date)); // Más reciente primero
    notifyListeners();
  }

  Future<void> addFuelLog(FuelLog log) async {
    var box = Hive.box<FuelLog>(_boxName);
    await box.add(log);
    await loadFuelLogs();
  }

  Future<void> deleteFuelLog(int index) async {
    var box = Hive.box<FuelLog>(_boxName);
    await box.deleteAt(index);
    await loadFuelLogs();
  }
}
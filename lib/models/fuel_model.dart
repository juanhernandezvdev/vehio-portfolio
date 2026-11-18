import 'package:hive/hive.dart';

part 'fuel_model.g.dart';

@HiveType(typeId: 2) // ID 2 porque Vehículo es 0 y Mantenimiento es 1
class FuelLog extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  double liters;

  @HiveField(2)
  double totalCost;

  @HiveField(3)
  int currentMileage;

  @HiveField(4)
  String vehicleKey;

  FuelLog({
    required this.date,
    required this.liters,
    required this.totalCost,
    required this.currentMileage,
    required this.vehicleKey,
  });
}
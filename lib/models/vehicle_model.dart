import 'package:hive/hive.dart';

part 'vehicle_model.g.dart';

@HiveType(typeId: 0)
class Vehicle extends HiveObject {
  @HiveField(0)
  String brand;

  @HiveField(1)
  String model;

  @HiveField(2)
  int year;

  @HiveField(3)
  int mileage;

  @HiveField(4)
  String distanceUnit; // "km" o "mi"

  @HiveField(5)
  int nextServiceMileage; // Kilometraje para la próxima alerta de servicio

  @HiveField(6)
  String vehicleType; // "Auto" o "Moto"

  // --- NUEVO CAMPO OPCIONAL PARA FIRESTORE ---
  @HiveField(7)
  String? id;

  Vehicle({
    String? id,
    required this.brand,
    required this.model,
    required this.year,
    required this.mileage,
    this.distanceUnit = 'km',
    this.nextServiceMileage = 5000,
    this.vehicleType = 'Auto',
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  // Método toMap para sincronizar con Cloud Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'brand': brand,
      'model': model,
      'year': year,
      'mileage': mileage,
      'distanceUnit': distanceUnit,
      'nextServiceMileage': nextServiceMileage,
      'vehicleType': vehicleType,
    };
  }
}
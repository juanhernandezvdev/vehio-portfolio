import 'package:hive/hive.dart';

part 'maintenance_model.g.dart';

@HiveType(typeId: 1)
class Maintenance extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  double cost;

  @HiveField(3)
  int mileageAtService;

  @HiveField(4)
  String vehicleKey;

  @HiveField(5)
  String category; // Ej: "Mecánica", "Electrónica", "Llantas", "Estética"

  @HiveField(6)
  int? nextReviewMileage; // Kilometraje límite de la pieza (vida útil)

  @HiveField(7)
  String? description; // Comentarios o descripción detallada del servicio

  Maintenance({
    required this.title,
    required this.date,
    required this.cost,
    required this.mileageAtService,
    required this.vehicleKey,
    this.category = 'Mecánica', // Valor por defecto
    this.nextReviewMileage,
    this.description,
  });
}
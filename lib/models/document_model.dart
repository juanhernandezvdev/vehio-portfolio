import 'package:hive/hive.dart';

part 'document_model.g.dart';

@HiveType(typeId: 3)
class VehicleDocument extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String filePath;

  @HiveField(2)
  String vehicleKey;

  VehicleDocument({
    required this.title,
    required this.filePath,
    required this.vehicleKey,
  });
}
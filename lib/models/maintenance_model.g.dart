// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MaintenanceAdapter extends TypeAdapter<Maintenance> {
  @override
  final int typeId = 1;

  @override
  Maintenance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Maintenance(
      title: fields[0] as String,
      date: fields[1] as DateTime,
      cost: fields[2] as double,
      mileageAtService: fields[3] as int,
      vehicleKey: fields[4] as String,
      category: fields[5] as String,
      nextReviewMileage: fields[6] as int?,
      description: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Maintenance obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.cost)
      ..writeByte(3)
      ..write(obj.mileageAtService)
      ..writeByte(4)
      ..write(obj.vehicleKey)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.nextReviewMileage)
      ..writeByte(7)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaintenanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

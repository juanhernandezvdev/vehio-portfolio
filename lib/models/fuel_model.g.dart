// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fuel_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FuelLogAdapter extends TypeAdapter<FuelLog> {
  @override
  final int typeId = 2;

  @override
  FuelLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FuelLog(
      date: fields[0] as DateTime,
      liters: fields[1] as double,
      totalCost: fields[2] as double,
      currentMileage: fields[3] as int,
      vehicleKey: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FuelLog obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.liters)
      ..writeByte(2)
      ..write(obj.totalCost)
      ..writeByte(3)
      ..write(obj.currentMileage)
      ..writeByte(4)
      ..write(obj.vehicleKey);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FuelLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

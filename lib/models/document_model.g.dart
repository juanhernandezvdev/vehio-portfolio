// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VehicleDocumentAdapter extends TypeAdapter<VehicleDocument> {
  @override
  final int typeId = 3;

  @override
  VehicleDocument read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VehicleDocument(
      title: fields[0] as String,
      filePath: fields[1] as String,
      vehicleKey: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, VehicleDocument obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.filePath)
      ..writeByte(2)
      ..write(obj.vehicleKey);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VehicleDocumentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

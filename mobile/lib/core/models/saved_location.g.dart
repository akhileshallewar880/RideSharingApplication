// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_location.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavedLocationAdapter extends TypeAdapter<SavedLocation> {
  @override
  final int typeId = 10;

  @override
  SavedLocation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedLocation(
      id: fields[0] as String,
      name: fields[1] as String,
      address: fields[2] as String,
      latitude: fields[3] as double,
      longitude: fields[4] as double,
      type: fields[5] as SavedLocationType,
      createdAt: fields[6] as DateTime,
      lastUsedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SavedLocation obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.address)
      ..writeByte(3)
      ..write(obj.latitude)
      ..writeByte(4)
      ..write(obj.longitude)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.lastUsedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedLocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SavedLocationTypeAdapterAdapter
    extends TypeAdapter<SavedLocationTypeAdapter> {
  @override
  final int typeId = 11;

  @override
  SavedLocationTypeAdapter read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SavedLocationTypeAdapter.home;
      case 1:
        return SavedLocationTypeAdapter.work;
      case 2:
        return SavedLocationTypeAdapter.favorite;
      default:
        return SavedLocationTypeAdapter.home;
    }
  }

  @override
  void write(BinaryWriter writer, SavedLocationTypeAdapter obj) {
    switch (obj) {
      case SavedLocationTypeAdapter.home:
        writer.writeByte(0);
        break;
      case SavedLocationTypeAdapter.work:
        writer.writeByte(1);
        break;
      case SavedLocationTypeAdapter.favorite:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedLocationTypeAdapterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

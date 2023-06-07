// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DataAdapter extends TypeAdapter<Data> {
  @override
  final int typeId = 1;

  @override
  Data read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Data(
      first: fields[0] as DateTime,
      second: fields[1] as double,
      note: fields[2] == null ? '' : fields[2] as String,
      uid: fields[3] == null ? '' : fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Data obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.first)
      ..writeByte(1)
      ..write(obj.second)
      ..writeByte(2)
      ..write(obj.note)
      ..writeByte(3)
      ..write(obj.uid);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DataContainerAdapter extends TypeAdapter<DataContainer> {
  @override
  final int typeId = 2;

  @override
  DataContainer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DataContainer(
      name: fields[1] as String,
      note: fields[2] as String,
      color: fields[3] as Color,
      isDateOnly: fields[4] == null ? true : fields[4] as bool,
    )
      ..data = (fields[0] as List).cast<Data>()
      ..isFavourite = fields[5] == null ? false : fields[5] as bool;
  }

  @override
  void write(BinaryWriter writer, DataContainer obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.data)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.note)
      ..writeByte(3)
      ..write(obj.color)
      ..writeByte(4)
      ..write(obj.isDateOnly)
      ..writeByte(5)
      ..write(obj.isFavourite);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataContainerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

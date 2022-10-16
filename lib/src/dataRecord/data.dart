import 'package:hive/hive.dart';
import 'dart:ui';

part 'data.g.dart';

class ColorAdapter extends TypeAdapter<Color> {
  @override
  Color read(BinaryReader reader) => Color(reader.readInt());

  @override
  void write(BinaryWriter writer, Color obj) => writer.writeInt(obj.value);

  @override
  int get typeId => 200;
}

@HiveType(typeId: 1)
class Data extends HiveObject {
  Data({required this.first, required this.second});

  @HiveField(0)
  DateTime first = DateTime.now();

  @HiveField(1)
  double second = .0;
}

class DataDialogReturn {
  String category;
  Data data;
  bool delete = false;
  DataDialogReturn(
      {required this.category, required this.data, this.delete = false});
}

@HiveType(typeId: 2)
class DataContainer {
  DataContainer({required this.name, required this.note, required this.color});

  @HiveField(0)
  List<Data> data = [];

  @HiveField(1)
  String name;

  @HiveField(2)
  String note;

  @HiveField(3)
  Color color;
}

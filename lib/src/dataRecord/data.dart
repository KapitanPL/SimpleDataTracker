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
  Data({required this.first, required this.second, this.note = ""});

  @HiveField(0)
  DateTime first = DateTime.now();

  @HiveField(1)
  double second = .0;

  @HiveField(2, defaultValue: "")
  String note;
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
  DataContainer(
      {required this.name,
      required this.note,
      required this.color,
      this.isDateOnly = true,
      this.isFavourite = false});

  @HiveField(0)
  List<Data> data = [];

  @HiveField(1)
  String name;

  @HiveField(2)
  String note;

  @HiveField(3)
  Color color;

  @HiveField(4, defaultValue: true)
  bool isDateOnly;

  @HiveField(5, defaultValue: false)
  bool isFavourite;
}

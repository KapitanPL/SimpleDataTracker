import 'dart:ui';

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

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
  Data(
      {required this.first,
      required this.second,
      this.note = "",
      this.uid = ""}) {
    if (uid.isEmpty) {
      var uuid = const Uuid();
      uid = uuid.v4();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "dateTime": first.millisecondsSinceEpoch,
      "value": second,
      "note": note
    };
  }

  @HiveField(0)
  DateTime first = DateTime.now();

  @HiveField(1)
  double second = .0;

  @HiveField(2, defaultValue: "")
  String note;

  @HiveField(3, defaultValue: "")
  String uid;
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
  late String name;

  @HiveField(2)
  late String note;

  @HiveField(3)
  late Color color;

  @HiveField(4, defaultValue: true)
  late bool isDateOnly;

  @HiveField(5, defaultValue: false)
  late bool isFavourite;

  Map<String, dynamic> toJson() {
    List<String> dataUids = [];
    for (var d in data) {
      dataUids.add(d.uid);
    }
    return {
      "name": name,
      "note": note,
      "color": color.value,
      "isDateOnly": isDateOnly,
      "isFavourite": isFavourite,
      "dataUids": dataUids,
    };
  }
}

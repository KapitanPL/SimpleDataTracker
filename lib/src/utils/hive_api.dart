import 'package:datatracker/main.dart';

import 'package:hive/hive.dart';

import 'package:datatracker/src/dataRecord/data.dart';

class HiveDatabaseApi {
  DataTrackerState datatracker;

  HiveDatabaseApi({required this.datatracker});

  Future<Map<String, DataContainer>> loadData() async {
    var box = await Hive.openBox('dataBox');
    Map<String, DataContainer> loadedData = {};
    for (var key in box.keys) {
      if (key is String) {
        var data = box.get(key);
        if (data is DataContainer) {
          loadedData[key] = box.get(key);
        }
      }
    }
    return loadedData;
  }

  Future<void> saveData({String? key}) async {
    var box = await Hive.openBox('dataBox');
    if (key == null) {
      box.clear();
      for (var key in datatracker.data.keys) {
        box.put(key, datatracker.data[key]);
      }
    } else {
      box.put(key, datatracker.data[key]);
    }
  }
}

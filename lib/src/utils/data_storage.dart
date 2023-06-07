import 'firebase_api.dart';
import 'hive_api.dart';

import 'package:datatracker/main.dart';
import 'package:datatracker/src/dataRecord/data.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class DataStorage {
  FirebaseApp firebaseApp;

  User? loggedInUser;

  DataTrackerState datatracker;

  late FirebaseDatabaseApi? _firebase;

  late HiveDatabaseApi? _hive;

  DataStorage(
      {required this.loggedInUser,
      required this.firebaseApp,
      required this.datatracker}) {
    if (loggedInUser == null) {
      _hive = HiveDatabaseApi(datatracker: datatracker);
      _firebase = null;
    } else {
      _hive = null;
      _firebase = FirebaseDatabaseApi(
          datatracker: datatracker,
          firebaseApp: firebaseApp,
          uid: loggedInUser!.uid);
    }
  }

  bool runsLocally() {
    return _hive != null;
  }

  bool runsInCloud() {
    return _firebase != null;
  }

  void saveData(String key, int index) {
    if (_firebase != null) {
      if (key.isEmpty) {
        // save all
        for (var k in datatracker.data.keys) {
          _firebase!.saveFirebaseKey(k);
          for (var i = 0; i < datatracker.data[k]!.data.length; ++i) {
            _firebase!.saveFirebaseDataValue(k, i);
          }
        }
      } else {
        if (index < 0) {
          _firebase!.saveFirebaseKey(key);
          for (var i = 0; i < datatracker.data[key]!.data.length; ++i) {
            _firebase!.saveFirebaseDataValue(key, i);
          }
        } else {
          _firebase!.saveFirebaseDataValue(key, index);
        }
      }
    } else {
      _hive!.saveData(key: key);
    }
  }

  void deleteData(String key, int index) {
    if (_firebase != null) {
      if (index < 0) {
        for (var i = 0; i < datatracker.data[key]!.data.length; ++i) {
          _firebase!
              .deleteFirebaseDataValue(key, datatracker.data[key]!.data[i].uid);
        }
        _firebase!.deleteFirebaseKey(key);
      } else {
        _firebase!.deleteFirebaseDataValue(
            key, datatracker.data[key]!.data[index].uid);
      }
    } else {
      _hive!.saveData();
    }
  }

  Future<Map<String, DataContainer>> loadData() async {
    if (_firebase != null) {
      return _firebase!.loadDataFromFirebase();
    } else {
      return _hive!.loadData();
    }
  }
}

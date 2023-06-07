import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:datatracker/src/dataRecord/data.dart';
import 'package:datatracker/main.dart';

extension TypeConvertor on Object {
  double toDouble([double defaultValue = double.nan]) {
    if (this is double) {
      return this as double;
    }
    if (this is int) {
      return (this as int).toDouble();
    }
    if (this is String) {
      return (this as String).toDouble(defaultValue);
    }
    return defaultValue;
  }
}

class FirebaseDatabaseApi {
  FirebaseApp firebaseApp;

  String uid;

  DataTrackerState datatracker;

  FirebaseDatabaseApi(
      {required this.firebaseApp,
      required this.uid,
      required this.datatracker}) {
    FirebaseDatabase.instanceFor(
            app: firebaseApp,
            databaseURL:
                'https://simpledatatracker-8f954-default-rtdb.europe-west1.firebasedatabase.app')
        .setPersistenceEnabled(true);
  }

  Future<Map<String, DataContainer>> loadDataFromFirebase() async {
    Map<String, DataContainer> loadedData = {};
    var keys = await loadFirebaseKeys();
    for (var key in keys) {
      var data = await loadFirebaseKey(key);
      if (data != null) {
        loadedData[key] = data;
      }
    }
    return loadedData;
  }

  void saveFirebaseDataValue(String key, int index) {
    String uidVal = datatracker.data[key]!.data[index].uid;
    var dataRef = FirebaseDatabase.instanceFor(
            app: firebaseApp,
            databaseURL:
                'https://simpledatatracker-8f954-default-rtdb.europe-west1.firebasedatabase.app')
        .ref("$uid/$key/$uidVal");
    var json = datatracker.data[key]!.data[index].toJson();
    json["uid"] = uidVal;
    dataRef.update(json);
  }

  void deleteFirebaseDataValue(String key, String uidVal) {
    FirebaseDatabase.instanceFor(
            app: firebaseApp,
            databaseURL:
                'https://simpledatatracker-8f954-default-rtdb.europe-west1.firebasedatabase.app')
        .ref("$uid/$key/$uidVal")
        .remove();
  }

  void saveFirebaseKey(String key) {
    var keyRef = FirebaseDatabase.instanceFor(
            app: firebaseApp,
            databaseURL:
                'https://simpledatatracker-8f954-default-rtdb.europe-west1.firebasedatabase.app')
        .ref("$uid/$key");
    keyRef.update(datatracker.data[key]!.toJson());
    updateFirebaseKeys();
  }

  Future<DataContainer?> loadFirebaseKey(String key) async {
    var keysSnapshot = await FirebaseDatabase.instanceFor(
            app: firebaseApp,
            databaseURL:
                'https://simpledatatracker-8f954-default-rtdb.europe-west1.firebasedatabase.app')
        .ref("$uid/$key")
        .get();
    if (keysSnapshot.exists) {
      var name = keysSnapshot.child("name").value as String;
      var note = keysSnapshot.child("note").value as String;
      var color = Color(keysSnapshot.child("color").value as int);
      var isDateOnly = keysSnapshot.child("isDateOnly").value as bool;
      var isFavourite = keysSnapshot.child("isFavourite").value as bool;
      List<String> uids = [];
      if (keysSnapshot.hasChild("dataUids")) {
        uids = (keysSnapshot.child("dataUids").value as List)
            .map((e) => e as String)
            .toList();
      }

      DataContainer dataContainer = DataContainer(
          name: name,
          note: note,
          color: color,
          isDateOnly: isDateOnly,
          isFavourite: isFavourite);

      for (var uidVal in uids) {
        var dataSnapshot = await FirebaseDatabase.instanceFor(
                app: firebaseApp,
                databaseURL:
                    'https://simpledatatracker-8f954-default-rtdb.europe-west1.firebasedatabase.app')
            .ref("$uid/$key/$uidVal")
            .get();
        if (dataSnapshot.exists) {
          var datetime = DateTime.fromMillisecondsSinceEpoch(
              dataSnapshot.child("dateTime").value as int);
          var value = dataSnapshot.child("value").value!.toDouble();
          var note = dataSnapshot.child("note").value as String;

          dataContainer.data.add(
              Data(first: datetime, second: value, note: note, uid: uidVal));
        }
      }

      return dataContainer;
    }
    return null;
  }

  void deleteFirebaseKey(String key) {
    FirebaseDatabase.instanceFor(
            app: firebaseApp,
            databaseURL:
                'https://simpledatatracker-8f954-default-rtdb.europe-west1.firebasedatabase.app')
        .ref("$uid/$key")
        .remove();
    updateFirebaseKeys();
  }

  void updateFirebaseKeys() {
    var keysRef = FirebaseDatabase.instanceFor(
            app: firebaseApp,
            databaseURL:
                'https://simpledatatracker-8f954-default-rtdb.europe-west1.firebasedatabase.app')
        .ref("$uid/keys");
    keysRef.update({"keys": datatracker.data.keys.toList(growable: false)});
  }

  Future<List<String>> loadFirebaseKeys() async {
    List<String> keys = [];
    var keysSnapshot = await FirebaseDatabase.instanceFor(
            app: firebaseApp,
            databaseURL:
                'https://simpledatatracker-8f954-default-rtdb.europe-west1.firebasedatabase.app')
        .ref("$uid/keys")
        .get();
    if (keysSnapshot.exists) {
      keys = (keysSnapshot.child("keys").value as List)
          .map((item) => item as String)
          .toList();
    }
    return keys;
  }
}

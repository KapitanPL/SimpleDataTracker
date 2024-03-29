import 'dart:math';

import 'package:datatracker/src/dialogs/sing_in_dialog.dart';
import 'package:datatracker/src/utils/authentication.dart';
import 'package:datatracker/src/utils/firebase_api.dart';
import 'package:datatracker/src/utils/data_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:collection/collection.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:social_share/social_share.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'src/dataRecord/data.dart';
import 'src/widgets/key_button.dart';

import 'src/dialogs/data_input_dialog.dart';
import 'src/dialogs/edit_series.dart';
import 'src/dialogs/frea_app_waring.dart';
import 'src/dialogs/yes_no_question.dart';

typedef CallbackFunction = void Function();

const bool isFree = false;

const String hiveKeyselectedItem = "selectedItem";
const String hiveKeySplitterWeights = "splitterWeights";

const String hiveKeyxMin = "xMin";
const String hiveKeyxMax = "xMax";
const String hiveKeyyMin = "yMin";
const String hiveKeyyMax = "yMax";

const String hiveKeyLastShare = "lastShare";
const String hiveKeyControlsSide = "controlsSide";

const String hiveKeyAskForLogin = "askForLogin";

const int databaseAll = -1;

late FirebaseApp firebaseApp;

List<String> getVersionNotes() {
  List<String> notes = [];
  notes.add("Version notes.");
  notes.add("Account login/logout synchronization should work");
  notes.add("try/catch on disconnect");
  return notes;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var directory = await getApplicationSupportDirectory(); //? Or some better
  Hive
    // ..init("data/user/0/customFolder")
    ..init(directory.path)
    ..registerAdapter(DataAdapter())
    ..registerAdapter(DataContainerAdapter())
    ..registerAdapter(ColorAdapter());
  firebaseApp = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);

  runApp(const DataTracker());
}

class DataTracker extends StatelessWidget {
  const DataTracker({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const MyHomePage(
          title: 'Flutter Demo Home Page', key: Key("DataTrackerHome")),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  const MyHomePage({super.key, required this.title});

  @override
  State<MyHomePage> createState() => DataTrackerState();
}

class DataCacheEntry {
  DataCacheEntry(this.time, this.value, this.datakey, this.note);
  DateTime time;
  double value;
  String note;
  String datakey;
}

class DataTrackerState extends State<MyHomePage> {
  Map<String, DataContainer> data = {};
  List<String> selectedKeys = [];

  Map<String, List<DataCacheEntry>> dataCache = {};
  bool reloadDataCache = false;
  bool dataLoaded = false;
  bool expandedMenu = false;

  DateTime _xMin = DateTime.now();
  DateTime _xMax = DateTime.now();
  double _yMin = .0;
  double _yMax = .0;

  bool _rightHanded = true;

  bool _settingsLoaded = false;

  bool _userLoaded = false;
  bool _askForLogin = true;
  User? _loggedInUser;

  DateTime _lastShare = DateTime.now().subtract(const Duration(days: 60));
  static const Duration _freeShareDuration = Duration(days: 30);

  final ScreenshotController _screenshotController = ScreenshotController();

  late DataStorage _database;

  List<BuildContext> signInDialogContext = [];

  DataTrackerState() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _loggedInUser = user;
      if (user == null) {
        onLogout();
      } else {
        onLogin();
      }
    });
    _loggedInUser = Authentication.loggedInUser();
    _userLoaded = true;
    loadSettings();
    _database = DataStorage(
        datatracker: this,
        loggedInUser: _loggedInUser,
        firebaseApp: firebaseApp);
    reloadDataFromDatabase();
  }

  void onLogin() {
    if (_userLoaded && _database.runsLocally()) {
      if (dataLoaded) {
        // login after using only locally.
        _database = DataStorage(
            datatracker: this,
            loggedInUser: _loggedInUser,
            firebaseApp: firebaseApp);
        if (data.isNotEmpty) {
          yesNoQuestion(
                  context, "Transfer data to cloud? (Keep what you have?)")
              .then((value) {
            if (value) {
              _database.saveData("", databaseAll);
            } else {
              data.clear();
              selectedKeys.clear();
              dataCache.clear();
              reloadDataFromDatabase();
            }
          });
        }
      }
    }
  }

  void onLogout() {
    if (_userLoaded && _database.runsInCloud()) {
      if (dataLoaded) {
        // login after using only locally.
        _database = DataStorage(
            datatracker: this,
            loggedInUser: _loggedInUser,
            firebaseApp: firebaseApp);
        if (data.isNotEmpty) {
          yesNoQuestion(context,
                  "Transfer data to this device? (Keep what you have?)")
              .then((value) {
            if (value) {
              _database.saveData("", databaseAll);
            } else {
              data.clear();
              selectedKeys.clear();
              dataCache.clear();
              reloadDataFromDatabase();
            }
          });
        }
      }
    }
  }

  void reloadDataFromDatabase() {
    _database.loadData().then(
      (value) {
        setState(() {
          data = value;
          reloadDataCache = true;
        });
      },
    ).whenComplete(() => setState(
          () {
            dataLoaded = true;
          },
        ));
  }

  @override
  @mustCallSuper
  void initState() {
    super.initState();
  }

  Future<void> _showSignInDialog() async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    _dismissSignInDialog();
    signInDialogContext.add(context);
    signInDialog(context).then((value) => _processLogin(value));
  }

  void _dismissSignInDialog() {
    if (signInDialogContext.isNotEmpty) {
      Navigator.pop(signInDialogContext.first);
      signInDialogContext.removeAt(0);
    }
  }

  void _showAboutDialog() {
    PackageInfo.fromPlatform().then((value) {
      String info = "Info: \n";
      info += "Version ${value.version}\n";
      var versionNotes = getVersionNotes();
      if (versionNotes.isNotEmpty) {
        info += " \n";
        info += "Notes: \n";
        for (var note in versionNotes) {
          info += "$note\n";
        }
      }
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Simple Data Tracker'),
              content: Text(info),
              actions: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true)
                        .pop(); // dismisses only the dialog and returns false
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          });
    });
  }

  void _processLogin(User? newUser) {
    if (_loggedInUser == null && newUser == null) {
      print("ask for login: false");
      _askForLogin = false;
      saveSettings(hiveKeyAskForLogin, _askForLogin);
    }
    _loggedInUser = newUser;
  }

  void updateChartRangesUponPointChange(DateTime date, double value) {
    if (date.isAfter(_xMax)) {
      _xMax = date;
    }
    if (date.isBefore(_xMin)) {
      _xMin = date;
    }
    if (value > _yMax) {
      _yMax = value;
    }
    if (value < _yMin) {
      _yMin = value;
    }
    saveZoom();
  }

  void _addNewRecord() {
    if (data.keys.isEmpty) {
      return;
    }
    showDataInputDialog(context, data, selectedKeys).then((value) {
      if (value != null) {
        assert(data.keys.contains(value.category));
        var dataKey = value.category;
        setState(() {
          if (data[dataKey]!.data.isEmpty ||
              value.data.first.isAfter(data[dataKey]!.data.last.first)) {
            data[dataKey]!.data.add(value.data);
          } else {
            data[dataKey]!.data.insert(
                data[dataKey]!.data.indexWhere((element) {
                  return element.first.isAfter(value.data.first);
                }),
                value.data);
          }
          updateChartRangesUponPointChange(value.data.first, value.data.second);
          _database.saveData(dataKey, -1);
          reloadDataCache = true;
        });
      }
    });
  }

  dynamic getSettingValue(String hiveKey, Box box, dynamic defaultValue) {
    if (box.keys.contains(hiveKey)) {
      return box.get(hiveKey);
    }
    return defaultValue;
  }

  Future<void> loadSettings() async {
    var box = await Hive.openBox('settings');
    setState(() {
      selectedKeys = getSettingValue(hiveKeyselectedItem, box, <String>[]);

      // chart zoom
      _xMin = getSettingValue(hiveKeyxMin, box, _xMin);
      _xMax = getSettingValue(hiveKeyxMax, box, _xMin);
      _yMin = getSettingValue(hiveKeyyMin, box, _yMin);
      _yMax = getSettingValue(hiveKeyyMax, box, _yMin);

      _lastShare = getSettingValue(hiveKeyLastShare, box, _lastShare);
      _rightHanded = getSettingValue(hiveKeyControlsSide, box, _rightHanded);

      _askForLogin = getSettingValue(hiveKeyAskForLogin, box, true);

      _settingsLoaded = true;
    });
  }

  Future<void> saveSettings(String key, dynamic value) async {
    var box = await Hive.openBox('settings');
    box.put(key, value);
  }

  Future<void> saveListSettings(String key, List<dynamic> value) async {
    var box = await Hive.openBox('settings');
    box.put(key, value);
  }

  void saveZoom() {
    saveSettings(hiveKeyxMax, _xMax);
    saveSettings(hiveKeyxMin, _xMin);
    saveSettings(hiveKeyyMax, _yMax);
    saveSettings(hiveKeyyMin, _yMin);
  }

  void keyValuePressed(String key) {
    setState(() {
      if (selectedKeys.contains(key)) {
        selectedKeys.remove(key);
      } else {
        selectedKeys.add(key);
      }
      reloadDataCache = true;
      saveListSettings(hiveKeyselectedItem, selectedKeys);
    });
  }

  void updateData(
      String key, int index, DateTime date, double value, String note,
      {bool deleteValue = false}) {
    assert(data.keys.contains(key));
    assert(data[key]!.data.length >= index && index >= 0);
    setState(() {
      if (data[key]!.data.isEmpty && index == 0) {
        data[key]!.data.add(Data(first: date, second: value, note: note));
      } else {
        if (deleteValue) {
          data[key]!.data.removeAt(index);
        } else {
          if (data[key]!.data[index].first == date) {
            data[key]!.data[index].second = value;
            data[key]!.data[index].note = note;
          } else {
            data[key]!.data[index].first = date;
            data[key]!.data[index].second = value;
            data[key]!.data[index].note = note;
            data[key]!.data.sort(((a, b) => a.first.compareTo(b.first)));
          }
        }
      }
      updateChartRangesUponPointChange(date, value);
      reloadDataCache = true;
      if (deleteValue) {
        _database.deleteData(key, index);
      } else {
        _database.saveData(key, index);
      }
    });
  }

  void deleteKey(key) async {
    setState(() {
      data.remove(key);
      if (selectedKeys.contains(key)) {
        selectedKeys.remove(key);
        saveListSettings(hiveKeyselectedItem, selectedKeys);
      }
      reloadDataCache = true;
      _database.deleteData(key, databaseAll);
    });
  }

  void editKey(key) async {
    EditSeriesDialog.show(context, data, isFree, this, defaultValue: data[key])
        .then((seriesReturn) {
      if (seriesReturn != null) {
        if (seriesReturn.delete) {
          setState(() {
            deleteKey(seriesReturn.container.name);
          });
        } else {
          var value = seriesReturn.container;
          setState(() {
            if (key != value.name) {
              var oldKey = key;
              data[value.name] = data[key]!;
              key = value.name;
              data.remove(oldKey);
            }
            data[key]!.color = value.color;
            data[key]!.name = value.name;
            data[key]!.note = value.note;
            data[key]!.isDateOnly = value.isDateOnly;
            data[key]!.isFavourite = value.isFavourite;
            reloadDataCache = true;
            // TODO: update only key
            _database.saveData(key, databaseAll);
          });
        }
      }
    });
  }

  void _addKey(DataContainer value) {
    setState(() {
      if (data.keys.contains(value.name) == false) {
        data[value.name] = value;
        selectedKeys.add(value.name);
        _database.saveData(value.name, databaseAll);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var activeWidget =
        dataLoaded ? getChart() : const CircularProgressIndicator();
    if (_settingsLoaded && _askForLogin && _loggedInUser == null) {
      _showSignInDialog();
    }
    return _settingsLoaded
        ? Scaffold(
            body: Screenshot(
                controller: _screenshotController,
                child: Stack(
                  children: [
                    Container(
                      color: Colors.amber.shade50,
                    ),
                    activeWidget,
                    Row(
                        mainAxisAlignment: _rightHanded
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.end,
                        children: [
                          const SizedBox(
                            width: 20,
                          ),
                          getDataLabelsWidget()
                        ])
                  ],
                )),
            floatingActionButton: getFloatingActionButton(),
          )
        : const Scaffold();
  }

  void _onShare() async {
    if (isFree) {
      Duration shareInterval = DateTime.now().difference(_lastShare);
      if (shareInterval.compareTo(_freeShareDuration) < 0) {
        freeAppWarning(context,
            "Free version allows share only once per 30 days. Next share in ${shareInterval.inDays} day(s)");
        return;
      }
    }
    final directory = await getApplicationDocumentsDirectory();
    _screenshotController
        .captureAndSave(directory.path,
            fileName: "dataTrackerScreenshot.png",
            pixelRatio: MediaQuery.of(context).devicePixelRatio)
        .then((imagePath) async {
      await SocialShare.shareOptions("Hello world", imagePath: imagePath);
      _lastShare = DateTime.now();
      saveSettings(hiveKeyLastShare, _lastShare);
    });
  }

  void _onAddSeries() {
    if (isFree && data.keys.length >= 5) {
      // limit free app to 5 labels
      freeAppWarning(
          context, "You can have a maximum of 5 labels in the free version.");
      return;
    }
    EditSeriesDialog.show(context, data, isFree, this).then((value) => {
          if (value != null) {_addKey(value.container)}
        });
  }

  double minValueOfData(String key) {
    assert(data[key]!.data.isNotEmpty);
    double ret = data[key]!.data.first.second;
    for (var d in data[key]!.data) {
      ret = min(ret, d.second);
    }
    return ret;
  }

  double maxValueOfData(String key) {
    assert(data[key]!.data.isNotEmpty);
    double ret = data[key]!.data.first.second;
    for (var d in data[key]!.data) {
      ret = max(ret, d.second);
    }
    return ret;
  }

  void _onZoomOut() {
    setState(() {
      var firstKey = selectedKeys
          .firstWhereOrNull((element) => data[element]!.data.isNotEmpty);
      if (firstKey == null) {
        _xMin = DateTime.now();
        _xMax = _xMin;
        _yMin = .0;
        _yMax = .0;
        return;
      } else {
        _xMin = data[firstKey]!.data.first.first;
        _xMax = data[firstKey]!.data.last.first;
        _yMin = minValueOfData(firstKey);
        _yMax = maxValueOfData(firstKey);
      }
      for (var key in selectedKeys) {
        _xMin = data[key]!.data.first.first.isBefore(_xMin)
            ? data[key]!.data.first.first
            : _xMin;
        _xMax = data[key]!.data.last.first.isAfter(_xMax)
            ? data[key]!.data.last.first
            : _xMax;
        _yMin = min(minValueOfData(key), _yMin);
        _yMax = max(maxValueOfData(key), _yMax);
      }
    });
  }

  void _onHandSide() {
    setState(() {
      _rightHanded = !_rightHanded;
      saveSettings(hiveKeyControlsSide, _rightHanded);
    });
  }

  Widget getDataLabelsWidget() {
    List<Widget> dataLabels = [];
    List<String> favouriteKeys = [];
    dataLabels.add(SizedBox(
      height: MediaQuery.of(context).padding.top,
    ));
    double width = MediaQuery.of(context).size.width * 3 / 8;
    for (var key in data.keys) {
      if (data[key]!.isFavourite) {
        favouriteKeys.add(key);
        dataLabels.add(createKeyButton(key, context, this, width));
      }
    }
    for (var key in data.keys) {
      if (favouriteKeys.contains(key)) {
        continue;
      }
      dataLabels.add(createKeyButton(key, context, this, width));
    }
    return ShaderMask(
        shaderCallback: (Rect bounds) {
          var xCoord = (Alignment.center.x + Alignment.bottomCenter.x) / 2;
          var yCoord = (Alignment.center.y + Alignment.bottomCenter.y) / 2;
          return LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment(xCoord, yCoord),
            colors: const [Colors.black, Colors.transparent],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstOut,
        child: SizedBox(
            height: MediaQuery.of(context).size.height / 4,
            child: SingleChildScrollView(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: dataLabels,
            ))));
  }

  Widget? getFloatingActionButton() {
    bool expandedMenuSideAware = expandedMenu;
    if (!_rightHanded) {
      expandedMenuSideAware = !expandedMenuSideAware;
    }
    if (dataLoaded) {
      List<Widget> floatingButtons = [];
      if (expandedMenu) {
        floatingButtons.addAll([
          FloatingActionButton(
              onPressed: () {
                setState(() {
                  _showAboutDialog();
                });
              },
              mini: true,
              child: const Icon(Icons.info_outline)),
          const SizedBox(
            height: 5,
          ),
        ]);
        if (_loggedInUser == null) {
          floatingButtons.addAll([
            FloatingActionButton(
                onPressed: () {
                  setState(() {
                    expandedMenu = false;
                    _showSignInDialog();
                  });
                },
                mini: true,
                child: const Icon(Icons.login)),
            const SizedBox(
              height: 5,
            ),
          ]);
        } else {
          floatingButtons.addAll([
            FloatingActionButton(
                onPressed: () {
                  setState(() {
                    expandedMenu = false;
                    Authentication.logout();
                    _loggedInUser = null;
                  });
                },
                mini: true,
                child: const Icon(Icons.logout)),
            const SizedBox(
              height: 5,
            ),
          ]);
        }
        floatingButtons.addAll([
          FloatingActionButton(
            onPressed: _onHandSide,
            mini: true,
            child: Icon(_rightHanded
                ? Icons.front_hand_outlined
                : Icons.back_hand_outlined),
          ),
          const SizedBox(
            height: 5,
          ),
          FloatingActionButton(
            onPressed: _onZoomOut,
            mini: true,
            child: const Icon(Icons.zoom_out_map),
          ),
          const SizedBox(
            height: 5,
          ),
          FloatingActionButton(
            onPressed: _onShare,
            mini: true,
            child: const Icon(Icons.share),
          ),
          const SizedBox(
            height: 5,
          ),
          FloatingActionButton(
            onPressed: _onAddSeries,
            mini: true,
            child: expandedMenu
                ? const Icon(Icons.add_chart)
                : const Icon(Icons.arrow_back_ios_sharp),
          ),
          const SizedBox(
            height: 5,
          ),
        ]);
      }
      floatingButtons.addAll([
        FloatingActionButton(
          backgroundColor: expandedMenu ? Colors.orangeAccent : Colors.teal,
          onPressed: () => setState(() {
            expandedMenu = !expandedMenu;
          }),
          tooltip: expandedMenu ? "Close actions" : "Open actions",
          mini: true,
          child: expandedMenuSideAware
              ? const Icon(Icons.arrow_forward_ios_sharp)
              : const Icon(Icons.arrow_back_ios_sharp),
        ),
        const SizedBox(height: 15),
        FloatingActionButton(
          onPressed: onAddPressed,
          tooltip: "Add new data to data series",
          child: const Icon(Icons.add),
        ),
        const SizedBox(height: 15),
      ]);
      return Stack(children: [
        Row(
            mainAxisAlignment:
                _rightHanded ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              const SizedBox(
                width: 30,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: floatingButtons,
              )
            ]),
      ]);
    }
    return null;
  }

  void onAddPressed() {
    if (data.isEmpty) {
      EditSeriesDialog.show(context, data, isFree, this).then((value) => {
            if (value != null)
              {
                _addKey(value.container),
              }
          });
    } else {
      _addNewRecord();
    }
  }

  void updateDataCache() {
    if (reloadDataCache) {
      dataCache.clear();
      List<String> keysToRemove = [];
      for (var dataKey in selectedKeys) {
        if (!data.keys.contains(dataKey)) {
          keysToRemove.add(dataKey);
          continue;
        }
        if (data[dataKey]!.data.isNotEmpty && !dataCache.containsKey(dataKey)) {
          dataCache[dataKey] = [];
        }
        for (var dt in data[dataKey]!.data) {
          dataCache[dataKey]!
              .add(DataCacheEntry(dt.first, dt.second, dataKey, dt.note));
        }
      }
      if (keysToRemove.isNotEmpty) {
        selectedKeys.removeWhere((element) => keysToRemove.contains(element));
        saveListSettings(hiveKeyselectedItem, selectedKeys);
      }
    }
  }

  SfCartesianChart getChart() {
    updateDataCache();
    List<ChartSeries> series = [];
    for (var dataKey in dataCache.keys) {
      series.add(LineSeries<DataCacheEntry, DateTime>(
          dataSource: dataCache[dataKey]!,
          xValueMapper: (DataCacheEntry dataItem, _) => dataItem.time,
          yValueMapper: (DataCacheEntry dataItem, _) => dataItem.value,
          color: data[dataKey]!.color));
      series.add(ScatterSeries<DataCacheEntry, DateTime>(
        dataSource: dataCache[dataKey]!,
        xValueMapper: (DataCacheEntry dataItem, _) => dataItem.time,
        yValueMapper: (DataCacheEntry dataItem, _) => dataItem.value,
        color: data[dataKey]!.color,
        markerSettings: const MarkerSettings(
            shape: DataMarkerType.circle, width: 20, height: 20),
        onPointTap: (pointInteractionDetails) {
          var index = pointInteractionDetails.pointIndex!;
          var originalTime = dataCache[dataKey]![index].time;
          var originalValue = dataCache[dataKey]![index].value;
          var originalNote = dataCache[dataKey]![index].note;
          showDataInputDialog(context, data, selectedKeys,
                  date: originalTime,
                  value: originalValue,
                  note: originalNote,
                  defaultKey: dataKey,
                  enableDelete: true)
              .then((newValues) {
            if (newValues != null) {
              updateData(dataKey, index, newValues.data.first,
                  newValues.data.second, newValues.data.note,
                  deleteValue: newValues.delete);
            }
          });
        },
      ));
    }
    bool displayTime = false;
    for (var key in selectedKeys) {
      if (!data[key]!.isDateOnly) {
        displayTime = true;
        break;
      }
    }
    String dateFormat = DateFormat.YEAR_ABBR_MONTH_DAY;
    if (displayTime) {
      dateFormat = "y-M-d H:m";
    }
    DateTimeAxis xAxis = (_xMax == _xMin)
        ? DateTimeAxis(dateFormat: DateFormat(dateFormat))
        : DateTimeAxis(
            dateFormat: DateFormat(dateFormat),
            visibleMinimum: _xMin,
            visibleMaximum: _xMax);
    NumericAxis yAxis = (_yMax == _yMin)
        ? NumericAxis()
        : NumericAxis(visibleMinimum: _yMin, visibleMaximum: _yMax);
    return SfCartesianChart(
      primaryXAxis: xAxis,
      primaryYAxis: yAxis,
      series: series,
      zoomPanBehavior: ZoomPanBehavior(
        enableMouseWheelZooming: true,
        enablePinching: true,
        enablePanning: true,
      ),
      onActualRangeChanged: (rangeChangedArgs) {
        if (rangeChangedArgs.axisName == "primaryXAxis") {
          _xMin =
              DateTime.fromMillisecondsSinceEpoch(rangeChangedArgs.visibleMin);
          _xMax =
              DateTime.fromMillisecondsSinceEpoch(rangeChangedArgs.visibleMax);
        }
        if (rangeChangedArgs.axisName == "primaryYAxis") {
          _yMin = rangeChangedArgs.visibleMin.toDouble();
          _yMax = rangeChangedArgs.visibleMax.toDouble();
        }
        saveZoom();
      },
    );
  }
}

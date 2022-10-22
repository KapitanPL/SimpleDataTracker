import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:split_view/split_view.dart';
import 'package:intl/intl.dart';

import 'src/dataRecord/data.dart';
import 'src/widgets/key_button.dart';

import 'src/dialogs/data_input_dialog.dart';
import 'src/dialogs/edit_series.dart';
import 'src/dialogs/frea_app_waring.dart';
import 'src/dialogs/yes_no_question.dart';

typedef CallbackFunction = void Function();

const bool isFree = true;

const String hiveKeyselectedItem = "selectedItem";
const String hiveKeySplitterWeights = "splitterWeights";

const String hiveKeyxMin = "xMin";
const String hiveKeyxMax = "xMax";
const String hiveKeyyMin = "yMin";
const String hiveKeyyMax = "yMax";

const double dayInMiliseconds = 24 * 60 * 60 * 1000;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var directory = await getApplicationSupportDirectory(); //? Or some better
  Hive
    ..init(directory.path)
    ..registerAdapter(DataAdapter())
    ..registerAdapter(DataContainerAdapter())
    ..registerAdapter(ColorAdapter());
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
  List<double> _splitterWeights = [0.1, 0.9];

  Map<String, List<DataCacheEntry>> dataCache = {};
  bool reloadDataCache = false;
  bool dataLoaded = false;
  bool expandedMenu = false;

  DateTime _xMin = DateTime.now();
  DateTime _xMax = DateTime.now();
  double _yMin = .0;
  double _yMax = .0;

  DataTrackerState() {
    loadSettings();
    loadData().then(
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
          saveData(key: dataKey);
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
    selectedKeys = getSettingValue(hiveKeyselectedItem, box, <String>[]);
    _splitterWeights =
        getSettingValue(hiveKeySplitterWeights, box, _splitterWeights);

    // chart zoom
    _xMin = getSettingValue(hiveKeyxMin, box, _xMin);
    _xMax = getSettingValue(hiveKeyxMax, box, _xMin);
    _yMin = getSettingValue(hiveKeyyMin, box, _yMin);
    _yMax = getSettingValue(hiveKeyyMax, box, _yMin);
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
      for (var key in data.keys) {
        box.put(key, data[key]);
      }
    } else {
      box.put(key, data[key]);
    }
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
      saveData(key: key);
    });
  }

  void deleteKey(key) async {
    yesNoQuestion(context, "Delete $key?").then((value) {
      if (value) {
        setState(() {
          data.remove(key);
          if (selectedKeys.contains(key)) {
            selectedKeys.remove(key);
            saveListSettings(hiveKeyselectedItem, selectedKeys);
          }
          reloadDataCache = true;
          saveData();
        });
      }
    });
  }

  void editKey(key) async {
    EditSeriesDialog.show(context, data, isFree, defaultValue: data[key])
        .then((value) {
      if (value != null) {
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
          saveData();
        });
      }
    });
  }

  void _addKey(DataContainer value) {
    setState(() {
      if (data.keys.contains(value.name) == false) {
        data[value.name] = value;
        selectedKeys.add(value.name);
        saveData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> dataLabels = [];
    List<String> favouriteKeys = [];
    for (var key in data.keys) {
      if (data[key]!.isFavourite) {
        favouriteKeys.add(key);
        dataLabels.add(createKeyButton(key, context, this));
      }
    }
    for (var key in data.keys) {
      if (favouriteKeys.contains(key)) {
        continue;
      }
      dataLabels.add(createKeyButton(key, context, this));
    }
    var activeWidget =
        dataLoaded ? getChart() : const CircularProgressIndicator();
    return Scaffold(
      body: SplitView(
        viewMode: SplitViewMode.Vertical,
        controller: SplitViewController(limits: [
          WeightLimit(min: 0.05, max: 0.35),
          WeightLimit(min: 0.65, max: 0.95)
        ], weights: _splitterWeights),
        onWeightChanged: (weightList) {
          _splitterWeights.clear();
          for (var weight in weightList) {
            if (weight != null) {
              _splitterWeights.add(weight);
            }
          }
          saveListSettings(hiveKeySplitterWeights, _splitterWeights);
        },
        children: [
          SizedBox(
              height: 50,
              child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(children: <Widget>[
                    SizedBox(height: MediaQuery.of(context).viewPadding.top),
                    Wrap(
                      alignment: WrapAlignment.start,
                      spacing: 3,
                      children: dataLabels,
                    )
                  ]))),
          activeWidget,
        ],
      ),
      floatingActionButton: getFloatingActionButton(),
    );
  }

  Widget? getFloatingActionButton() {
    if (dataLoaded) {
      List<Widget> floatingButtons = [];
      if (expandedMenu) {
        floatingButtons.addAll([
          FloatingActionButton(
            onPressed: () {
              if (isFree && data.keys.length >= 5) {
                // limit free app to 5 labels
                freeAppWarning(context,
                    "You can have a maximum of 5 labels in the free version.");
                return;
              }
              EditSeriesDialog.show(context, data, isFree).then((value) => {
                    if (value != null) {_addKey(value)}
                  });
            },
            mini: true,
            child: expandedMenu
                ? const Icon(Icons.add_chart)
                : Transform.scale(
                    scaleX: -1, child: const Icon(Icons.play_arrow_sharp)),
          ),
          const SizedBox(
            height: 10,
          )
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
          child: expandedMenu
              ? const Icon(Icons.play_arrow_sharp)
              : Transform.scale(
                  scaleX: -1, child: const Icon(Icons.play_arrow_sharp)),
        ),
        const SizedBox(height: 15),
        FloatingActionButton(
          onPressed: _addNewRecord,
          tooltip: "Add new data to data series",
          child: const Icon(Icons.add),
        ),
        const SizedBox(height: 15),
      ]);
      return Column(
          mainAxisAlignment: MainAxisAlignment.end, children: floatingButtons);
    }
    return null;
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
    DateTimeAxis xAxis = (_xMax == _xMin)
        ? DateTimeAxis(dateFormat: DateFormat(DateFormat.YEAR_ABBR_MONTH_DAY))
        : DateTimeAxis(
            dateFormat: DateFormat(DateFormat.YEAR_ABBR_MONTH_DAY),
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

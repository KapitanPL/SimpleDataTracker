import 'dart:math';

import 'package:datatracker/src/utils/contrast_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_circle_color_picker/flutter_circle_color_picker.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:split_view/split_view.dart';

import 'src/dataRecord/data.dart';
import 'src/widgets/key_button.dart';
import 'src/widgets/custom_popup_menu_item.dart';

typedef CallbackFunction = void Function();

extension TimeManipulation on DateTime {
  DateTime getMidnight() {
    return DateTime(year, month, day);
  }
}

const String hiveKeyselectedItem = "selectedItem";
const String hiveKeySplitterWeights = "splitterWeights";

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
  DataCacheEntry(this.time, this.value, this.datakey);
  DateTime time;
  double value;
  String datakey;
}

class DataTrackerState extends State<MyHomePage> {
  Map<String, DataContainer> data = {};
  final _yTextFieldController = TextEditingController();
  final _textFieldController = TextEditingController();
  final _descriptionFieldController = TextEditingController();
  final _colorController = CircleColorPickerController(
    initialColor: Colors.blue,
  );
  List<String> selectedKeys = [];
  String _valueEnterKey = "";
  String _timeValueText = "";
  List<double> _splitterWeights = [0.1, 0.9];

  Map<String, List<DataCacheEntry>> dataCache = {};
  bool reloadDataCache = false;
  bool dataLoaded = false;
  bool expandedMenu = false;

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

  void _addNewRecord() {
    if (data.keys.isEmpty) {
      return;
    }
    _showDataInputDialog().then((value) {
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
          saveData();
          reloadDataCache = true;
        });
      }
    });
  }

  Future<void> loadSettings() async {
    var box = await Hive.openBox('settings');
    if (box.keys.contains(hiveKeyselectedItem)) {
      selectedKeys = box.get(hiveKeyselectedItem);
    }
    if (box.keys.contains(hiveKeySplitterWeights)) {
      _splitterWeights = box.get(hiveKeySplitterWeights);
    }
  }

  Future<void> saveSettings(String key, String value) async {
    var box = await Hive.openBox('settings');
    box.put(key, value);
  }

  Future<void> saveListSettings(String key, List<dynamic> value) async {
    var box = await Hive.openBox('settings');
    box.put(key, value);
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

  Future<void> saveData() async {
    var box = await Hive.openBox('dataBox');
    box.clear();
    for (var key in data.keys) {
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

  void updateData(String key, int index, DateTime date, double value) {
    assert(data.keys.contains(key));
    assert(data[key]!.data.length >= index && index >= 0);
    setState(() {
      if (data[key]!.data.isEmpty && index == 0) {
        data[key]!.data.add(Data(first: date, second: value));
      }
      if (data[key]!.data[index].first == date) {
        data[key]!.data[index].second = value;
      } else {
        data[key]!.data[index].first = date;
        data[key]!.data[index].second = value;
        data[key]!.data.sort(((a, b) => a.first.compareTo(b.first)));
      }
      reloadDataCache = true;
      saveData();
    });
  }

  Future<bool> yesNoQuestion(BuildContext context, String question) async {
    bool result = await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Qestion'),
            content: Text(question),
            actions: <Widget>[
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop(
                      false); // dismisses only the dialog and returns false
                },
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true)
                      .pop(true); // dismisses only the dialog and returns true
                },
                child: const Text('Yes'),
              ),
            ],
          );
        });
    return result;
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
    _editSeries(defaultValue: data[key]).then((value) {
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
    for (var key in data.keys) {
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
            onPressed: () => _editSeries().then((value) => {
                  if (value != null) {_addKey(value)}
                }),
            mini: true,
            child: expandedMenu
                ? const Icon(Icons.add_chart)
                : Transform.scale(
                    scaleX: -1, child: const Icon(Icons.play_arrow_sharp)),
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
      for (var dataKey in selectedKeys) {
        if (data[dataKey]!.data.isNotEmpty && !dataCache.containsKey(dataKey)) {
          dataCache[dataKey] = [];
        }
        for (var dt in data[dataKey]!.data) {
          dataCache[dataKey]!.add(DataCacheEntry(dt.first, dt.second, dataKey));
        }
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
          _showDataInputDialog(date: originalTime, value: originalValue)
              .then((newValues) {
            if (newValues != null) {
              updateData(
                  dataKey, index, newValues.data.first, newValues.data.second);
            }
          });
        },
      ));
    }
    return SfCartesianChart(
      primaryXAxis: DateTimeAxis(
          dateFormat: DateFormat(DateFormat.YEAR_ABBR_MONTH_DAY),
          visibleMinimum: DateTime.now().subtract(const Duration(days: 7))),
      series: series,
      zoomPanBehavior:
          ZoomPanBehavior(enableMouseWheelZooming: true, enablePinching: true),
    );
  }

  String? get _errorKeyText {
    // at any time, we can get the text from _controller.value.text
    final text = _textFieldController.value.text;
    // Note: you can do your own custom validation here
    // Move this logic this outside the widget for more testable code
    if (text.isEmpty) {
      return 'Can\'t be empty';
    }
    if (data.keys.contains(text)) {
      return 'Key already exists';
    }
    // return null if the text is valid
    return null;
  }

  Future<DataContainer?> _editSeries({DataContainer? defaultValue}) async {
    if (defaultValue != null) {
      _textFieldController.text = defaultValue.name;
      _descriptionFieldController.text = defaultValue.note;
      _colorController.color = defaultValue.color;
    } else {
      _textFieldController.text = "";
      _descriptionFieldController.text = "";
      _colorController.color = Colors.red;
    }
    return showDialog(
        context: context,
        builder: (context) {
          return ValueListenableBuilder(
              // Note: pass _controller to the animation argument
              valueListenable: _textFieldController,
              builder: (context, TextEditingValue value, __) {
                return AlertDialog(
                  content: SizedBox(
                      child: Column(children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'New data series:',
                        errorText: _errorKeyText,
                      ),
                      controller: _textFieldController,
                    ),
                    CircleColorPicker(
                      controller: _colorController,
                    ),
                    TextField(
                      decoration:
                          const InputDecoration(labelText: "Description"),
                      controller: _descriptionFieldController,
                    )
                  ])),
                  actions: <Widget>[
                    ElevatedButton(
                      child: const Text("Cancel"),
                      onPressed: () => Navigator.pop(context),
                    ),
                    ElevatedButton(
                      onPressed: _textFieldController.value.text.isNotEmpty
                          ? () => Navigator.pop(
                              context,
                              DataContainer(
                                  name: _textFieldController.text,
                                  color: _colorController.color,
                                  note: _descriptionFieldController.text))
                          : null,
                      child: const Text('OK'),
                    ),
                  ],
                );
              });
        });
  }

  Future<DataDialogReturn?> _showDataInputDialog(
      {DateTime? date, double? value}) async {
    List<PopupMenuItem> keys = [];
    _yTextFieldController.text = value != null ? "$value" : "";
    for (var key in data.keys) {
      keys.add(CustomPopupMenuItem(
        value: keys.isEmpty ? 0 : keys.last.value + 1,
        color: data[key]!.color,
        child: Text(key,
            style: TextStyle(
                overflow: TextOverflow.ellipsis,
                //backgroundColor: data[key]!.color,
                color: contrastColor(data[key]!.color))),
      ));
    }
    if (!data.keys.contains(_valueEnterKey)) {
      if (selectedKeys.isEmpty) {
        _valueEnterKey = data.keys.first;
      } else {
        _valueEnterKey = selectedKeys.last;
      }
    }

    const List<PopupMenuItem> timeKeys = [
      PopupMenuItem(
        value: 0,
        child: Text("Today"),
      ),
      PopupMenuItem(
        value: 1,
        child: Text("Yesterday"),
      ),
      PopupMenuItem(
        value: 2,
        child: Text("Other"),
      ),
    ];
    _timeValueText = date == null
        ? "Today"
        : DateFormat(DateFormat.YEAR_ABBR_MONTH_DAY).format(date);
    var returnDate = date ?? DateTime.now();
    var smallerSide = min(MediaQuery.of(context).size.width,
            MediaQuery.of(context).size.height) /
        2;
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
              return SizedBox(
                  height: 100,
                  child: Column(
                    children: [
                      PopupMenuButton(
                        position: PopupMenuPosition.under,
                        iconSize: 15,
                        itemBuilder: (BuildContext context) => keys,
                        onSelected: (item) {
                          setState(() {
                            _valueEnterKey =
                                (keys[item.hashCode].child as Text).data!;
                          });
                        },
                        child: Container(
                            color: data[_valueEnterKey]!.color,
                            child: Row(children: [
                              Icon(
                                Icons.keyboard_double_arrow_down,
                                color:
                                    contrastColor(data[_valueEnterKey]!.color),
                              ),
                              Flexible(
                                  child: Text(
                                _valueEnterKey,
                                style: TextStyle(
                                    overflow: TextOverflow.ellipsis,
                                    color: contrastColor(
                                        data[_valueEnterKey]!.color)),
                              )),
                            ])),
                      ),
                      Row(
                        children: [
                          Expanded(
                              child: PopupMenuButton(
                            position: PopupMenuPosition.under,
                            iconSize: 15,
                            itemBuilder: (BuildContext context) => timeKeys,
                            onSelected: (item) {
                              //_timeValueText = (timeKeys[item.hashCode].child as Text).data!;
                              switch (item.hashCode) {
                                case 0:
                                  {
                                    var now = DateTime.now();
                                    returnDate = now.getMidnight();
                                    setState(() {
                                      _timeValueText = DateFormat(
                                              DateFormat.YEAR_ABBR_MONTH_DAY)
                                          .format(now);
                                    });
                                    break;
                                  }
                                case 1:
                                  {
                                    setState(() {
                                      var yesterday = DateTime.now()
                                          .subtract(const Duration(days: 1));
                                      returnDate = yesterday.getMidnight();
                                      _timeValueText = DateFormat(
                                              DateFormat.YEAR_ABBR_MONTH_DAY)
                                          .format(yesterday);
                                    });
                                    break;
                                  }
                                case 2:
                                  {
                                    showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          DateTime localDateValue =
                                              DateTime.now();
                                          return AlertDialog(
                                              title: const Text(''),
                                              content: SizedBox(
                                                height: smallerSide + 100,
                                                child: Column(
                                                  children: <Widget>[
                                                    SizedBox(
                                                        width: smallerSide,
                                                        height: smallerSide,
                                                        child: Card(
                                                            child:
                                                                SfDateRangePicker(
                                                          view:
                                                              DateRangePickerView
                                                                  .month,
                                                          selectionMode:
                                                              DateRangePickerSelectionMode
                                                                  .single,
                                                          onSelectionChanged:
                                                              ((dateRangePickerSelectionChangedArgs) {
                                                            localDateValue =
                                                                dateRangePickerSelectionChangedArgs
                                                                    .value;
                                                          }),
                                                        ))),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.end,
                                                      children: [
                                                        ElevatedButton(
                                                          child:
                                                              const Text("OK"),
                                                          onPressed: () {
                                                            var theDate = DateTime(
                                                                localDateValue
                                                                    .year,
                                                                localDateValue
                                                                    .month,
                                                                localDateValue
                                                                    .day);
                                                            setState(() {
                                                              returnDate = theDate
                                                                  .getMidnight();
                                                              _timeValueText = DateFormat(
                                                                      DateFormat
                                                                          .YEAR_ABBR_MONTH_DAY)
                                                                  .format(
                                                                      theDate);
                                                            });
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                        ),
                                                        ElevatedButton(
                                                          child: const Text(
                                                              "Cancel"),
                                                          onPressed: () {
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                        )
                                                      ],
                                                    )
                                                  ],
                                                ),
                                              ));
                                        });
                                    break;
                                  }
                              }
                            },
                            child: Row(children: [
                              const Icon(Icons.keyboard_double_arrow_down),
                              Expanded(child: Text(_timeValueText)),
                            ]),
                          )),
                          Expanded(
                              child: TextField(
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.-]+'))
                            ],
                            decoration:
                                const InputDecoration(labelText: "Value"),
                            controller: _yTextFieldController,
                          )),
                        ],
                      )
                    ],
                  ));
            }),
            actions: <Widget>[
              ElevatedButton(
                  child: const Text("Cancel"),
                  onPressed: () {
                    _valueEnterKey = "";
                    Navigator.pop(context);
                  }),
              ElevatedButton(
                  child: const Text('OK'),
                  onPressed: () {
                    var categoryKey = _valueEnterKey;
                    _valueEnterKey = "";
                    _yTextFieldController.text.isEmpty
                        ? Navigator.pop(context)
                        : Navigator.pop(
                            context,
                            DataDialogReturn(
                                category: categoryKey,
                                data: Data(
                                    first: returnDate,
                                    second: double.parse(
                                        _yTextFieldController.text))));
                  }),
            ],
          );
        });
  }
}

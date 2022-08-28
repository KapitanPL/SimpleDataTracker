import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_circle_color_picker/flutter_circle_color_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:intl/intl.dart';

import 'src/dataRecord/data.dart';

typedef CallbackFunction = void Function();

extension FlSpotConvertor on List<Data> {
  List<FlSpot> getSpots() {
    List<FlSpot> res = [];
    for (var dt in this) {
      res.add(FlSpot(dt.first.millisecondsSinceEpoch.toDouble(), dt.second));
    }
    return res;
  }
}

extension TimeManipulation on DateTime {
  DateTime getMidnight() {
    return DateTime(year, month, day);
  }
}

const String hiveKeyselectedItem = "selectedItem";

const double dayInMiliseconds = 24 * 60 * 60 * 1000;

void main() {
  var path = Directory.current.path; //? Or some better
  Hive
    ..init(path)
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
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Map<String, DataContainer> data = {};
  final _yTextFieldController = TextEditingController();
  final _textFieldController = TextEditingController();
  final _descriptionFieldController = TextEditingController();
  final _colorController = CircleColorPickerController(
    initialColor: Colors.blue,
  );
  List<String> _selectedKeys = [];
  String _valueEnterKey = "";
  String _timeValueText = "";

  List<LineChartBarData> lineChartBarDataCache = [];
  bool reloadDataCache = false;
  bool dataLoaded = false;

  _MyHomePageState() {
    loadSettings();
    loadData().then(
      (value) {
        setState(() {
          data = value;
          reloadDataCache = true;
          dataLoaded = true;
        });
      },
    );
  }

  void _addNewRecord() {
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
      _selectedKeys = box.get(hiveKeyselectedItem);
    }
    box.close();
  }

  Future<void> saveSettings(String key, String value) async {
    var box = await Hive.openBox('settings');
    box.put(key, value);
    box.close();
  }

  Future<void> saveListSettings(String key, List<String> value) async {
    var box = await Hive.openBox('settings');
    box.put(key, value);
    box.close();
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
      if (_selectedKeys.contains(key)) {
        _selectedKeys.remove(key);
      } else {
        _selectedKeys.add(key);
      }
      reloadDataCache = true;
      saveListSettings(hiveKeyselectedItem, _selectedKeys);
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

  void _deleteKey(key) async {
    yesNoQuestion(context, "Delete $key?").then((value) {
      if (value) {
        setState(() {
          data.remove(key);
          if (_selectedKeys.contains(key)) {
            _selectedKeys.remove(key);
            saveListSettings(hiveKeyselectedItem, _selectedKeys);
          }
          reloadDataCache = true;
          saveData();
        });
      }
    });
  }

  void _editKey(key) async {
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
        _selectedKeys.add(value.name);
        saveData();
      }
    });
  }

  Color contrastColor(Color color) {
    if ((color.red * 0.299 + color.green * 0.587 + color.blue * 0.114) > 186) {
      return Colors.black;
    }
    return Colors.white;
  }

  ElevatedButton createKeyButton(String key) {
    Color textColor = contrastColor(data[key]!.color);
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
            primary: data[key]!.color,
            minimumSize: const Size(0, 30),
            maximumSize: Size(MediaQuery.of(context).size.width - 15, 30),
            elevation: _selectedKeys.contains(key) ? 10 : 0),
        onPressed: () => keyValuePressed(key),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(key,
                style: TextStyle(
                  color: textColor,
                  fontWeight: _selectedKeys.contains(key)
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: _selectedKeys.contains(key) ? 20 : 12,
                )),
            PopupMenuButton(
              position: PopupMenuPosition.under,
              iconSize: 15,
              itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                const PopupMenuItem(
                  value: 0,
                  child: Text('Edit'),
                ),
                const PopupMenuItem(
                  value: 1,
                  child: Text('Delete'),
                ),
              ],
              onSelected: (item) {
                switch (item) {
                  case 0: // Edit
                    {
                      _editKey(key);
                      break;
                    }
                  case 1: //Delete
                    {
                      _deleteKey(key);
                      break;
                    }
                }
              },
              icon:
                  Icon(Icons.menu, color: textColor), //dropdown indicator icon
            )
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> dataLabels = [];
    for (var key in data.keys) {
      dataLabels.add(createKeyButton(key));
    }
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Wrap(
              alignment: WrapAlignment.start,
              spacing: 10,
              children: dataLabels,
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height - 50,
              width: MediaQuery.of(context).size.width * 0.98,
              child: (dataLoaded)
                  ? LineChart(getLineChartData())
                  : const CircularProgressIndicator(),
            ),
          ],
        ),
      ),
      floatingActionButton: dataLoaded
          ? Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              FloatingActionButton(
                onPressed: () => _editSeries().then((value) => {
                      if (value != null) {_addKey(value)}
                    }),
                tooltip: 'Add new record',
                mini: true,
                child: const Icon(Icons.add_chart_outlined),
              ),
              const SizedBox(height: 15),
              FloatingActionButton(
                onPressed: _addNewRecord,
                tooltip: 'Add new record',
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 15),
            ])
          : null,
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.blueGrey,
      fontWeight: FontWeight.bold,
      fontSize: 18,
    );
    var timeLabel = DateTime.fromMillisecondsSinceEpoch(value.floor());
    var timeValueText =
        DateFormat(DateFormat.YEAR_ABBR_MONTH_DAY).format(timeLabel);
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 15,
      child: Text(timeValueText, style: style),
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.blueGrey,
      fontWeight: FontWeight.bold,
      fontSize: 18,
    );
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 16,
      child: Text(meta.formattedValue, style: style),
    );
  }

  LineChartData getLineChartData() {
    return LineChartData(
      gridData: FlGridData(show: true, verticalInterval: dayInMiliseconds),
      lineBarsData: getLineChartBarData(),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: leftTitleWidgets,
            reservedSize: 56,
          ),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            interval: dayInMiliseconds,
            showTitles: true,
            getTitlesWidget: bottomTitleWidgets,
            reservedSize: 36,
          ),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
    );
  }

  List<LineChartBarData> getLineChartBarData() {
    if (reloadDataCache) {
      lineChartBarDataCache.clear();
      for (var datasetKey in data.keys) {
        if (_selectedKeys.contains(datasetKey) == false ||
            data[datasetKey]!.data.isEmpty) {
          continue;
        }
        lineChartBarDataCache.add(LineChartBarData(
          color: data[datasetKey]!.color,
          spots: data[datasetKey]!.data.getSpots(),
          isCurved: false,
          isStrokeCapRound: true,
          barWidth: 3,
          belowBarData: BarAreaData(
            show: false,
          ),
          dotData: FlDotData(show: true),
        ));
      }
      reloadDataCache = false;
    }
    return lineChartBarDataCache;
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

  Future<DataDialogReturn?> _showDataInputDialog() async {
    List<PopupMenuItem> keys = [];
    _yTextFieldController.text = "";
    for (var key in data.keys) {
      keys.add(PopupMenuItem(
        value: keys.isEmpty ? 0 : keys.last.value + 1,
        child: Text(key),
      ));
    }
    if (!data.keys.contains(_valueEnterKey)) {
      _valueEnterKey = _selectedKeys.last;
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
    _timeValueText = "Today";
    var returnDate = DateTime.now();
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
                        child: Row(children: [
                          Expanded(child: Text(_valueEnterKey)),
                          const Icon(Icons.keyboard_double_arrow_down)
                        ]),
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
                              Expanded(child: Text(_timeValueText)),
                              const Icon(Icons.keyboard_double_arrow_down)
                            ]),
                          )),
                          Expanded(
                              child: TextField(
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]+'))
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
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: const Text('OK'),
                onPressed: () => _yTextFieldController.text.isEmpty
                    ? Navigator.pop(context)
                    : Navigator.pop(
                        context,
                        DataDialogReturn(
                            category: _valueEnterKey,
                            data: Data(
                                first: returnDate, // TODO return real value
                                second:
                                    double.parse(_yTextFieldController.text)))),
              ),
            ],
          );
        });
  }
}

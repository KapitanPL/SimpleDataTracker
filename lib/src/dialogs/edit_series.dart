import 'package:flutter/material.dart';

import 'package:flutter_circle_color_picker/flutter_circle_color_picker.dart';
import 'package:intl/intl.dart';

import 'package:datatracker/main.dart';
import 'package:datatracker/src/dataRecord/data.dart';
import 'package:datatracker/src/dialogs/frea_app_waring.dart';
import 'package:datatracker/src/dialogs/data_input_dialog.dart';
import 'package:datatracker/src/dialogs/yes_no_question.dart';

class EditSeriesReturn {
  EditSeriesReturn(this.container, this.delete);
  DataContainer container;
  bool delete;
}

class EditSeriesDialog extends AlertDialog {
  static final _textFieldController = TextEditingController();
  static final _descriptionFieldController = TextEditingController();
  static final _colorController = CircleColorPickerController(
    initialColor: Colors.blue,
  );
  static bool _isFavourite = false;
  static bool _isDateOnly = true;
  static bool _isFree = false;
  static bool _showTable = false;

  static const int _maxFreeFavouriteCount = 2;
  static const int _maxFreeDateAndTimeCount = 2;
  static late BuildContext _context;

  EditSeriesDialog(Map<String, DataContainer> data, DataTrackerState mainState,
      {DataContainer? defaultValue})
      : super(
            insetPadding: const EdgeInsets.fromLTRB(.0, 20.0, .0, 24.0),
            content: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
              var width = MediaQuery.of(context).size.width;
              return SizedBox(
                  width: width,
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.all(.0),
                      scrollDirection: Axis.vertical,
                      child: Column(
                          children: getChildren(data, setState, mainState,
                              defaultValue: defaultValue))));
            }),
            actions: getActions(defaultValue));

  static List<Widget> getActions(DataContainer? defaultValue) {
    List<Widget> actions = [];
    if (defaultValue != null) {
      actions.add(ElevatedButton(
          onPressed: () => onDeletePressed(defaultValue.name),
          style: ElevatedButton.styleFrom(primary: Colors.red),
          child: const Text('Delete')));
    }
    actions.addAll(<Widget>[
      ElevatedButton(
        child: const Text("Cancel"),
        onPressed: () => Navigator.pop(_context),
      ),
      const ElevatedButton(
        onPressed: onOkPressed,
        child: Text('OK'),
      ),
    ]);
    return actions;
  }

  static void onDeletePressed(String deleteKey) {
    yesNoQuestion(_context, 'Really delete?').then((value) {
      if (value) {
        Navigator.pop(
            _context,
            EditSeriesReturn(
                DataContainer(name: deleteKey, note: "", color: Colors.red),
                true));
      }
    });
  }

  static void onOkPressed() {
    _textFieldController.value.text.isNotEmpty
        ? Navigator.pop(
            _context,
            EditSeriesReturn(
                DataContainer(
                    name: _textFieldController.text,
                    color: _colorController.color,
                    note: _descriptionFieldController.text,
                    isDateOnly: _isDateOnly,
                    isFavourite: _isFavourite),
                false))
        : Navigator.pop(_context);
  }

  static List<Widget> getChildren(Map<String, DataContainer> data,
      StateSetter setState, DataTrackerState mainState,
      {DataContainer? defaultValue}) {
    List<Widget> children = [];
    children.add(getOptionsBar(setState, data, defaultValue));
    if (_showTable) {
      var dateFormater = DateFormat.yMd();
      children.add(DataTable(
          columnSpacing: 10,
          border: TableBorder.all(color: Colors.teal),
          showCheckboxColumn: false,
          columns: <DataColumn>[
            DataColumn(
              label: Expanded(
                child: Text(
                  (_isDateOnly ? 'Date' : 'Date and Time'),
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ),
            DataColumn(
              label: Expanded(
                child: Text(
                  defaultValue!.name,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ),
            const DataColumn(
              label: Expanded(
                child: Text(
                  'Note',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ),
          ],
          rows: List<DataRow>.generate(
              defaultValue.data.length,
              (int index) => DataRow(
                  color: MaterialStateProperty.resolveWith<Color?>(
                      (Set<MaterialState> states) {
                    // Even rows will have a grey color.
                    if (index.isEven) {
                      return Colors.teal[50];
                    }
                    return Colors.yellow[
                        50]; // Use default value for other states and odd rows.
                  }),
                  cells: <DataCell>[
                    DataCell(Text(
                        dateFormater.format(defaultValue.data[index].first))),
                    DataCell(Center(
                        child:
                            Text(defaultValue.data[index].second.toString()))),
                    DataCell(SizedBox(
                        height: 40,
                        child: Text(
                          defaultValue.data[index].note,
                          overflow: TextOverflow.fade,
                        )))
                  ],
                  onSelectChanged: (value) {
                    showDataInputDialog(_context, data, [],
                            date: defaultValue.data[index].first,
                            value: defaultValue.data[index].second,
                            note: defaultValue.data[index].note,
                            defaultKey: defaultValue.name,
                            enableDelete: true)
                        .then((newValues) {
                      if (newValues != null) {
                        setState(() {
                          mainState.updateData(
                              defaultValue.name,
                              index,
                              newValues.data.first,
                              newValues.data.second,
                              newValues.data.note,
                              deleteValue: newValues.delete);
                        });
                      }
                    });
                  }))));
    } else {
      children.addAll([
        TextField(
          decoration: InputDecoration(
            labelText: (defaultValue != null)
                ? "Data series name"
                : 'New data series:',
            errorText: (defaultValue != null &&
                    _textFieldController.text == defaultValue.name)
                ? ""
                : _errorKeyText(data),
          ),
          controller: _textFieldController,
          onChanged: ((value) {
            setState(() {});
          }),
        ),
        CircleColorPicker(
          controller: _colorController,
        ),
        TextField(
          minLines: 1,
          maxLines: 4,
          decoration: const InputDecoration(labelText: "Description"),
          controller: _descriptionFieldController,
        )
      ]);
    }
    return children;
  }

  static String? _errorKeyText(Map<String, DataContainer> data) {
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

  static ElevatedButton optionButton(VoidCallback? onPressed, IconData icon,
      String label, MaterialColor activeColor, bool isActive) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
          primary: Colors.transparent, shadowColor: Colors.transparent),
      child: Column(children: [
        Icon(
          icon,
          color: isActive ? activeColor : Colors.grey,
          size: 30,
        ),
        Text(
          label,
          style: TextStyle(
              color: isActive ? activeColor : Colors.grey, fontSize: 10),
        ),
      ]),
    );
  }

  static bool checkFavouriteCount(Map<String, DataContainer> data) {
    if (_isFree) {
      int favouriteCount = 0;
      for (var key in data.keys) {
        if (data[key]!.isFavourite) {
          ++favouriteCount;
        }
        if (favouriteCount > _maxFreeFavouriteCount) {
          return false;
        }
      }
    }
    return true;
  }

  static bool checkDateAndTimeCount(Map<String, DataContainer> data) {
    if (_isFree) {
      int dateAndTimeCount = 0;
      for (var key in data.keys) {
        if (!data[key]!.isDateOnly) {
          ++dateAndTimeCount;
        }
        if (dateAndTimeCount > _maxFreeDateAndTimeCount) {
          return false;
        }
      }
    }
    return true;
  }

  static Widget getOptionsBar(StateSetter setState,
      Map<String, DataContainer> data, DataContainer? defaultValue) {
    List<Widget> children = [
      optionButton(() {
        setState(() {
          if (_isFavourite || checkFavouriteCount(data)) {
            _isFavourite = !_isFavourite;
          } else {
            freeAppWarning(_context,
                "You can have a maximmum of 3 favourite data sets in free version.");
          }
        });
      }, Icons.star, "Favourite", Colors.amber, _isFavourite),
      optionButton(() {
        setState(() {
          if (!_isDateOnly || checkDateAndTimeCount(data)) {
            _isDateOnly = !_isDateOnly;
          } else {
            freeAppWarning(_context,
                "You can have a maximmum of 3 Date and Time data sets in free version.");
          }
        });
      }, Icons.access_time, "Use Time", Colors.lightBlue, !_isDateOnly),
    ];
    if (defaultValue != null) {
      children.add(optionButton(() {
        setState(() {
          _showTable = !_showTable;
        });
      },
          _showTable
              ? Icons.arrow_back_ios_sharp
              : Icons.arrow_forward_ios_sharp,
          _showTable ? "Back" : "Table",
          Colors.green,
          _showTable));
    }
    return Wrap(children: children);
  }

  static Future<EditSeriesReturn?> show(BuildContext context,
      Map<String, DataContainer> data, bool isFree, DataTrackerState mainState,
      {DataContainer? defaultValue}) async {
    if (defaultValue != null) {
      _textFieldController.text = defaultValue.name;
      _descriptionFieldController.text = defaultValue.note;
      _colorController.color = defaultValue.color;
      _isFavourite = defaultValue.isFavourite;
      _isDateOnly = defaultValue.isDateOnly;
    } else {
      _textFieldController.text = "";
      _descriptionFieldController.text = "";
      _colorController.color = Colors.red;
    }
    _isFree = isFree;
    _context = context;
    return showDialog(
        context: context,
        builder: (context) {
          return EditSeriesDialog(
            data,
            mainState,
            defaultValue: defaultValue,
          );
        });
  }
}

import 'dart:math';

import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import 'package:datatracker/src/dataRecord/data.dart';
import 'package:datatracker/src/widgets/custom_popup_menu_item.dart';
import 'package:datatracker/src/utils/contrast_color.dart';
import 'package:datatracker/src/dialogs/yes_no_question.dart';

import 'package:datatracker/src/utils/time_utils.dart';

class DataInputDialog extends AlertDialog {
  static final _yTextFieldController = TextEditingController();
  static final _noteTextFieldController = TextEditingController();
  static const List<PopupMenuItem> dateKeys = [
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
  static const List<PopupMenuItem> timeKeys = [
    PopupMenuItem(
      value: 0,
      child: Text("Now"),
    ),
    PopupMenuItem(
      value: 2,
      child: Text("Other"),
    ),
  ];
  static DateTime returnDate = DateTime.now();
  static double smallerSide = 100;
  static String _valueEnterKey = "";
  static String _timeValueText = "";

  static List<Widget> getChildren(
      BuildContext context,
      String? defaultKey,
      List<PopupMenuItem> keys,
      Map<String, DataContainer> data,
      StateSetter setState) {
    List<Widget> children = [];
    children.add(getKeysPopupButton(keys, data, setState, defaultKey));
    children.add(getDataInputWidget(context, setState, data));
    children.add(getNoteEdit());
    return children;
  }

  static TextField getNoteEdit() {
    return TextField(
      decoration: const InputDecoration(labelText: "Note"),
      minLines: 2,
      maxLines: 6,
      controller: _noteTextFieldController,
    );
  }

  static Widget getDataInputWidget(BuildContext context, StateSetter setState,
      Map<String, DataContainer> data) {
    bool isTimeAndDate = !data[_valueEnterKey]!.isDateOnly;
    return Row(
      children: [
        Expanded(
            child: PopupMenuButton(
          position: PopupMenuPosition.under,
          iconSize: 15,
          itemBuilder: (BuildContext context) =>
              isTimeAndDate ? timeKeys : dateKeys,
          onSelected: (item) {
            switch (item) {
              case 0:
                {
                  var now = DateTime.now();
                  returnDate = isTimeAndDate ? now : now.getMidnight();
                  setState(() {
                    _timeValueText =
                        DateFormat(DateFormat.YEAR_ABBR_MONTH_DAY).format(now);
                  });
                  break;
                }
              case 1:
                {
                  setState(() {
                    var yesterday =
                        DateTime.now().subtract(const Duration(days: 1));
                    returnDate = yesterday.getMidnight();
                    _timeValueText = DateFormat(DateFormat.YEAR_ABBR_MONTH_DAY)
                        .format(yesterday);
                  });
                  break;
                }
              case 2:
                {
                  showOmniDateTimePicker(
                          context: context,
                          type: isTimeAndDate
                              ? OmniDateTimePickerType.dateAndTime
                              : OmniDateTimePickerType.date)
                      .then((value) {
                    if (value != null) {
                      setState(() {
                        returnDate =
                            isTimeAndDate ? value : value.getMidnight();
                        _timeValueText =
                            DateFormat(DateFormat.YEAR_ABBR_MONTH_DAY)
                                .format(value);
                        if (isTimeAndDate) {
                          _timeValueText += " ";
                          _timeValueText +=
                              DateFormat(DateFormat.HOUR_MINUTE).format(value);
                        }
                      });
                    }
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
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.-]+'))
          ],
          decoration: const InputDecoration(labelText: "Value"),
          controller: _yTextFieldController,
        )),
      ],
    );
  }

  static PopupMenuButton getKeysPopupButton(
      List<PopupMenuItem> keys,
      Map<String, DataContainer> data,
      StateSetter setState,
      String? defaultKey) {
    return PopupMenuButton(
      position: PopupMenuPosition.under,
      iconSize: 15,
      itemBuilder: (BuildContext context) {
        if (defaultKey != null && defaultKey.isNotEmpty) {
          return [
            CustomPopupMenuItem(
              value: keys.isEmpty ? 0 : keys.last.value + 1,
              color: data[defaultKey]!.color,
              child: Text(defaultKey,
                  style: TextStyle(
                      overflow: TextOverflow.ellipsis,
                      //backgroundColor: data[key]!.color,
                      color: contrastColor(data[defaultKey]!.color))),
            )
          ];
        } else {
          return keys;
        }
      },
      onSelected: (item) {
        setState(() {
          _valueEnterKey = (keys[item.hashCode].child as Text).data!;
        });
      },
      child: Container(
          color: data[_valueEnterKey]!.color,
          child: Row(children: [
            Icon(
              Icons.keyboard_double_arrow_down,
              color: contrastColor(data[_valueEnterKey]!.color),
            ),
            Flexible(
                child: Text(
              _valueEnterKey,
              style: TextStyle(
                  overflow: TextOverflow.ellipsis,
                  color: contrastColor(data[_valueEnterKey]!.color)),
            )),
          ])),
    );
  }

  static List<ElevatedButton> getActionButtons(
      BuildContext context, bool enableDelete) {
    List<ElevatedButton> actionButtons = [];
    if (enableDelete) {
      actionButtons.add(ElevatedButton(
        //delete Button
        onPressed: () {
          yesNoQuestion(context, "Delete data point?").then((value) {
            if (value) {
              var categoryKey = _valueEnterKey;
              _valueEnterKey = "";
              _yTextFieldController.text.isEmpty
                  ? Navigator.pop(context)
                  : Navigator.pop(
                      context,
                      DataDialogReturn(
                          category: categoryKey,
                          data: Data(
                              first: DataInputDialog.returnDate,
                              second: double.parse(_yTextFieldController.text),
                              note: _noteTextFieldController.text),
                          delete: true));
            }
          });
        },
        style: ElevatedButton.styleFrom(
          primary: Colors.red.shade300,
        ),
        child: const Text("Delete"),
      ));
    }
    actionButtons.addAll([
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
                            first: DataInputDialog.returnDate,
                            second: double.parse(_yTextFieldController.text),
                            note: _noteTextFieldController.text)));
          }),
    ]);
    return actionButtons;
  }

  DataInputDialog(BuildContext context, List<PopupMenuItem> keys,
      Map<String, DataContainer> data, String? defaultKey, bool enableDelete)
      : super(
          content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return SizedBox(
                height: smallerSide,
                child: Column(
                  children:
                      getChildren(context, defaultKey, keys, data, setState),
                ));
          }),
          actions: getActionButtons(context, enableDelete),
        );
}

Future<DataDialogReturn?> showDataInputDialog(BuildContext context,
    Map<String, DataContainer> data, List<String> selectedKeys,
    {DateTime? date,
    double? value,
    String? note,
    String? defaultKey,
    bool enableDelete = false}) async {
  DataInputDialog._yTextFieldController.text = value != null ? "$value" : "";
  DataInputDialog._noteTextFieldController.text = note ?? "";
  DataInputDialog.returnDate = date ?? DateTime.now();
  DataInputDialog.smallerSide = min(MediaQuery.of(context).size.width,
          MediaQuery.of(context).size.height) /
      2;

  List<PopupMenuItem> keys = [];
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
  if (!data.keys.contains(DataInputDialog._valueEnterKey)) {
    if (selectedKeys.isEmpty) {
      DataInputDialog._valueEnterKey = data.keys.first;
    } else if (defaultKey != null && data.keys.contains(defaultKey)) {
      DataInputDialog._valueEnterKey = defaultKey;
    } else {
      DataInputDialog._valueEnterKey = selectedKeys.last;
    }
  }
  bool isTimeAndDate = !data[DataInputDialog._valueEnterKey]!.isDateOnly;
  String defaultText = isTimeAndDate ? "Now" : "Today";
  DataInputDialog._timeValueText = date == null
      ? defaultText
      : DateFormat(DateFormat.YEAR_ABBR_MONTH_DAY).format(date);
  return showDialog(
      context: context,
      builder: (context) {
        return DataInputDialog(context, keys, data, defaultKey, enableDelete);
      });
}

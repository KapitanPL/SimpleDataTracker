import 'dart:math';

import 'package:flutter/material.dart';

import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import 'package:datatracker/src/dataRecord/data.dart';
import 'package:datatracker/src/widgets/custom_popup_menu_item.dart';
import 'package:datatracker/src/utils/contrast_color.dart';
import 'package:datatracker/src/dialogs/yes_no_question.dart';

import 'package:datatracker/src/utils/time_utils.dart';

final _yTextFieldController = TextEditingController();
String _valueEnterKey = "";
String _timeValueText = "";

Future<DataDialogReturn?> showDataInputDialog(BuildContext context,
    Map<String, DataContainer> data, List<String> selectedKeys,
    {DateTime? date, double? value, bool enableDelete = false}) async {
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
  var actionButtons = <Widget>[];
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
                            first: returnDate,
                            second: double.parse(_yTextFieldController.text)),
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
  actionButtons.addAll(<Widget>[
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
                          second: double.parse(_yTextFieldController.text))));
        }),
  ]);
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
                              color: contrastColor(data[_valueEnterKey]!.color),
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
                                                        child: const Text("OK"),
                                                        onPressed: () {
                                                          var theDate =
                                                              DateTime(
                                                                  localDateValue
                                                                      .year,
                                                                  localDateValue
                                                                      .month,
                                                                  localDateValue
                                                                      .day);
                                                          setState(() {
                                                            returnDate = theDate
                                                                .getMidnight();
                                                            _timeValueText =
                                                                DateFormat(DateFormat
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
                          decoration: const InputDecoration(labelText: "Value"),
                          controller: _yTextFieldController,
                        )),
                      ],
                    )
                  ],
                ));
          }),
          actions: actionButtons,
        );
      });
}

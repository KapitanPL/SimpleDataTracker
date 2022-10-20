import 'package:flutter/material.dart';

import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:intl/intl.dart';

import 'package:datatracker/src/utils/time_utils.dart';

class DateTimeDialogReturn {
  DateTimeDialogReturn(this.dateTime, this.timeValueText);
  DateTime dateTime;
  String timeValueText;
}

class DateTimeDialog extends AlertDialog {
  static double smallerSide = 100;
  static DateTime localDateValue = DateTime.now();

  DateTimeDialog(
    Key? key,
    BuildContext context,
  ) : super(
            key: key,
            title: const Text(''),
            content: SizedBox(
              height: smallerSide + 100,
              child: Column(
                children: <Widget>[
                  SizedBox(
                      width: smallerSide,
                      height: smallerSide,
                      child: Card(
                          child: SfDateRangePicker(
                        view: DateRangePickerView.month,
                        selectionMode: DateRangePickerSelectionMode.single,
                        onSelectionChanged:
                            ((dateRangePickerSelectionChangedArgs) {
                          localDateValue =
                              dateRangePickerSelectionChangedArgs.value;
                        }),
                      ))),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        child: const Text("OK"),
                        onPressed: () {
                          var theDate = DateTime(localDateValue.year,
                              localDateValue.month, localDateValue.day);
                          Navigator.pop(
                              context,
                              DateTimeDialogReturn(
                                  theDate.getMidnight(),
                                  DateFormat(DateFormat.YEAR_ABBR_MONTH_DAY)
                                      .format(theDate)));
                        },
                      ),
                      ElevatedButton(
                        child: const Text("Cancel"),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      )
                    ],
                  )
                ],
              ),
            ));
}

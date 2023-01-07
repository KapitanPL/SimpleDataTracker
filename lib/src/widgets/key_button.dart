import 'package:datatracker/src/widgets/long_press_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/contrast_color.dart';
import '../utils/time_utils.dart';

import '../../main.dart';

ElevatedButton createKeyButton(
    String key, BuildContext context, DataTrackerState state) {
  Color textColor = contrastColor(state.data[key]!.color);
  final lastValueFieldController = TextEditingController();
  lastValueFieldController.text = state.data[key]!.data.isEmpty
      ? ""
      : state.data[key]!.data.last.second.toString();
  return ElevatedButton(
      style: ElevatedButton.styleFrom(
          primary: state.data[key]!.color,
          minimumSize: const Size(0, 30),
          maximumSize: Size(MediaQuery.of(context).size.width - 15, 30),
          elevation: state.selectedKeys.contains(key) ? 10 : 0,
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2)),
      onPressed: () => state.keyValuePressed(key),
      child: LongPressWrapper(
        context: context,
        tapCallback: () => state.keyValuePressed(key),
        pressCallback: (() {
          state.editKey(key);
        }),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
                width: 40,
                child: TextField(
                  style: TextStyle(color: textColor),
                  decoration: null,
                  textAlignVertical: TextAlignVertical.bottom,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.-]+'))
                  ],
                  controller: lastValueFieldController,
                  onSubmitted: (value) {
                    double? parsedValue =
                        double.tryParse(lastValueFieldController.text);
                    if (parsedValue == null) return;
                    state.updateData(
                        key,
                        state.data[key]!.data.isEmpty
                            ? 0
                            : state.data[key]!.data
                                .indexOf(state.data[key]!.data.last),
                        state.data[key]!.data.isEmpty
                            ? DateTime.now().getMidnight()
                            : state.data[key]!.data.last.first,
                        parsedValue!,
                        state.data[key]!.data.isEmpty
                            ? ""
                            : state.data[key]!.data.last.note);
                  },
                )),
            Flexible(
                child: Text(key,
                    style: TextStyle(
                      overflow: TextOverflow.ellipsis,
                      color: textColor,
                      fontWeight: state.selectedKeys.contains(key)
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: state.selectedKeys.contains(key) ? 20 : 12,
                    ))),
          ],
        ),
      ));
}

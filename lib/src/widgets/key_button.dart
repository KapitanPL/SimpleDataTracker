import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/contrast_color.dart';

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
          elevation: state.selectedKeys.contains(key) ? 10 : 0),
      onPressed: () => state.keyValuePressed(key),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
              width: 50,
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
                  state.updateData(
                      key,
                      state.data[key]!.data.indexOf(state.data[key]!.data.last),
                      state.data[key]!.data.last.first,
                      double.parse(lastValueFieldController.text));
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
                    state.editKey(key);
                    break;
                  }
                case 1: //Delete
                  {
                    state.deleteKey(key);
                    break;
                  }
              }
            },
            icon: Icon(Icons.menu, color: textColor), //dropdown indicator icon
          )
        ],
      ));
}

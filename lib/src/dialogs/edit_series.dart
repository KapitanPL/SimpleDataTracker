import 'package:flutter/material.dart';

import 'package:flutter_circle_color_picker/flutter_circle_color_picker.dart';

import 'package:datatracker/src/dataRecord/data.dart';

final _textFieldController = TextEditingController();
final _descriptionFieldController = TextEditingController();
final _colorController = CircleColorPickerController(
  initialColor: Colors.blue,
);

String? _errorKeyText(Map<String, DataContainer> data) {
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

Future<DataContainer?> editSeries(
    BuildContext context, Map<String, DataContainer> data,
    {DataContainer? defaultValue}) async {
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
                      labelText: (defaultValue != null)
                          ? "Data series name"
                          : 'New data series:',
                      errorText: (defaultValue != null &&
                              _textFieldController.text == defaultValue.name)
                          ? ""
                          : _errorKeyText(data),
                    ),
                    controller: _textFieldController,
                  ),
                  CircleColorPicker(
                    controller: _colorController,
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: "Description"),
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

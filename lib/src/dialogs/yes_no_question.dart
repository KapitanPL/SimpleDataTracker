import 'package:flutter/material.dart';

Future<bool> yesNoQuestion(BuildContext context, String question) async {
  bool result = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Question'),
          content: Text(question),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true)
                    .pop(false); // dismisses only the dialog and returns false
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

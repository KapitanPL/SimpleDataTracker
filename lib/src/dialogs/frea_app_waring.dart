import 'package:flutter/material.dart';

Future<void> freeAppWarning(BuildContext context, String explanation) async {
  return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pro version?'),
          content: ConstrainedBox(
              constraints: BoxConstraints(
                  minHeight: 0,
                  maxHeight: MediaQuery.of(context).size.height / 3),
              child: Column(
                children: [
                  Text(explanation),
                  const SizedBox(
                    height: 20,
                  ),
                  const Text("To allow more, go PRO!")
                ],
              )),
          actions: <Widget>[
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                },
                child: const Text("Ok")),
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                },
                child: const Text("go PRO!"))
          ],
        );
      });
}

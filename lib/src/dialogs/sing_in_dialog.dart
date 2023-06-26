import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/authentication.dart';

void showError(BuildContext context, String message) {
  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sign In ERROR'),
          content: Text(message),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true)
                    .pop(); // dismisses only the dialog and returns false
              },
              child: const Text('Close'),
            ),
          ],
        );
      });
}

Future<User?> signInDialog(BuildContext context) async {
  User? result = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Sign In: $dialogCount'),
          content: SizedBox(
              height: 50,
              child: SignInButton(
                Buttons.Google,
                onPressed: () {
                  Authentication.signInWithGoogle(
                          (errorString) => showError(context, errorString))
                      .then((value) {
                    Navigator.of(context, rootNavigator: true).pop(value);
                  });
                },
              )),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true)
                    .pop(); // dismisses only the dialog and returns false
              },
              child: const Text('Use Offline'),
            ),
          ],
        );
      });
  return result;
}

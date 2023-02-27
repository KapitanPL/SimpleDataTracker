import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/authentication.dart';

Future<User?> signInDialog(BuildContext context) async {
  User? result = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sign In'),
          content: SizedBox(
              height: 50,
              child: SignInButton(
                Buttons.Google,
                onPressed: () {
                  Authentication.signInWithGoogle().then((value) =>
                      Navigator.of(context, rootNavigator: true).pop(value));
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

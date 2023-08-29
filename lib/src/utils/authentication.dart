import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/src/services/message_codec.dart';

import "dart:io";

typedef ErrorCallback = void Function(String error);

class Authentication {
  static User? loggedInUser() {
    return FirebaseAuth.instance.currentUser;
  }

  static void logout() {
    FirebaseAuth.instance.signOut();
  }

  static Future<User?> signInWithGoogle(ErrorCallback onError) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user;

    final GoogleSignIn googleSignIn = GoogleSignIn();

    try {
      await googleSignIn.disconnect().timeout(const Duration(seconds: 10));
    } on PlatformException catch (e) {
      onError(e.toString());
    }

    final GoogleSignInAccount? googleSignInAccount = await googleSignIn
        .signIn()
        .timeout(const Duration(seconds: 10))
        .onError((error, stackTrace) {
      onError(error.toString());
      return null;
    });

    if (googleSignInAccount != null) {
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication
              .timeout(const Duration(seconds: 10));

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      try {
        final UserCredential userCredential = await auth
            .signInWithCredential(credential)
            .timeout(const Duration(seconds: 10));

        user = userCredential.user;
      } on FirebaseException catch (e) {
        onError(e.toString());
      }
    } else {
      onError("googleSignInAccount is null!");
    }

    return user;
  }
}

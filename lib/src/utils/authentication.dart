import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import "dart:io";

class Authentication {
  static User? loggedInUser() {
    return FirebaseAuth.instance.currentUser;
  }

  static void logout() {
    FirebaseAuth.instance.signOut();
  }

  static Future<User?> signInWithGoogle() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user;

    final GoogleSignIn googleSignIn = GoogleSignIn();

    final GoogleSignInAccount? googleSignInAccount =
        await googleSignIn.signIn();

    if (googleSignInAccount != null) {
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      try {
        final UserCredential userCredential =
            await auth.signInWithCredential(credential);

        user = userCredential.user;
      } on FirebaseException catch (e) {
        if (e.code == 'account-exists-with-different-credential') {
          print(e.code);
        } else if (e.code == 'invalid-credential') {
          print(e.code);
        } else {
          print(e);
        }
      }
    }

    return user;
  }
}

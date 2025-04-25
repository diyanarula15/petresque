
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:petlove/screens/home_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:petlove/models/User_model.dart';

class Authentication {
  static Future<FirebaseApp> initializeFirebase({
    required BuildContext context,
  }) async {
    // Print statement added for debugging initialization
    print('DEBUG: Initializing Firebase...');
    FirebaseApp firebaseApp = await Firebase.initializeApp();
    print('DEBUG: Firebase Initialized.');

    User? user = FirebaseAuth.instance.currentUser;
    UserModel? fireuser = UserModel();

    if (user != null) {
      // Print statement added for debugging existing user check
      print('DEBUG: User already signed in (UID: ${user.uid}). Fetching Firestore data...');
      try {
        DocumentSnapshot variable = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        print('DEBUG: Firestore data fetched for existing user.');
        Map<String, dynamic> data = variable.data()! as Map<String, dynamic>;
        fireuser.displayName = data['displayName'];
        fireuser.uid = data['uid'];
        fireuser.email = data['email'];
        fireuser.photoURL = data['photoURL'];
        fireuser.ngo_uid = data['ngo_uid'];

        // Print statement added before navigation
        print('DEBUG: Navigating to HomePage for existing user.');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomePage(
              user: fireuser,
            ),
          ),
        );
      } catch (e) {
        print('DEBUG: Error fetching Firestore data for existing user: $e');
      }
    } else {
      print('DEBUG: No user currently signed in during initialization.');
    }

    return firebaseApp;
  }

  static Future<UserModel?> signInWithGoogle(
      {required BuildContext context}) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user; // Firebase Auth User
    UserModel fireuser = UserModel(); // Your custom user model
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    print('DEBUG: Starting signInWithGoogle...'); // Step 1

    if (kIsWeb) {
      // Web-specific logic (omitted print statements for brevity, assuming mobile focus)
      GoogleAuthProvider authProvider = GoogleAuthProvider();
      try {
        print('DEBUG: [Web] Attempting signInWithPopup...');
        UserCredential userCredential =
            await auth.signInWithPopup(authProvider);
        user = userCredential.user;
        print('DEBUG: [Web] signInWithPopup successful.');
        // Add Firestore logic for web if needed
      } catch (e) {
        print('DEBUG: [Web] Error during signInWithPopup: $e');
      }
    } else {
      // Mobile logic
      final GoogleSignIn googleSignIn = GoogleSignIn();

      print('DEBUG: [Mobile] Step 1: Calling googleSignIn.signIn()');
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();
      print('DEBUG: [Mobile] Step 2: googleSignIn.signIn() completed.');

      if (googleSignInAccount != null) {
        print('DEBUG: [Mobile] Step 3: GoogleSignInAccount received (Name: ${googleSignInAccount.displayName}). Getting authentication...');
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;
        print('DEBUG: [Mobile] Step 4: GoogleSignInAuthentication received.');

        print('DEBUG: [Mobile] Step 5: Creating GoogleAuthProvider credential...');
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );
        print('DEBUG: [Mobile] Step 6: Credential created.');

        try {
          print('DEBUG: [Mobile] Step 7: Calling auth.signInWithCredential...');
          final UserCredential userCredential =
              await auth.signInWithCredential(credential);
          user = userCredential.user; // Assign the Firebase user
          print('DEBUG: [Mobile] Step 8: auth.signInWithCredential successful. User UID: ${user?.uid}');

          // --- Firestore Interaction ---
          if (user != null) {
             print('DEBUG: [Mobile] Step 9: Checking if user exists in Firestore...');
             // Note: The original code had two reads here. Combining for efficiency.
             DocumentSnapshot userDoc = await _firestore
                 .collection('users')
                 .doc(user.uid)
                 .get();
             print('DEBUG: [Mobile] Step 10: Firestore document read attempt completed.');

             if (!userDoc.exists) {
               print('DEBUG: [Mobile] Step 11a: User NOT found in Firestore. Creating new document...');
               await _firestore
                   .collection('users')
                   .doc(user.uid)
                   .set({
                 'displayName': user.displayName,
                 'uid': user.uid,
                 'email': user.email,
                 'photoURL': user.photoURL,
                 'ngo_uid': null,
               });
               print('DEBUG: [Mobile] Step 12a: New user document created in Firestore.');
               // Populate fireuser for returning
               fireuser.displayName = user.displayName;
               fireuser.uid = user.uid;
               fireuser.email = user.email;
               fireuser.photoURL = user.photoURL;
               fireuser.ngo_uid = null;
             } else {
               print('DEBUG: [Mobile] Step 11b: User found in Firestore. Reading data...');
               Map<String, dynamic> data =
                   userDoc.data()! as Map<String, dynamic>;
               // Populate fireuser for returning
               fireuser.displayName = data['displayName'];
               fireuser.uid = data['uid'];
               fireuser.email = data['email'];
               fireuser.photoURL = data['photoURL'];
               fireuser.ngo_uid = data['ngo_uid'];
               print('DEBUG: [Mobile] Step 12b: Existing user data read from Firestore.');
             }
          } else {
             print('DEBUG: [Mobile] ERROR: userCredential.user was null after successful sign-in.');
          }
          // --- End Firestore Interaction ---

        } on FirebaseAuthException catch (e) {
          // Print specific Firebase Auth errors
          print('DEBUG: [Mobile] FirebaseAuthException during signInWithCredential: ${e.code} - ${e.message}');
          if (e.code == 'account-exists-with-different-credential') {
            ScaffoldMessenger.of(context).showSnackBar(
              Authentication.customSnackBar(
                content:
                    'The account already exists with a different credential.',
              ),
            );
          } else if (e.code == 'invalid-credential') {
            ScaffoldMessenger.of(context).showSnackBar(
              Authentication.customSnackBar(
                content:
                    'Error occurred while accessing credentials. Try again.',
              ),
            );
          } else {
             // Catch other Firebase exceptions
             ScaffoldMessenger.of(context).showSnackBar(
              Authentication.customSnackBar(
                content:
                    'Firebase Auth Error: ${e.code}',
              ),
            );
          }
        } catch (e) {
          // Print generic errors
          print('DEBUG: [Mobile] Generic Exception during sign-in/Firestore steps: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            Authentication.customSnackBar(
              content: 'Error occurred using Google Sign-In. Try again. Details: $e',
            ),
          );
        }
      } else {
         print('DEBUG: [Mobile] googleSignIn.signIn() returned null (User likely cancelled).');
      }
    }

    // Ensure fireuser has UID before returning, otherwise return null
    if (fireuser.uid != null) {
       print('DEBUG: signInWithGoogle finished successfully. Returning UserModel for UID: ${fireuser.uid}');
       return fireuser;
    } else {
       print('DEBUG: signInWithGoogle finished, but UserModel could not be populated. Returning null.');
       return null; // Return null if sign-in failed or user wasn't processed correctly
    }
  }

  static SnackBar customSnackBar({required String content}) {
    return SnackBar(
      backgroundColor: Colors.black,
      content: Text(
        content,
        style: const TextStyle(color: Colors.redAccent, letterSpacing: 0.5),
      ),
    );
  }

  static Future<void> signOut({required BuildContext context}) async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    print('DEBUG: Attempting sign out...');
    try {
      if (!kIsWeb) {
        print('DEBUG: Signing out from GoogleSignIn...');
        await googleSignIn.signOut();
        print('DEBUG: GoogleSignIn sign out successful.');
      }
      print('DEBUG: Signing out from FirebaseAuth...');
      await FirebaseAuth.instance.signOut();
      print('DEBUG: FirebaseAuth sign out successful.');
    } catch (e) {
      print('DEBUG: Error during sign out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        Authentication.customSnackBar(
          content: 'Error signing out. Try again.',
        ),
      );
    }
  }
} // Removed extra closing brace that was in the fetched file

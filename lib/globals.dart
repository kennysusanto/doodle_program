library doodle.globals;

import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';

int numRounds = 3;
int timerTime = 20;
Color themeColor = const Color.fromARGB(255, 40, 223, 153);
Color themeColorDarker = const Color.fromARGB(255, 0, 183, 113);
Color bgColor = const Color.fromARGB(255, 246, 247, 212);
double borderRad = 18.0;
double buttonPad = 15.0;
double buttonFontSize = 24;
Map<String, String> det = {
  'apiKey': "AIzaSyAeUgJdJv2hn_oD2EGr_sSDa1jswltX3UQ",
  'authDomain': "doodle-d5abb.firebaseapp.com",
  'databaseURL': "https://doodle-d5abb-default-rtdb.firebaseio.com",
  'projectId': "doodle-d5abb",
  'storageBucket': "doodle-d5abb.appspot.com",
  'messagingSenderId': "658846392651",
  'appId': "1:658846392651:web:9e988a933c3bb8be8cc8ce",
  'measurementId': "G-G2L8CWXVZ0"
};
FirebaseOptions firebaseConfig = FirebaseOptions(
    apiKey: det['apiKey']!,
    appId: det['appId']!,
    messagingSenderId: det['messagingSenderId']!,
    projectId: det['projectId']!,
    databaseURL: det['databaseURL']!,
    authDomain: det['authDomain']!);

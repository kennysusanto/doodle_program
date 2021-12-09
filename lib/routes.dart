import 'package:doodle/keywords.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:doodle/main.dart';
import 'package:doodle/doodle.dart';
import 'package:doodle/settings.dart';
import 'package:doodle/correct.dart';
import 'package:doodle/doodle_handler.dart';
import 'package:doodle/prevdoodles.dart';

class DoodlePageRoute extends CupertinoPageRoute {
  String keyword;
  DoodlePageRoute({required this.keyword})
      : super(builder: (BuildContext context) => DoodlePage(keyword: keyword));

  // OPTIONAL IF YOU WISH TO HAVE SOME EXTRA ANIMATION WHILE ROUTING
  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return FadeTransition(
        opacity: animation, child: DoodlePage(keyword: keyword));
  }
}

class SettingsPageRoute extends CupertinoPageRoute {
  SettingsPageRoute()
      : super(builder: (BuildContext context) => const SettingsPage());

  // OPTIONAL IF YOU WISH TO HAVE SOME EXTRA ANIMATION WHILE ROUTING
  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return FadeTransition(opacity: animation, child: const SettingsPage());
  }
}

class MainMenuRoute extends CupertinoPageRoute {
  late FirebaseApp fbapp;
  MainMenuRoute({required this.fbapp})
      : super(builder: (BuildContext context) => MainMenu(fbapp: fbapp));

  // OPTIONAL IF YOU WISH TO HAVE SOME EXTRA ANIMATION WHILE ROUTING
  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return FadeTransition(opacity: animation, child: MainMenu(fbapp: fbapp));
  }
}

class DoodleHandlerRoute extends CupertinoPageRoute {
  late FirebaseApp fbapp;
  DoodleHandlerRoute({required this.fbapp})
      : super(builder: (BuildContext context) => DoodleHandler(fbapp: fbapp));

  // OPTIONAL IF YOU WISH TO HAVE SOME EXTRA ANIMATION WHILE ROUTING
  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return FadeTransition(
        opacity: animation, child: DoodleHandler(fbapp: fbapp));
  }
}

class KeywordsPageRoute extends CupertinoPageRoute {
  KeywordsPageRoute()
      : super(builder: (BuildContext context) => const KeywordsPage());

  // OPTIONAL IF YOU WISH TO HAVE SOME EXTRA ANIMATION WHILE ROUTING
  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return FadeTransition(opacity: animation, child: const KeywordsPage());
  }
}

class CorrectPageRoute extends CupertinoPageRoute {
  final String akeyword;
  final List astrokes;
  final num atimetaken;
  CorrectPageRoute(
      {required this.akeyword,
      required this.astrokes,
      required this.atimetaken})
      : super(
            builder: (BuildContext context) => CorrectPage(
                keyword: akeyword, strokes: astrokes, timeTaken: atimetaken));

  // OPTIONAL IF YOU WISH TO HAVE SOME EXTRA ANIMATION WHILE ROUTING
  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return FadeTransition(
        opacity: animation,
        child: CorrectPage(
            keyword: akeyword, strokes: astrokes, timeTaken: atimetaken));
  }
}

class PreviousDoodlesRoute extends CupertinoPageRoute {
  PreviousDoodlesRoute()
      : super(builder: (BuildContext context) => const PreviousDoodlesPage());

  // OPTIONAL IF YOU WISH TO HAVE SOME EXTRA ANIMATION WHILE ROUTING
  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return FadeTransition(
        opacity: animation, child: const PreviousDoodlesPage());
  }
}

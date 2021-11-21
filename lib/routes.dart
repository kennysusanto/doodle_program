import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'main.dart';
import 'doodle.dart';
import 'settings.dart';
import 'sketcher.dart';
import 'doodle_handler.dart';

class DoodlePageRoute extends CupertinoPageRoute {
  List keywordsa = ['a'];
  List labelsa = ['a'];
  List labels2a = ['a'];
  DoodlePageRoute(
      {required this.keywordsa, required this.labelsa, required this.labels2a})
      : super(
            builder: (BuildContext context) => DoodlePage(
                keywords: keywordsa, labels: labelsa, labels2: labels2a));

  // OPTIONAL IF YOU WISH TO HAVE SOME EXTRA ANIMATION WHILE ROUTING
  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return FadeTransition(
        opacity: animation,
        child: DoodlePage(
            keywords: keywordsa, labels: labelsa, labels2: labels2a));
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
  MainMenuRoute() : super(builder: (BuildContext context) => const MainMenu());

  // OPTIONAL IF YOU WISH TO HAVE SOME EXTRA ANIMATION WHILE ROUTING
  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return FadeTransition(opacity: animation, child: const MainMenu());
  }
}

class DoodleHandlerRoute extends CupertinoPageRoute {
  DoodleHandlerRoute()
      : super(builder: (BuildContext context) => const DoodleHandler());

  // OPTIONAL IF YOU WISH TO HAVE SOME EXTRA ANIMATION WHILE ROUTING
  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return FadeTransition(opacity: animation, child: const DoodleHandler());
  }
}

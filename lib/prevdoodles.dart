import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:doodle/globals.dart' as globals;

class PreviousDoodlesPage extends StatefulWidget {
  const PreviousDoodlesPage({Key? key}) : super(key: key);

  @override
  _PreviousDoodlesPageState createState() => _PreviousDoodlesPageState();
}

class _PreviousDoodlesPageState extends State<PreviousDoodlesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Previous Doodles'),
        ),
        backgroundColor: globals.bgColor,
        // body list view
        body: const Text('Nothing yet...'));
  }
}

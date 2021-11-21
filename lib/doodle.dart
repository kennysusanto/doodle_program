import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:core';
import 'sketcher.dart';
import 'globals.dart' as globals;

class DoodlePage extends StatefulWidget {
  final List keywords;
  final List labels;
  final List labels2;
  const DoodlePage(
      {Key? key,
      required this.keywords,
      required this.labels,
      required this.labels2})
      : super(key: key);

  @override
  _DoodlePageState createState() => _DoodlePageState();
}

class _DoodlePageState extends State<DoodlePage> {
  List strokes = [];
  List stroke = [];
  int c = 0;

  void onPanStart(DragStartDetails details) {
    print('User started drawing');
    final box = context.findRenderObject() as RenderBox;
    final point = box.globalToLocal(details.globalPosition);
    // print(point);

    setState(() {
      // dl.addFirstPoint(point);
      stroke = [];
      stroke.add(point);
      strokes.add(stroke);
    });
  }

  void onPanUpdate(DragUpdateDetails details) {
    final box = context.findRenderObject() as RenderBox;
    final point = box.globalToLocal(details.globalPosition);
    // print(point);

    setState(() {
      // dl.addPoint(point);
      stroke.add(point);
      strokes[c] = stroke;
    });
  }

  void onPanEnd(DragEndDetails details) {
    setState(() {
      print('User ended drawing');
      // print(strokes[c]);
      c += 1;
    });
  }

  void confirmExit() {
    showConfirmExitDialog();
  }

  Future<void> showConfirmExitDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Exit'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('All progress will be lost.'),
                Text('Are you sure to exit?'),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, 'Cancel');
                },
                child: Text('Cancel')),
            ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, 'Confirm');
                  Navigator.of(context).pop();
                },
                child: Text('Confirm')),
          ],
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    confirmExit();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: Scaffold(
          body: Container(
              color: Colors.yellow[100],
              child: Stack(
                children: [
                  GestureDetector(
                    onPanStart: onPanStart,
                    onPanUpdate: onPanUpdate,
                    onPanEnd: onPanEnd,
                    child: RepaintBoundary(
                      child: Container(
                        color: Colors.transparent,
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        // CustomPaint widget will go here
                      ),
                    ),
                  ),
                  CustomPaint(
                    painter: MyCustomPainter(strokes),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Keyword Here'),
                      Container(
                        margin: EdgeInsets.only(left: 10),
                        child: ElevatedButton(
                            onPressed: () {
                              confirmExit();
                            },
                            child: Text('Exit')),
                      ),
                      ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, [true, strokes]);
                          },
                          child: Text('Exit True')),
                      ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, [false, strokes]);
                          },
                          child: Text('Exit False'))
                    ],
                  )
                ],
              )),
        ),
        onWillPop: _onWillPop);
  }
}

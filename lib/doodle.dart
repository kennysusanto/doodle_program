import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:core';
import 'sketcher.dart';
import 'globals.dart' as globals;
import 'package:tflite/tflite.dart';
import 'dart:math';

class DoodlePage extends StatefulWidget {
  final String keyword;
  const DoodlePage({
    Key? key,
    required this.keyword,
  }) : super(key: key);

  @override
  _DoodlePageState createState() => _DoodlePageState();
}

class _DoodlePageState extends State<DoodlePage> {
  List<List<Offset>> strokes = [];
  List<Offset> stroke = [];
  List imageDataInt = List.generate(28 * 28, (_) => []);
  int c = 0;
  late List _outputs;
  late File _image;
  final imSize = 200;
  final imPadding = 40;
  GlobalKey containerKey = GlobalKey();

  @override
  void initState() {
    // TODO: implement initState
    // load tflite model

    super.initState();

    loadModel();
    setState(() {});
  }

  pickImage() async {
    // var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    // if (image == null) return null;
    // setState(() {
    //   _image = image;
    // });
    // classifyImage(image);
  }

  classifyImage(File image) async {
    var output = await Tflite.runModelOnImage(
      path: image.path,
    );
    print("predict = " + output.toString());
    setState(() {
      _outputs = output!;
    });
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/my_tflite_model.tflite",
      labels: "assets/labels.txt",
    );
  }

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

    RenderBox box2 =
        containerKey.currentContext!.findRenderObject() as RenderBox;
    Offset containerPos =
        box2.localToGlobal(Offset.zero); //this is global position
    // print('CONTAINER: ${containerPos.dx}, ${containerPos.dy}');

    setState(() {
      // dl.addPoint(point);
      if (point.dx < containerPos.dx + imSize + (imPadding * 2) &&
          point.dy < containerPos.dy + imSize + (imPadding * 2) &&
          point.dx > containerPos.dx &&
          point.dy > containerPos.dy) {
        // print(point);
        stroke.add(point);
        strokes[c] = stroke;
      }
    });
  }

  void onPanEnd(DragEndDetails details) {
    setState(() {
      print('User ended drawing');
      // print(strokes[c]);

      // normalize strokes to 28x28
      var allPoints = [];
      for (var i = 0; i < strokes.length; i++) {
        List<Offset> stroke = strokes[i];
        for (var j = 0; j < stroke.length; j++) {
          Offset p = stroke[j];
          Offset n = Offset(normalizeValue(p.dx, 1, 28).roundToDouble(),
              normalizeValue(p.dy, 1, 28).roundToDouble());
          // print(n);
          allPoints.add(n);
        }
      }

      print('all points length: ${allPoints.length}');

      for (var i = 0; i < 28; i++) {
        for (var j = 0; j < 28; j++) {
          var n = ((i + 1) * (j + 1)) - 1;
          for (var k = 0; k < allPoints.length; k++) {
            Offset p = allPoints[k];
            if (p.dx == i) {
              imageDataInt[n] = 255;
            }
            if (p.dy == j) {
              imageDataInt[n] = 255;
            }
          }
        }
      }

      print(imageDataInt);

      c += 1;
    });
  }

  void confirmExit() {
    showConfirmExitDialog();
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
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

  double normalizeValue(val, min, max) {
    return (val - min) / (max - min);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: Scaffold(
          body: Container(
              alignment: Alignment.center,
              color: Colors.yellow[100],
              child: Stack(
                children: [
                  GestureDetector(
                      onPanStart: onPanStart,
                      onPanUpdate: onPanUpdate,
                      onPanEnd: onPanEnd,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(widget.keyword),
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
                          ),
                          RepaintBoundary(
                              child: Container(
                            key: containerKey,
                            // color: Colors.transparent,
                            color: Colors.blue.shade100,
                            // width: MediaQuery.of(context).size.width,
                            // height: MediaQuery.of(context).size.height,
                            width: imSize + (imPadding * 2),
                            height: imSize + (imPadding * 2),
                            // CustomPaint widget will go here
                          )),
                        ],
                      )),
                  CustomPaint(
                    painter: MyCustomPainter(strokes),
                  ),
                ],
              )),
        ),
        onWillPop: _onWillPop);
  }
}

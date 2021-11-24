import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:core';
import 'sketcher.dart';
import 'globals.dart' as globals;
import 'package:tflite/tflite.dart';
import 'package:image/image.dart' as im;

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
  List<int> imageDataInt = List.generate(28 * 28, (_) => 0);
  Uint8List imageDataUInt8 = Uint8List(28 * 28);
  int c = 0;
  late List _outputs;
  late File _image;
  final imSize = 200;
  final imPadding = 40;
  final int kCanvasSize = 200;
  final double kCanvasInnerOffset = 40;
  final int kModelInputSize = 28;
  GlobalKey containerKey = GlobalKey();
  GlobalKey repaintBoundaryKey = GlobalKey();
  GlobalKey containerImageKey = GlobalKey();
  Image imGen = const Image(
      image: NetworkImage(
          'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl.jpg'));

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

  Uint8List convertStringToUint8List(String str) {
    final List<int> codeUnits = str.codeUnits;
    final Uint8List unit8List = Uint8List.fromList(codeUnits);

    return unit8List;
  }

  Future<List?> classifyImage(Uint8List imgBin) async {
    List? output = await Tflite.runModelOnBinary(binary: imgBin);
    print("predict = " + output.toString());
    return output;
    // setState(() {
    //   _outputs = output!;
    // });
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
    print('User ended drawing');
    // print(strokes[c]);

    // normalize strokes to 28x28
    // List<Offset> allPoints = [];

    // for (var i = 0; i < strokes.length; i++) {
    //   List<Offset> stroke = strokes[i];
    //   for (var j = 0; j < stroke.length; j++) {
    //     Offset p = Offset(stroke[j].dx, stroke[j].dy - 40);

    //     allPoints.add(p);
    //   }
    // }

    // print('all points length: ${allPoints.length}');

    // for (var i = 0; i < 28; i++) {
    //   for (var j = 0; j < 28; j++) {
    //     var n = ((i + 1) * (j + 1)) - 1;
    //     for (var k = 0; k < allPoints.length; k++) {
    //       Offset p = allPoints[k];
    //       if (p.dx == i) {
    //         imageDataInt[n] = 255;
    //       }
    //       if (p.dy == j) {
    //         imageDataInt[n] = 255;
    //       }
    //     }
    //   }
    // }

    try {
      var a = processCanvasPoints(strokes);
      //for (var i = 0; i < a.length; i++) print('CLASSIFIED AS: ${a[i]}');
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        duration: const Duration(milliseconds: 1000),
      ));
    }

    c += 1;
    setState(() {});
  }

  Future<List?> processCanvasPoints(List<List<Offset>> strokes) async {
    // We create an empty canvas 280x280 pixels
    final canvasSizeWithPadding = kCanvasSize + (2 * kCanvasInnerOffset);
    final canvasOffset = Offset(kCanvasInnerOffset, kCanvasInnerOffset);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromPoints(
        Offset(0.0, 0.0),
        Offset(canvasSizeWithPadding, canvasSizeWithPadding),
      ),
    );

    // Now we draw our list of points on white paint
    // for (int i = 0; i < points.length - 1; i++) {
    //   if (points[i] != null && points[i + 1] != null) {
    //     canvas.drawLine(
    //         points[i], points[i + 1], Paint()..color = Colors.black);
    //   }
    // }

    Path allPaths = Path();
    for (var i = 0; i < strokes.length; i++) {
      List<Offset> stroke = strokes[i];
      for (var j = 0; j < stroke.length; j++) {
        if (j == 0) {
          Offset p = Offset(stroke[j].dx, stroke[j].dy - 40);
          allPaths.moveTo(p.dx, p.dy);
        } else {
          Offset p = Offset(stroke[j].dx, stroke[j].dy - 40);
          allPaths.lineTo(p.dx, p.dy);
        }
      }
    }

    canvas.drawPath(
        allPaths,
        Paint()
          ..color = Colors.black
          ..style = ui.PaintingStyle.stroke);

    // At this point our virtual canvas is ready and we can export an image from it
    final picture = recorder.endRecording();
    final img = await picture.toImage(
      canvasSizeWithPadding.toInt(),
      canvasSizeWithPadding.toInt(),
    );
    final imgBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngUint8List = imgBytes!.buffer.asUint8List();

    // There's quite a funny game at this point. The image class we are using doesn't allow resizing.
    // In order to achieve that, we need to convert it to another image class that we are importing
    // as 'im' from package:image/image.dart
    try {
      im.Image? imImage = im.decodeImage(pngUint8List);
      im.Image resizedImage = im.copyResize(
        imImage!,
        width: kModelInputSize,
        height: kModelInputSize,
      );
    } catch (e) {
      print('ERROR DECODING: $e');
    }

    // Finally, we can return our the prediction we will perform over that
    // resized image
    print(pngUint8List.length);
    imGen = Image.memory(pngUint8List);

    setState(() {});
    Uint8List b = Uint8List(28 * 28 * 4);
    for (var m = 0; m < b.length; m++) {
      if (m < pngUint8List.length) {
        b[m] = pngUint8List[m];
      } else {
        b[m] = 0;
      }
      print(b[m].bitLength);
    }

    return classifyImage(b);
    // return predictImage(resizedImage);
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
                                  child: Text('Exit False')),
                            ],
                          ),
                          Row(
                            children: [
                              RepaintBoundary(
                                  key: repaintBoundaryKey,
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
                              Container(
                                key: containerImageKey,
                                child: imGen,
                              )
                            ],
                          )
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

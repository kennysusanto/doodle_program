import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:doodle/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'dart:core';
import 'sketcher.dart';
import 'globals.dart' as globals;
import 'package:image/image.dart' as im;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart' as pp;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:doodle/test_bit_converter.dart';

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
  List<List<List<dynamic>>> strokes = [];
  List<List<dynamic>> stroke = [];
  List<int> imageDataInt = List.generate(28 * 28, (_) => 0);
  Uint8List imageDataUInt8 = Uint8List(28 * 28);
  int c = 0;
  final imSize = 200;
  final imPadding = 40;
  final int kCanvasSize = 200;
  final double kCanvasInnerOffset = 40;
  final int kModelInputSize = 28;
  GlobalKey containerKey = GlobalKey();
  GlobalKey repaintBoundaryKey = GlobalKey();
  GlobalKey containerImageKey = GlobalKey();
  GlobalKey containerImageKey2 = GlobalKey();
  GlobalKey rowTextKey = GlobalKey();
  String _predkey = '';

  Image imGen = const Image(
      image: NetworkImage(
    'https://pixabay.com/images/id-49520/',
  ));
  Image imGen2 = const Image(
      image: NetworkImage(
    'https://pixabay.com/images/id-49520/',
  ));

  bool imgAva = false;
  late Timer _timer;
  num _start = double.tryParse(globals.timerTime.toString())!;

  // tflite_flutter package & tflite_flutter_helper package

  late Interpreter interpreter;
  late List<int> _inputShape;
  late List<int> _outputShape;

  late TensorImage _inputImage;
  late TensorBuffer _outputBuffer;

  late TfLiteType _inputType;
  late TfLiteType _outputType;

  final String _labelsFileName = 'assets/labels2.txt';

  final int _labelsLength = globals.timerTime;

  late var _probabilityProcessor;

  late List<String> labels;

  String modelName = 'my_tflite_model.tflite';

  NormalizeOp preProcessNormalizeOp = NormalizeOp(0, 1);
  NormalizeOp postProcessNormalizeOp = NormalizeOp(0, 255);

  List preds = [];

  @override
  void initState() {
    // TODO: implement initState
    // load tflite model

    super.initState();
    loadModel();
    loadLabels();
    startTimer();
    setState(() {});
  }

  Widget _displayMedia(Image media) {
    if (imgAva) {
      return media;
    } else {
      return CachedNetworkImage(
        imageUrl: "https://i.imgur.com/0fNdo9h.jpeg",
        placeholder: (context, url) => new CircularProgressIndicator(),
        errorWidget: (context, url, error) => new Icon(Icons.error),
      );
    }
  }

  void startTimer() {
    const durValue = Duration(milliseconds: 100);
    _timer = Timer.periodic(
      durValue,
      (Timer timer) {
        if (_start == 0) {
          setState(() {
            timer.cancel();
          });
          Navigator.pop(context, [false, strokes]);
        } else {
          setState(() {
            _start -= double.tryParse(
                (durValue.inMilliseconds / 1000).toStringAsFixed(3))!;
            _start = num.tryParse(_start.toStringAsFixed(1))!;
          });
        }
      },
    );
  }

  num round(n) {
    num res = n;
    String fixed = n.toStringAsFixed(3);
    int dot = fixed.indexOf('.');
    String charAfterDot = fixed[dot + 1];
    int nCharAfterDot = int.tryParse(charAfterDot)!;
    if (nCharAfterDot >= 5) {
      res += (10 - nCharAfterDot) / 10;
    } else if (nCharAfterDot <= 4) {
      res += (0 - nCharAfterDot) / 10;
    }
    return res;
  }

  // Future<List?> classifyImage(Uint8List imgBin) async {
  //   List? output = await Tflite.runModelOnBinary(binary: imgBin);
  //   print("predict = " + output.toString());
  //   ScaffoldMessenger.of(context).hideCurrentSnackBar();
  //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //     content: Text(output.toString()),
  //     duration: const Duration(milliseconds: 1000),
  //   ));
  //   return output;
  // }

  // Future<List?> classifyImage2(String filePath) async {
  //   List? output = await Tflite.runModelOnImage(path: filePath);
  //   print("predict = " + output.toString());
  //   ScaffoldMessenger.of(context).hideCurrentSnackBar();
  //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //     content: Text(output.toString()),
  //     duration: const Duration(milliseconds: 1000),
  //   ));
  //   return output;
  // }

  Future<void> loadLabels() async {
    labels = await FileUtil.loadLabels(_labelsFileName);
    if (labels.length == _labelsLength) {
      print('Labels loaded successfully');
    } else {
      print('Unable to load labels');
    }
  }

  void loadModel() async {
    try {
      interpreter = await Interpreter.fromAsset('my_tflite_model.tflite');
      print('Interpreter Created Successfully');

      _inputShape = interpreter.getInputTensor(0).shape;
      _outputShape = interpreter.getOutputTensor(0).shape;
      // _inputType = interpreter.getInputTensor(0).type;
      // _outputType = interpreter.getOutputTensor(0).type;
      _inputType = TfLiteType.uint8;
      _outputType = TfLiteType.uint8;

      print('$_inputShape $_outputShape $_inputType $_outputType');

      _outputBuffer = TensorBuffer.createFixedSize(_outputShape, _outputType);
      _probabilityProcessor =
          TensorProcessorBuilder().add(postProcessNormalizeOp).build();
    } catch (e) {
      print('Unable to create interpreter, Caught Exception: ${e.toString()}');
    }
    // await Tflite.loadModel(
    //   model: "assets/my_tflite_model.tflite",
    //   labels: "assets/labels2.txt",
    // );
  }

  TensorImage _preProcess() {
    int cropSize = min(_inputImage.height, _inputImage.width);
    return ImageProcessorBuilder()
        .add(ResizeWithCropOrPadOp(cropSize, cropSize))
        .add(ResizeOp(
            _inputShape[1], _inputShape[2], ResizeMethod.NEAREST_NEIGHBOUR))
        .add(preProcessNormalizeOp)
        .build()
        .process(_inputImage);
  }

  Future<Category?> predict(im.Image image, File fileIM) async {
    final pres = DateTime.now().millisecondsSinceEpoch;
    _inputImage = TensorImage(_inputType);
    // _inputImage.loadImage(image); ini main

    // Directory? docsDir = await pp.getExternalStorageDirectory();
    // File('${docsDir!.path}/b.png').writeAsBytes(im.encodePng(image));
    // var img = File('${docsDir.path}/b.png');
    // im.Image a = im.decodePng(img.readAsBytesSync())!;
    // print('a channels: ${image.channels}');
    // print('a data: ${image.data}');
    // print('a data length: ${image.data.length}');
    // print('a length in bytes: ${image.getBytes().lengthInBytes}');
    _inputImage.loadImage(image);
    // print(_inputImage.buffer.asFloat32List().length);
    // print(_inputImage.buffer.asFloat32List().lengthInBytes);
    // im.Image? b = im.decodePng(image.getBytes(format: im.Format.rgba));

    // print(
    //     'before preprocess: ${_inputImage.height} ${_inputImage.width} ${_inputImage.buffer.asUint8List().length}');
    _inputImage = _preProcess();
    // print(
    //     'after preprocess: ${_inputImage.height} ${_inputImage.width} ${_inputImage.buffer.asUint8List().length}');
    final pre = DateTime.now().millisecondsSinceEpoch - pres;

    print('Time to load image: $pre ms');

    final runs = DateTime.now().millisecondsSinceEpoch;

    // print('output buffer length: ${_outputBuffer.buffer.lengthInBytes}');
    // print('input tensors: ${interpreter.getInputTensors()}');
    // print('output tensors: ${interpreter.getOutputTensors()}');

    // test

    // ImageProcessor ip = new ImageProcessorBuilder()
    //     .add(ResizeOp(28, 28, ResizeMethod.BILINEAR))
    //     .build();
    // TensorImage ti = TensorImage.fromFile(fileIM);
    // print(ti.buffer.asUint8List().length);
    // TensorImage ti2 = ip.process(ti);
    // print(ti2.buffer.asUint8List().length);
    // TensorBuffer tb =
    //     TensorBuffer.createFixedSize([28, 28, 4], TfLiteType.uint8);
    // tb.loadBuffer(fileIM.readAsBytesSync().buffer);
    // TensorImage ti3 = TensorImage.fromTensorBuffer(tb);
    // print(ti3.buffer.asUint8List().length);

    // end test
    // print('input size: ${_inputImage.buffer.asUint8List().length}');
    // print('output size: ${_outputBuffer.getBuffer().asUint8List().length}');
    // interpreter.run(_inputImage.buffer.asUint8List(), _outputBuffer.getBuffer().asUint8List());

    // Uint8List manadd = Uint8List(kModelInputSize * kModelInputSize * 4);
    // int i = 0;
    // int j = 0;
    // while (i < manadd.length) {
    //   if (i > 0 && (i + 1) % 4 == 0) {
    //     manadd[i] = 255;
    //   } else {
    //     manadd[i] = _inputImage.buffer.asUint8List()[j];
    //     j++;
    //   }
    //   i++;
    // }

    // Uint32List manadd2 = Uint32List(kModelInputSize * kModelInputSize);
    // i = 0;
    // j = 0;
    // while (i < manadd2.length) {
    //   if (i > 0 && (i + 1) % 4 == 0) {
    //     manadd[i] = 255;
    //   } else {
    //     manadd[i] = _inputImage.buffer.asUint8List()[j];
    //     j++;
    //   }
    //   i++;
    // }

    List manadd1 = List.generate(1, (index) => 0);
    List manadd2 = List.generate(kModelInputSize, (index) => 0);
    int i = 0;
    while (i < manadd2.length) {
      int j = 0;
      List manadd3 = List.generate(kModelInputSize, (index) => 0);
      while (j < manadd3.length) {
        List manadd4 = List.generate(1, (index) => 0);
        int ctr = (i + 1) * (j + 1) + 3;
        int a = _inputImage.buffer.asUint8List()[ctr];
        manadd4[0] = a.toDouble();
        manadd3[j] = manadd4;
        j++;
      }
      manadd2[i] = manadd3;
      i++;
    }
    manadd1[0] = manadd2;

    Directory? docsDir = await pp.getExternalStorageDirectory();
    File('${docsDir!.path}/a.txt').writeAsString(
        image.getBytes(format: im.Format.rgba).toList().toString());
    File('${docsDir.path}/b.txt')
        .writeAsString(_inputImage.buffer.asUint32List().toString());
    File('${docsDir.path}/c.txt').writeAsString(manadd1.toString());
    File('${docsDir.path}/da_outputbuffer.txt')
        .writeAsString(_outputBuffer.getBuffer().asUint8List().toString());

    // File('${docsDir.path}/d.txt')
    //     .writeAsString(interpreter.getInputTensors()[0].data.toString());

    TensorBuffer out = TensorBuffer.createFixedSize([1, 20], TfLiteType.uint8);

    interpreter.run(manadd1, out.getBuffer());

    File('${docsDir.path}/db_outbuffer.txt')
        .writeAsString(out.getBuffer().asUint8List().toString());

    final run = DateTime.now().millisecondsSinceEpoch - runs;

    print('Time to run inference: $run ms');

    // Map<String, double> labeledProb = TensorLabel.fromList(
    //         labels, _probabilityProcessor.process(_outputBuffer))
    //     .getMapWithFloatValue();

    Map<String, double> labeledProb =
        TensorLabel.fromList(labels, _probabilityProcessor.process(out))
            .getMapWithFloatValue();

    print(labeledProb);
    // final pred = getTopProbability(labeledProb);
    final pred = getTopProbabilityUnique(labeledProb, preds);
    preds.add(pred.key);
    _predkey = preds.toString();

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${pred.key} (${pred.value})'),
      duration: const Duration(milliseconds: 1000),
    ));
    return Category(pred.key, pred.value);
  }

  void close() {
    interpreter.close();
  }

  MapEntry<String, double> getTopProbability(Map<String, double> labeledProb) {
    var pq = PriorityQueue<MapEntry<String, double>>(compare);
    pq.addAll(labeledProb.entries);

    return pq.first;
  }

  MapEntry<String, double> getTopProbabilityUnique(
      Map<String, double> labeledProb, List preds) {
    var pq = PriorityQueue<MapEntry<String, double>>(compare);
    pq.addAll(labeledProb.entries);
    var res = pq.first;
    while (preds.contains(res.key)) {
      res = pq.removeFirst();
    }

    return res;
  }

  int compare(MapEntry<String, double> e1, MapEntry<String, double> e2) {
    if (e1.value > e2.value) {
      return -1;
    } else if (e1.value == e2.value) {
      return 0;
    } else {
      return 1;
    }
  }

  void _predict(File img) async {
    im.Image imageInput = im.decodeImage(await img.readAsBytes())!;
    print('imageInput: ${imageInput.length}');
    Category? pred = await predict(imageInput, img);
    print('prediction: $pred');
    // print('${pred!.label} ${widget.keyword}');
    if (pred!.label.toString().trim() == widget.keyword.toString().trim()) {
      num timeTaken = _start;
      _timer.cancel();
      await Navigator.of(context).push(CorrectPageRoute(
          akeyword: pred.label.toString(),
          astrokes: strokes,
          atimetaken: timeTaken));
      Navigator.pop(context, [true, strokes]);
    }
    setState(() {});
  }

  void onPanStart(DragStartDetails details) {
    print('User started drawing');
    final box = context.findRenderObject() as RenderBox;
    final point = box.globalToLocal(details.globalPosition);
    // print(point);

    setState(() {
      // dl.addFirstPoint(point);
      stroke = [];
      stroke.add([point, _start]);
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

    setState(() {
      // dl.addPoint(point);
      if (point.dx < containerPos.dx + imSize + (imPadding * 2) &&
          point.dy < containerPos.dy + imSize + (imPadding * 2) &&
          point.dx > containerPos.dx &&
          point.dy > containerPos.dy) {
        // print(point);
        List p = [point, _start];
        stroke.add(p);
        // print('points increased ${strokes.length}, ${stroke.length}');
        strokes[c] = stroke;
      }
    });
  }

  void onPanEnd(DragEndDetails details) {
    print('User ended drawing');

    try {
      var a = processCanvasPoints(strokes);
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

  Future<List?> processCanvasPoints(List<List<List<dynamic>>> strokes) async {
    RenderBox box =
        repaintBoundaryKey.currentContext!.findRenderObject() as RenderBox;
    Offset position = box.localToGlobal(Offset.zero);
    final dxFromLeft = position.dx;
    // final dyFromTop = position.dy;
    // RenderBox boxRowText =
    //     rowTextKey.currentContext!.findRenderObject() as RenderBox;
    // double boxRowTextHeight = boxRowText.size.height;
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

    Path allPaths = Path();
    for (var i = 0; i < strokes.length; i++) {
      List<List<dynamic>> stroke = strokes[i];
      for (var j = 0; j < stroke.length; j++) {
        List<dynamic> strokeSingle = stroke[j];
        Offset strokeOffset = strokeSingle[0];
        double timeStamp = strokeSingle[1];
        if (j == 0) {
          Offset p =
              Offset(strokeOffset.dx, strokeOffset.dy - kCanvasInnerOffset);
          // allPaths.moveTo(p.dx - dxFromLeft, p.dy - boxRowTextHeight);
          allPaths.moveTo(p.dx - dxFromLeft, p.dy);
        } else {
          Offset p =
              Offset(strokeOffset.dx, strokeOffset.dy - kCanvasInnerOffset);
          // allPaths.lineTo(p.dx - dxFromLeft, p.dy - boxRowTextHeight);
          allPaths.lineTo(p.dx - dxFromLeft, p.dy);
        }
      }
    }

    canvas.drawRect(
        Rect.fromPoints(
          Offset(0.0, 0.0),
          Offset(canvasSizeWithPadding, canvasSizeWithPadding),
        ),
        Paint()
          ..color = Colors.black
          ..style = ui.PaintingStyle.fill);

    canvas.drawPath(
        allPaths,
        Paint()
          ..shader = ui.Gradient.linear(
              Offset(0, 0),
              Offset(canvasSizeWithPadding, canvasSizeWithPadding),
              [Colors.white, Colors.grey.shade100])
          // ..color = Colors.white
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 9);

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

    im.Image? imImage = im.decodeImage(pngUint8List);
    im.Image resizedImage = im.copyResize(
      imImage!,
      width: kModelInputSize,
      height: kModelInputSize,
    );

    // algo untuk draw di pixel2 sekitar path dan biarin path nya jadi hitam,
    // ikutin contoh dataset di colab

    // target nya kita manipulasi di resizedImage aja karena sudah di resize jadi 28x28

    im.Image edittedResizedImage = resizedImage;
    List<List<int>> whites = [];
    // list all white pixels
    num u32Black = u8tou32([255, 0, 0, 0]);
    for (var i = 0; i < resizedImage.height; i++) {
      for (var j = 0; j < resizedImage.width; j++) {
        // check if current pixel has color (not black)
        if (resizedImage.getPixel(i, j) > u32Black) {
          List<int> p = [i, j];
          whites.add(p);
        }
      }
    }
    // draw all white pixels to black and surrounding pixels to white
    for (var i = 0; i < whites.length; i++) {
      int x = whites[i][0];
      int y = whites[i][1];
      int a = resizedImage.getPixel(x, y); // get color

      // set the surrounding pixels with the pixel's color
      // set left pixel's color
      setLeftPixel(edittedResizedImage, x, y, a, whites);
      // if (x - 1 >= 0 && resizedImage.getPixel(x - 1, y) < 4294638330) {
      //   edittedResizedImage.setPixel(x - 1, y, a);
      // }
      // set right pixel's color
      setRightPixel(edittedResizedImage, x, y, a, whites);
      // if (x + 1 <= 27 && resizedImage.getPixel(x + 1, y) < 4294638330) {
      //   edittedResizedImage.setPixel(x + 1, y, a);
      // }
      // set above pixel's color
      setAbovePixel(edittedResizedImage, x, y, a, whites);
      // if (y - 1 >= 0 && resizedImage.getPixel(x, y - 1) < 4294638330) {
      //   edittedResizedImage.setPixel(x, y - 1, a);
      // }
      // set below pixel's color
      setBelowPixel(edittedResizedImage, x, y, a, whites);
      // if (y + 1 <= 27 && resizedImage.getPixel(x, y + 1) < 4294638330) {
      //   edittedResizedImage.setPixel(x, y + 1, a);
      // }
      edittedResizedImage.setPixel(x, y, int.parse(u32Black.toString()));
      // 255 0 0 0 = 4278190080 #https://cryptii.com/pipes/integer-converter
      // 255 100 100 100 = 4284769380
      // 255 250 250 250 = 4294638330
      // 255 10 10 10 = 4278848010

    }
    Directory? docsDir = await pp.getExternalStorageDirectory();
    // File('${docsDir!.path}/a.png').writeAsBytes(im.encodePng(resizedImage));
    // File('${docsDir!.path}/a.txt').writeAsString(
    //     (Uint8List.fromList(edittedResizedImage.getBytes(format: im.Format.rgba))
    //         .toString()));
    File('${docsDir!.path}/a.png')
        .writeAsBytes(im.encodePng(edittedResizedImage));

    // Finally, we can return our the prediction we will perform over that
    // resized image
    imGen = Image.memory(pngUint8List);
    var bytes = await File('${docsDir.path}/a.png').readAsBytes();

    imGen2 = Image.memory(bytes);
    setState(() {
      imgAva = true;
    });

    // return classifyImage(imageToByteListUint83(resizedImage, 28));
    // return classifyImage2('${docsDir.path}/a.png');
    // return predictImage(resizedImage);

    _predict(File('${docsDir.path}/a.png'));

    return null;
  }

  bool isPointABorder(List<int> p, List<List<int>> whites) {
    Function deepEq = const DeepCollectionEquality().equals;
    bool exist = false;
    for (var i = 0; i < whites.length; i++) {
      if (deepEq(whites[i], p)) {
        exist = true;
      }
    }
    return exist;
  }

  void setLeftPixel(im.Image ima, int x, int y, int color, List<List<int>> wh) {
    if (x - 1 >= 0 && !isPointABorder([x - 1, y], wh)) {
      // klo overlap brarti darken
      var c = ima.getPixel(x - 1, y);
      if (c > u8tou32([255, 0, 0, 0]) &&
          int.parse((c - u8tou32([255, 20, 20, 20])).toString()) >
              u8tou32([255, 0, 0, 0])) {
        // if not black, darken
        ima.setPixel(
            x - 1, y, int.parse((c - u8tou32([255, 20, 20, 20])).toString()));
      } else {
        // if black, set color
        ima.setPixel(x - 1, y, color);
      }
    }
  }

  void setRightPixel(
      im.Image ima, int x, int y, int color, List<List<int>> wh) {
    if (x + 1 <= 27 && !isPointABorder([x + 1, y], wh)) {
      // klo overlap brarti darken
      var c = ima.getPixel(x + 1, y);
      if (c > u8tou32([255, 0, 0, 0]) &&
          int.parse((c - u8tou32([255, 20, 20, 20])).toString()) >
              u8tou32([255, 0, 0, 0])) {
        // if not black, darken
        ima.setPixel(
            x + 1, y, int.parse((c - u8tou32([255, 20, 20, 20])).toString()));
      } else {
        // if black, set color
        ima.setPixel(x + 1, y, color);
      }
    }
  }

  void setAbovePixel(
      im.Image ima, int x, int y, int color, List<List<int>> wh) {
    if (y - 1 >= 0 && !isPointABorder([x, y - 1], wh)) {
      // klo overlap brarti darken
      var c = ima.getPixel(x, y - 1);
      if (c > u8tou32([255, 0, 0, 0]) &&
          int.parse((c - u8tou32([255, 20, 20, 20])).toString()) >
              u8tou32([255, 0, 0, 0])) {
        // if not black, darken
        ima.setPixel(
            x, y - 1, int.parse((c - u8tou32([255, 20, 20, 20])).toString()));
      } else {
        // if black, set color
        ima.setPixel(x, y - 1, color);
      }
    }
  }

  void setBelowPixel(
      im.Image ima, int x, int y, int color, List<List<int>> wh) {
    if (y + 1 <= 27 && !isPointABorder([x, y + 1], wh)) {
      // klo overlap brarti darken
      var c = ima.getPixel(x, y + 1);
      if (c > u8tou32([255, 0, 0, 0]) &&
          int.parse((c - u8tou32([255, 20, 20, 20])).toString()) >
              u8tou32([255, 0, 0, 0])) {
        // if not black, darken
        ima.setPixel(
            x, y + 1, int.parse((c - u8tou32([255, 20, 20, 20])).toString()));
      } else {
        // if black, set color
        ima.setPixel(x, y + 1, color);
      }
    }
  }

  Uint8List imageToByteListFloat32(
      im.Image image, int inputSize, double mean, double std) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (im.getRed(pixel) - mean) / std;
        buffer[pixelIndex++] = (im.getGreen(pixel) - mean) / std;
        buffer[pixelIndex++] = (im.getBlue(pixel) - mean) / std;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  Uint8List imageToByteListUint8(im.Image image, int inputSize) {
    var convertedBytes = Uint8List(1 * inputSize * inputSize * 4);
    var buffer = Uint8List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = im.getRed(pixel);
        buffer[pixelIndex++] = im.getGreen(pixel);
        buffer[pixelIndex++] = im.getBlue(pixel);
      }
    }
    // print(convertedBytes.buffer.asUint8List().length);
    return convertedBytes.buffer.asUint8List();
  }

  Uint8List imageToByteListUint82(im.Image image, int inputSize) {
    var convertedBytes = Uint8List(1 * inputSize * inputSize * 4);
    var buffer = Uint8List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = im.getRed(pixel);
        buffer[pixelIndex++] = im.getGreen(pixel);
        buffer[pixelIndex++] = im.getBlue(pixel);
      }
    }
    // print(convertedBytes.buffer.asUint8List());
    return convertedBytes.buffer.asUint8List();
  }

  Uint8List imageToByteListUint83(im.Image image, int inputSize) {
    var convertedBytes = Uint8List(1 * inputSize * inputSize * 4);
    var buffer = Uint8List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex] =
            im.getRed(pixel) + im.getBlue(pixel) + im.getGreen(pixel);
      }
    }
    print(convertedBytes.buffer.asUint8List());
    return convertedBytes.buffer.asUint8List();
  }

  void confirmExit() {
    showConfirmExitDialog();
  }

  @override
  void dispose() {
    // closeTflite();
    _timer.cancel();
    super.dispose();
  }

  Future<void> showConfirmExitDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(globals.borderRad)),
          backgroundColor: globals.bgColor,
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
            OutlinedButton(
                style: ButtonStyle(
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(globals.borderRad),
                            side: BorderSide(color: globals.themeColor))),
                    side: MaterialStateProperty.all(
                        BorderSide(color: globals.themeColor))),
                onPressed: () {
                  Navigator.pop(context, 'Cancel');
                },
                child: Container(
                    padding: EdgeInsets.all(globals.buttonPad),
                    child: Text(
                      'Cancel',
                      style: TextStyle(fontSize: globals.buttonFontSize),
                    ))),
            ElevatedButton(
                style: ButtonStyle(
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(globals.borderRad),
                            side: BorderSide(color: globals.themeColor)))),
                onPressed: () {
                  Navigator.pop(context, 'Confirm');
                  Navigator.of(context).pop();
                },
                child: Container(
                    padding: EdgeInsets.all(globals.buttonPad),
                    child: Text(
                      'Confirm',
                      style: TextStyle(fontSize: globals.buttonFontSize),
                    ))),
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
          backgroundColor: globals.bgColor,
          body: Container(
              alignment: Alignment.center,
              child: Stack(
                children: [
                  GestureDetector(
                      onPanStart: onPanStart,
                      onPanUpdate: onPanUpdate,
                      onPanEnd: onPanEnd,
                      child: Column(
                        children: [
                          IntrinsicHeight(
                            child: Stack(
                              children: [
                                Row(
                                    key: rowTextKey,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Align(
                                          child: Text(
                                              'Keyword: ${widget.keyword}',
                                              style: const TextStyle(
                                                  fontSize: 24))),
                                      Align(
                                          child: Text(
                                              'Time: ${_start.toStringAsFixed(1)}'))
                                    ]),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                      style: ButtonStyle(
                                          shape: MaterialStateProperty.all<
                                                  RoundedRectangleBorder>(
                                              RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          globals.borderRad),
                                                  side: BorderSide(
                                                      color: globals
                                                          .themeColor)))),
                                      onPressed: () {
                                        confirmExit();
                                      },
                                      child: Container(
                                          padding:
                                              EdgeInsets.all(globals.buttonPad),
                                          child: Text(
                                            'Exit',
                                            style: TextStyle(
                                                fontSize:
                                                    globals.buttonFontSize),
                                          ))),
                                ),
                                // ElevatedButton(
                                //     onPressed: () {
                                //       Navigator.pop(context, [true, strokes]);
                                //     },
                                //     child: Text('Exit True')),
                                // ElevatedButton(
                                //     onPressed: () {
                                //       Navigator.pop(context, [false, strokes]);
                                //     },
                                //     child: Text('Exit False')),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              RepaintBoundary(
                                  key: repaintBoundaryKey,
                                  child: Container(
                                    key: containerKey,
                                    // color: Colors.transparent,
                                    color: globals.themeColor,
                                    // width: MediaQuery.of(context).size.width,
                                    // height: MediaQuery.of(context).size.height,
                                    width: imSize + (imPadding * 2),
                                    height: imSize + (imPadding * 2),
                                    // CustomPaint widget will go here
                                  )),
                              // SizedBox(
                              //   key: containerImageKey,
                              //   child: FittedBox(
                              //     fit: BoxFit.fill,
                              //     child: _displayMedia(imGen),
                              //   ),
                              //   width: 280,
                              //   height: 280,
                              // ),
                              SizedBox(
                                key: containerImageKey2,
                                child: FittedBox(
                                  fit: BoxFit.fill,
                                  child: _displayMedia(imGen2),
                                ),
                                width: 280,
                                height: 280,
                              ),
                            ],
                          ),
                          Container(
                            child: Text(_predkey),
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

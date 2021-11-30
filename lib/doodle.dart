import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'dart:core';
import 'sketcher.dart';
import 'globals.dart' as globals;
import 'package:tflite/tflite.dart';
import 'package:image/image.dart' as im;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart' as pp;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';
import 'dart:math';
import 'package:collection/collection.dart';

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
  GlobalKey containerImageKey2 = GlobalKey();
  // Image imGen = const Image(
  //     image: NetworkImage(
  //   'https://pixabay.com/images/id-49520/',
  // ));

  Image imGen = const Image(
      image: NetworkImage(
    'https://pixabay.com/images/id-49520/',
  ));
  Image imGen2 = const Image(
      image: NetworkImage(
    'https://pixabay.com/images/id-49520/',
  ));

  bool imgAva = false;

  // tflite_flutter package & tflite_flutter_helper package

  late Interpreter interpreter;
  late List<int> _inputShape;
  late List<int> _outputShape;

  late TensorImage _inputImage;
  late TensorBuffer _outputBuffer;

  late TfLiteType _inputType;
  late TfLiteType _outputType;

  final String _labelsFileName = 'assets/labels2.txt';

  final int _labelsLength = 20;

  late var _probabilityProcessor;

  late List<String> labels;

  String modelName = 'my_tflite_model.tflite';

  NormalizeOp preProcessNormalizeOp = NormalizeOp(0, 1);
  NormalizeOp postProcessNormalizeOp = NormalizeOp(0, 255);

  @override
  void initState() {
    // TODO: implement initState
    // load tflite model

    super.initState();
    loadModel();
    loadLabels();
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

  Future<List?> classifyImage(Uint8List imgBin) async {
    List? output = await Tflite.runModelOnBinary(binary: imgBin);
    print("predict = " + output.toString());
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(output.toString()),
      duration: const Duration(milliseconds: 1000),
    ));
    return output;
  }

  Future<List?> classifyImage2(String filePath) async {
    List? output = await Tflite.runModelOnImage(path: filePath);
    print("predict = " + output.toString());
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(output.toString()),
      duration: const Duration(milliseconds: 1000),
    ));
    return output;
  }

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
      _inputType = interpreter.getInputTensor(0).type;
      _outputType = interpreter.getOutputTensor(0).type;

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

  Category predict(im.Image image) {
    final pres = DateTime.now().millisecondsSinceEpoch;
    _inputImage = TensorImage(_inputType);
    _inputImage.loadImage(image);
    print(
        'before preprocess: ${_inputImage.height} ${_inputImage.width} ${_inputImage.buffer.lengthInBytes}');
    _inputImage = _preProcess();
    print(
        'after preprocess: ${_inputImage.height} ${_inputImage.width} ${_inputImage.buffer.lengthInBytes}');
    final pre = DateTime.now().millisecondsSinceEpoch - pres;

    print('Time to load image: $pre ms');

    final runs = DateTime.now().millisecondsSinceEpoch;

    print('output buffer length: ${_outputBuffer.buffer.lengthInBytes}');

    interpreter.run(_inputImage.buffer, _outputBuffer.getBuffer());
    final run = DateTime.now().millisecondsSinceEpoch - runs;

    print('Time to run inference: $run ms');

    Map<String, double> labeledProb = TensorLabel.fromList(
            labels, _probabilityProcessor.process(_outputBuffer))
        .getMapWithFloatValue();
    final pred = getTopProbability(labeledProb);

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
    im.Image imageInput = im.decodeImage(img.readAsBytesSync())!;
    print('imageInput: ${imageInput.length}');
    var pred = predict(imageInput);
    print('prediction: $pred');

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

  Future<List?> processCanvasPoints(List<List<Offset>> strokes) async {
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
      List<Offset> stroke = strokes[i];
      for (var j = 0; j < stroke.length; j++) {
        if (j == 0) {
          Offset p = Offset(stroke[j].dx, stroke[j].dy - kCanvasInnerOffset);
          allPaths.moveTo(p.dx, p.dy);
        } else {
          Offset p = Offset(stroke[j].dx, stroke[j].dy - kCanvasInnerOffset);
          allPaths.lineTo(p.dx, p.dy);
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
          ..color = Colors.white
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 10);

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

    Directory? docsDir = await pp.getExternalStorageDirectory();
    // print(docsDir!.path);
    File('${docsDir!.path}/a.png').writeAsBytes(im.encodePng(resizedImage));
    // print(im.encodePng(resizedImage));

    // Finally, we can return our the prediction we will perform over that
    // resized image
    imGen = Image.memory(pngUint8List);
    // var a = imageToByteListUint82(resizedImage, 28);
    // var b = Bitmap.fromHeadless(28, 28, a);
    // ui.Image c = await b.buildImage();
    // final d = await c.toByteData(format: ui.ImageByteFormat.png);
    // Uint8List e = d!.buffer.asUint8List();
    var bytes = await File('${docsDir.path}/a.png').readAsBytes();

    imGen2 = Image.memory(bytes);
    // imGen2 = (await decodeImageFromList(a)) as Image;

    // var c = im.decodePng(a);
    // print(a);
    // Image b = Image.memory(imageToByteListUint82(c!, 28));
    // imGen2 = b;
    setState(() {
      imgAva = true;
    });

    // return classifyImage(imageToByteListUint83(resizedImage, 28));
    // return classifyImage2('${docsDir.path}/a.png');
    // return predictImage(resizedImage);

    _predict(File('${docsDir.path}/a.png'));

    return null;
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
                              SizedBox(
                                key: containerImageKey,
                                child: FittedBox(
                                  fit: BoxFit.fill,
                                  child: _displayMedia(imGen),
                                ),
                                width: 280,
                                height: 280,
                              ),
                              SizedBox(
                                key: containerImageKey2,
                                child: FittedBox(
                                  fit: BoxFit.fill,
                                  child: _displayMedia(imGen2),
                                ),
                                width: 140,
                                height: 140,
                              ),
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

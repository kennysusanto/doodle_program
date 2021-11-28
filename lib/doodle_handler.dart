import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:tflite/tflite.dart';
import 'globals.dart' as globals;
import 'routes.dart';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

class DoodleHandler extends StatefulWidget {
  const DoodleHandler({Key? key}) : super(key: key);

  @override
  _DoodleHandlerState createState() => _DoodleHandlerState();
}

class _DoodleHandlerState extends State<DoodleHandler> {
  int numOfRounds = globals.numRounds;
  List corrects = [];
  List wrongs = [];
  List keywords = [];
  List labels = [];
  List labels2 = [];

  void send() async {
    SchedulerBinding.instance!.addPostFrameCallback((_) async {
      // load keywords and h5 model
      // final _downloadsFolder = await getExternalStorageDirectory();
      // final _keywordsFile = File(_downloadsFolder!.path + '/keywords.txt');
      // final _h5ModelFile = File(_downloadsFolder.path + '/my_h5_model.h5');
      // final _tfliteModelFile =
      //     File(_downloadsFolder.path + '/my_tflite_model.tflite');
      // final _labelsFile = File(_downloadsFolder.path + '/labels.txt');
      final _labels2String = await loadLabels2();

      // load txt file strings to list
      // Stream<String> lines = _keywordsFile
      //     .openRead()
      //     .transform(utf8.decoder) // Decode bytes to UTF-8.
      //     .transform(LineSplitter()); // Convert stream to individual lines.
      // try {
      //   await for (var line in lines) {
      //     // print('$line: ${line.length} characters');
      //     keywords.add(line);
      //   }
      //   print('File is now closed.');
      // } catch (e) {
      //   print('Error: $e');
      // }

      // Stream<String> lines2 = _labelsFile
      //     .openRead()
      //     .transform(utf8.decoder) // Decode bytes to UTF-8.
      //     .transform(LineSplitter()); // Convert stream to individual lines.
      // try {
      //   await for (var line in lines2) {
      //     // print('$line: ${line.length} characters');
      //     labels.add(line);
      //   }
      //   print('File is now closed.');
      // } catch (e) {
      //   print('Error: $e');
      // }

      // Stream<String> lines3 = _labels2File
      //     .openRead()
      //     .transform(utf8.decoder) // Decode bytes to UTF-8.
      //     .transform(LineSplitter()); // Convert stream to individual lines.
      // try {
      //   await for (var line in lines3) {
      //     // print('$line: ${line.length} characters');
      //     labels2.add(line);
      //   }
      //   print('File is now closed.');
      // } catch (e) {
      //   print('Error: $e');
      // }

      // print('Labels 2: ${_labels2String}');
      final _labels2List = _labels2String.split("\n");
      // print('Labels 2 ${_labels2List.length}');

      // select random keywords for n rounds
      var rng = new Random();
      Set<int> rnglist = {};
      // print(rnglist.length);
      while (rnglist.length < numOfRounds) {
        rnglist.add(rng.nextInt(_labels2List
            .length)); // still using the trained keywords, not full keywords
        // print(rnglist.toList()[rnglist.length - 1]);
      }

      for (var element in rnglist) {
        print(_labels2List[element]);
      }

      for (int i = 0; i < numOfRounds; i++) {
        final res = await Navigator.of(context)
            .push(DoodlePageRoute(keyword: _labels2List[rnglist.toList()[i]]));
        print(res);
        if (res == null) {
          break;
        }
        if (res[0] == true) {
          corrects.add(res[1]);
        } else if (res[0] == false) {
          wrongs.add(res[1]);
        }
      }
      print('corrects: ${corrects.length} - wrongs: ${wrongs.length}');

      Navigator.of(context).pop();
    });
  }

  Future<String> loadLabels2() async {
    return await rootBundle.loadString('assets/labels2.txt');
  }

  @override
  void initState() {
    super.initState();
    send();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}

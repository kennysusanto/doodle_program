import 'dart:io';
import 'package:path_provider/path_provider.dart' as pp;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
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
  List allStrokes = [];

  void send() async {
    SchedulerBinding.instance!.addPostFrameCallback((_) async {
      final _labels2String = await loadLabels2();
      final _labels2List = _labels2String.split("\n");

      // select random keywords for n rounds
      var rng = new Random();
      Set<int> rnglist = {};
      // print(rnglist.length);
      while (rnglist.length < numOfRounds) {
        rnglist.add(rng.nextInt(_labels2List
            .length)); // still using the trained keywords, not full keywords
      }

      for (var element in rnglist) {
        print(_labels2List[element]);
      }

      for (int i = 0; i < numOfRounds; i++) {
        final res = await Navigator.of(context)
            .push(DoodlePageRoute(keyword: _labels2List[rnglist.toList()[i]]));
        // print(res);
        if (res == null) {
          break;
        }
        if (res[0] == true) {
          corrects.add(res[1]);
        } else if (res[0] == false) {
          wrongs.add(res[1]);
        }
        if (res[1].length > 0) {
          // if there's stroke, if not then dont add
          allStrokes.add(res);
        }
      }
      print('corrects: ${corrects.length} - wrongs: ${wrongs.length}');

      // ini data untuk retrain
      // conform strokes to google dataset format [1, 784] white value 0 to 255
      // ikutin algo di doodle.dart untuk create image
      // todo disini

      // ini data untuk di log
      List whiteStrokes = [];
      for (var i = 0; i < allStrokes.length; i++) {
        List s = allStrokes[i][1][0];
        List px = []; // x
        List py = []; // y
        List pt = []; // time
        for (var j = 0; j < s.length; j++) {
          List s2 = s[j];
          Offset sOffset = s2[0];
          double x = sOffset.dx;
          double y = sOffset.dy;
          double t = double.tryParse(s2[1].toString())!;

          px.add(x);
          py.add(y);
          pt.add(t);
        }
        whiteStrokes.add([px, py, pt]);
      }

      Directory? docsDir = await pp.getExternalStorageDirectory();
      File('${docsDir!.path}/whiteStrokes.txt')
          .writeAsString(whiteStrokes.toString());
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

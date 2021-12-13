import 'dart:io';
import 'package:doodle/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:path_provider/path_provider.dart' as pp;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'globals.dart' as globals;
import 'routes.dart';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_database/firebase_database.dart';

class DoodleHandler extends StatefulWidget {
  final String userEmail;
  const DoodleHandler({Key? key, required this.userEmail}) : super(key: key);

  @override
  _DoodleHandlerState createState() => _DoodleHandlerState();
}

class _DoodleHandlerState extends State<DoodleHandler> {
  int numOfRounds = globals.numRounds;
  List corrects = [];
  List wrongs = [];
  List keywords = [];
  List guessedKeywordsList = [];
  List labels = [];
  List labels2 = [];
  List allStrokes = [];
  List timerTimes = [];
  late FirebaseDatabase database;

  void send() async {
    SchedulerBinding.instance!.addPostFrameCallback((_) async {
      // print(widget.fbapp.name);

      // print(Firebase.apps);
      bool exists = false;
      String firebaseAppName = 'fb_doodlehandler';
      for (FirebaseApp fba in Firebase.apps) {
        if (fba.name == firebaseAppName) {
          exists = true;
        }
      }
      if (!exists) {
        FirebaseApp fbapp = await Firebase.initializeApp(
            name: firebaseAppName,
            options: DefaultFirebaseOptions.currentPlatform);
        // print('$b ${b.name} ${b.options}');
        database = FirebaseDatabase.instanceFor(app: fbapp);
      } else {
        FirebaseApp fbapp = Firebase.app(firebaseAppName);
        database = FirebaseDatabase.instanceFor(app: fbapp);
      }

      final _labels2String = await loadLabels2();
      final _labels2List = _labels2String.split("\n");

      // select random keywords for n rounds
      var rng = Random();
      Set<int> rnglist = {};
      // print(rnglist.length);
      while (rnglist.length < numOfRounds) {
        rnglist.add(rng.nextInt(_labels2List
            .length)); // still using the trained keywords, not full keywords
      }

      // for (var element in rnglist) {
      //   print(_labels2List[element]);
      // }

      for (int i = 0; i < numOfRounds; i++) {
        String kw = _labels2List[rnglist.toList()[i]];
        final res =
            await Navigator.of(context).push(DoodlePageRoute(keyword: kw));
        // print(res);
        if (res == null) {
          break;
        }
        if (res[0] == true) {
          corrects.add(res[1]);
        } else if (res[0] == false) {
          wrongs.add(res[1]);
        }
        // if (res[1].length > 0) {
        //   // if there's stroke, if not then dont add
        //   allStrokes.add(res);
        // }
        keywords.add([res[0], kw]);
        timerTimes.add(res[3]);
        guessedKeywordsList.add(res[2]);
        allStrokes.add(res);
      }
      // print('corrects: ${corrects.length} - wrongs: ${wrongs.length}');

      // ini data untuk retrain
      // conform strokes to google dataset format [1, 784] white value 0 to 255
      // ikutin algo di doodle.dart untuk create image
      // todo disini

      // ini data untuk di log
      if (allStrokes.isNotEmpty) {
        List whiteStrokes = [];
        for (int i = 0; i < allStrokes.length; i++) {
          List strokes = allStrokes[i][1];
          List stroke = [];
          for (int j = 0; j < strokes.length; j++) {
            List singleStroke = strokes[j];
            List px = []; // x
            List py = []; // y
            List pt = []; // time
            for (int k = 0; k < singleStroke.length; k++) {
              List p = singleStroke[k];
              Offset sOffset = p[0];
              double x = sOffset.dx;
              double y = sOffset.dy;
              double t = double.tryParse(p[1].toString())!;

              px.add(x);
              py.add(y);
              pt.add(t);
            }
            stroke.add([px, py, pt]);
          }
          List strokeDetails = keywords[i];
          String kw = strokeDetails[1];
          bool guessed = strokeDetails[0];
          List guessedKeywords = guessedKeywordsList[i];
          String jsonStr =
              '{"keyword": "${kw.trim().replaceAll(RegExp('\r'), '')}", "guessed": "$guessed", "guessed_keywords": $guessedKeywords, "strokes": $stroke}';
          // whiteStrokes.add([px, py, pt]);
          whiteStrokes.add(jsonStr);
        }

        if (whiteStrokes.isNotEmpty) {
          DatabaseReference ref = database.ref('doodleMaster');
          // DatabaseEvent event = await ref.once();
          // print(event.snapshot.value);
          // await ref.set({"strokes": whiteStrokes.toString()});
          DatabaseReference newStroke = ref.push();
          newStroke.set({
            "user_email": widget.userEmail,
            "datetime": DateTime.now().toString(),
            "doodles": whiteStrokes.toString(),
            "timer_time": timerTimes[0].toString()
          });

          Directory? docsDir = await pp.getExternalStorageDirectory();
          File('${docsDir!.path}/whiteStrokes.txt')
              .writeAsString(whiteStrokes.toString());
        }
      }
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
    return const Scaffold();
  }
}

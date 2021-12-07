import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:doodle/globals.dart' as globals;

class CorrectPage extends StatefulWidget {
  final String keyword;
  final List strokes;
  final num timeTaken;
  const CorrectPage(
      {Key? key,
      required this.keyword,
      required this.strokes,
      required this.timeTaken})
      : super(key: key);

  @override
  _CorrectPageState createState() => _CorrectPageState();
}

class _CorrectPageState extends State<CorrectPage> {
  late Timer _timer;
  num _start = 10.0;

  @override
  void initState() {
    super.initState();
    startTimer();
    setState(() {});
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
          Navigator.pop(context);
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

  @override
  void dispose() {
    // closeTflite();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: globals.bgColor,
      body: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('You\'re correct! Keyword: ${widget.keyword}'),
            Text('Strokes drawn: ${widget.strokes.length}'),
            Text(
                'Time taken to draw the keyword: ${(double.parse(globals.timerTime.toString()) - widget.timeTaken).toStringAsFixed(1)}s'),
            Text('Auto close in: ${_start.toStringAsFixed(0)}s'),
            ElevatedButton(
                style: ButtonStyle(
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(globals.borderRad),
                            side: BorderSide(color: globals.themeColor)))),
                onPressed: () {
                  _timer.cancel();
                  Navigator.pop(context);
                },
                child: const Text('Close'))
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:doodle/globals.dart' as globals;

class AnimatedPainter extends CustomPainter {
  final Animation<double> animation;
  final List<List<dynamic>> points;

  AnimatedPainter({required this.animation, required this.points})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    // print(animation.value * 20);
    // _animation.value has a value between 0.0 and 1.0
    // use this to draw the first X% of the path
    Path path = Path();
    if (points.isEmpty) return;
    // print(animation.value * 20);
    double tt = animation.value * globals.timerTime;
    double tts = double.parse(tt.toStringAsFixed(1));
    // Offset origin = points[0][0];
    // path.moveTo(origin.dx, origin.dy);
    for (int i = 0; i < points.length; i++) {
      Path subPath = Path();
      List stroke = points[i];
      for (int j = 0; j < stroke.length; j++) {
        List offsetandtime = stroke[j];
        Offset p = offsetandtime[0];
        double t = offsetandtime[1];
        if (j == 0) {
          subPath.moveTo(p.dx, p.dy);
        }
        if (tts > t) {
          subPath.lineTo(p.dx, p.dy);
        }
      }
      path.addPath(subPath, Offset.zero);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0,
    );
  }

  @override
  bool shouldRepaint(AnimatedPainter oldDelegate) {
    return true;
  }
}

class DoodleReplayPage extends StatefulWidget {
  final List<dynamic> doodles;
  const DoodleReplayPage({Key? key, required this.doodles}) : super(key: key);

  @override
  _DoodleReplayPageState createState() => _DoodleReplayPageState();
}

class _DoodleReplayPageState extends State<DoodleReplayPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String timeHolder = '0';
  List kws = [];
  List gkwsAllDoodles = [];
  List gkwsStrings = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
    );
    _controller.addListener(() {
      for (int i = 0; i < gkwsAllDoodles.length; i++) {
        List gkwsDoodle = gkwsAllDoodles[i];
        for (int j = 0; j < gkwsDoodle.length; j++) {
          String kw = gkwsDoodle[j][0];
          double t = gkwsDoodle[j][1];
          if (t.toStringAsFixed(1) == timeHolder) {
            if (kw != kws[i]) {
              gkwsStrings[i] = kw;
            } else {
              gkwsStrings[i] = '$kw (${t}s)';
            }
          }
        }
      }
      if (timeHolder == globals.timerTime.toString()) {
        for (String st in gkwsStrings) {
          st = '';
        }
      }
      setState(() {
        timeHolder = (_controller.value * globals.timerTime).toStringAsFixed(1);
      });
    });
    appendGKWs();
  }

  void appendGKWs() {
    for (int i = 0; i < widget.doodles.length; i++) {
      kws.add(widget.doodles[i]['keyword']);
      List gkwsDoodle = widget.doodles[i]['guessed_keywords'];
      gkwsAllDoodles.add(gkwsDoodle);
      gkwsStrings.add('');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startAnimation() {
    _controller.stop();
    _controller.reset();
    _controller.repeat(
      period: Duration(seconds: globals.timerTime),
    );
  }

  List<List<dynamic>> getDoodleOffsetPoints(
      List strokes, int w, int h, List guessedKws) {
    List<List<dynamic>> res = [];
    for (int i = 0; i < strokes.length; i++) {
      List stroke = strokes[i];
      List singleStroke = [];
      for (int j = 0; j < stroke[0].length; j++) {
        double x = stroke[0][j];
        double y = stroke[1][j];
        double t = stroke[2][j];
        double xp = x * w / 280;
        x = xp;
        double yp = y * h / 280;
        y = yp;
        Offset p = Offset(x, y);
        List offsetandtime = [p, t];
        singleStroke.add(offsetandtime);
      }
      res.add(singleStroke);
    }
    return res;
  }

  String getTimes(List strokes) {
    String res = '';
    for (double t in strokes[2]) {
      res += '${t.toString()}, ';
    }
    return res;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doodle Replay'),
      ),
      backgroundColor: globals.bgColor,
      body: Container(
        margin: const EdgeInsets.all(16),
        child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.doodles.length,
            itemBuilder: (context, i) => Card(
                  margin: const EdgeInsets.only(right: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(globals.borderRad),
                      side: BorderSide(color: globals.themeColor)),
                  color: globals.themeColor,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    width: 320,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Keyword: ${widget.doodles[i]['keyword']}'),
                        Text(widget.doodles[i]['guessed'] == 'true'
                            ? 'Guessed: true'
                            : 'Guessed: false'),
                        // Text('Strokes: ${widget.doodles[i]['strokes'].toString()}'),
                        CustomPaint(
                          foregroundPainter: AnimatedPainter(
                            animation: _controller,
                            points: getDoodleOffsetPoints(
                                widget.doodles[i]['strokes'],
                                140,
                                140,
                                widget.doodles[i]['guessed_keywords']),
                          ),
                          child: Container(
                            color: globals.bgColor,
                            width: 140,
                            height: 140,
                          ),
                        ),
                        // RepaintBoundary(
                        //   child: Container(
                        //     color: globals.bgColor,
                        //     width: 140,
                        //     height: 140,
                        //   ),
                        // )
                        // Text(getTimes(widget.doodles[i]['strokes']))
                        Text(gkwsStrings[i])
                      ],
                    ),
                  ),
                )),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startAnimation,
        label: Text(timeHolder),
        icon: const Icon(Icons.play_arrow),
      ),
    );
  }
}
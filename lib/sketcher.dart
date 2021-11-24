import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class MyCustomPainter extends CustomPainter {
  List strokes = [];

  MyCustomPainter(ddl) {
    strokes = ddl;
  }

  @override
  void paint(Canvas canvas, Size size) {
    Paint poly = Paint();
    poly.style = PaintingStyle.stroke;
    poly.strokeWidth = 2;
    Path path = Path();
    // print(dl.firstPoint);
    // print(dl.points.isNotEmpty);

    // if (dl.points.isNotEmpty) {
    //   for (var i = 0; i < dl.points.length - 1; i++) {
    //     var p = dl.points[i];
    //     if (i == 0) {
    //       path.moveTo(p.dx, p.dy);
    //     }

    //     path.lineTo(p.dx, p.dy);
    //   }
    // } else {
    //   path.moveTo(dl.firstPoint.dx, dl.firstPoint.dy);
    // }
    // print(dl);
    for (var i = 0; i < strokes.length; i++) {
      List stroke = strokes[i];

      Path subPath = Path();
      for (var j = 0; j < stroke.length; j++) {
        Offset p = stroke[j];
        if (j == 0) {
          subPath.moveTo(p.dx, p.dy);
        } else {
          subPath.lineTo(p.dx, p.dy);
          // path.moveTo(p.dx, p.dy);
        }
      }
      path.addPath(subPath, Offset.zero);
    }

    canvas.drawPath(path, poly);
    // path.moveTo(lp.dx, lp.dy);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // TODO: implement shouldRepaint
    return true;
  }
}

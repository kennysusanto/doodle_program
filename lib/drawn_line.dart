import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class DrawnLine {
  Offset firstPoint = Offset(0, 0);
  List points = [];

  void addFirstPoint(Offset p) {
    firstPoint = p;
  }

  void addPoint(Offset p) {
    points.add(p);
  }
}

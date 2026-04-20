import 'dart:math' as math;
import 'package:flutter/material.dart';

class AppSize {
  static double w(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return math.min(screenWidth, 360.0); // 👈 cap here
  }
}
import 'package:flutter/material.dart';

Color contrastColor(Color color) {
  if ((color.red * 0.299 + color.green * 0.587 + color.blue * 0.114) > 186) {
    return Colors.black;
  }
  return Colors.white;
}

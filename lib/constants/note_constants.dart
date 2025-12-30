import 'package:flutter/material.dart';

// Colors cho notes
List<Color> noteTileColors = [
  const Color(0xFFe97a55),
  const Color(0xfff6d34f),
  const Color(0xfff5ebc9),
  const Color(0xffa7d573),
  const Color.fromARGB(255, 143, 144, 233),
  const Color.fromARGB(255, 233, 187, 143),
  const Color.fromARGB(255, 233, 143, 199),
  const Color.fromARGB(255, 143, 223, 233),
];

Color noteCreationBg = const Color.fromARGB(255, 255, 250, 234);

List<String> noteTypes = ["all", "Important", "Favourite", "ToDo"];

// Convert Color to hex string
String colorToHex(Color color) {
  return '#${color.value.toRadixString(16).substring(2, 8)}';
}

// Convert hex string to Color
Color hexToColor(String hex) {
  return Color(int.parse(hex.substring(1, 7), radix: 16) + 0xFF000000);
}

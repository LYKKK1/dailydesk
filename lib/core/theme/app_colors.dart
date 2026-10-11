import 'package:flutter/material.dart';

abstract final class AppColors {
  static const p0 = Color(0xFFE5484D);
  static const p1 = Color(0xFFF5A524);
  static const p2 = Color(0xFF3B82F6);
  static const p3 = Color(0xFF8B8D98);

  static const morandiPalette = [
    Color(0xFFD6CCC2),
    Color(0xFFB5C9B8),
    Color(0xFFC9B7A9),
    Color(0xFFA3B1C2),
    Color(0xFFD8C1D0),
    Color(0xFFCFC8B4),
  ];

  static Color priorityColor(int priority) => switch (priority) {
        0 => p0,
        1 => p1,
        2 => p2,
        _ => p3,
      };
}

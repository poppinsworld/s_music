import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: Colors.black,
      primaryColor: Colors.deepPurpleAccent,
      colorScheme: const ColorScheme.dark(
        primary: Colors.deepPurpleAccent,
        surface: Color(0xFF1E1E1E),
      ),
    );
  }
}

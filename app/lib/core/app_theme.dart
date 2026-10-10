import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFFE65100); // orange
  static const free = Color(0xFF2E7D32); // green
  static const occupied = Color(0xFFC62828); // red
  static const billed = Color(0xFFF9A825); // yellow
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        appBarTheme: const AppBarTheme(centerTitle: false),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(64, 52),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      );
}

/// Rs 1,450 format
String rs(double amount) {
  final s = amount.toStringAsFixed(0);
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final fromEnd = s.length - i;
    buf.write(s[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
  }
  return 'Rs ${buf.toString()}';
}

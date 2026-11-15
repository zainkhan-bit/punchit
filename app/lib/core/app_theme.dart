import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const background = Color(0xFFF8F7F3);
  static const card = Colors.white;
  static const primary = Color(0xFFB94620);
  static const darkGreen = Color(0xFF1F3B2B);
  static const green = Color(0xFF2A7152);
  static const successBg = Color(0xFFE9F4EA);
  static const peach = Color(0xFFFFF0E5);
  static const warningBg = Color(0xFFFFF6DC);
  static const warningText = Color(0xFF8A6A1F);
  static const textPrimary = Color(0xFF1C1C1A);
  static const textSecondary = Color(0xFF8A8A84);
  static const divider = Color(0xFFE6E4DE);

  static const primaryLight = Color(0xFFD9683C);
  static const darkGreenLight = Color(0xFF2D5A43);
  static const darkGreenDeep = Color(0xFF16291F);
  static const skeleton = Color(0xFFECE9E2);

  static const free = green;
  static const occupied = primary;
  static const billed = Color(0xFFC9891A);
}

class AppGradients {
  AppGradients._();

  static const primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primaryLight, AppColors.primary],
  );

  static const hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.darkGreenLight,
      AppColors.darkGreen,
      AppColors.darkGreenDeep,
    ],
  );

  static const badge = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3C9A72), AppColors.green],
  );
}

class AppShadows {
  AppShadows._();

  static const card = [
    BoxShadow(color: Color(0x12000000), blurRadius: 18, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 3, offset: Offset(0, 1)),
  ];

  static const soft = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 4)),
  ];

  static const button = [
    BoxShadow(color: Color(0x59B94620), blurRadius: 16, offset: Offset(0, 8)),
  ];

  static const hero = [
    BoxShadow(color: Color(0x471F3B2B), blurRadius: 26, offset: Offset(0, 14)),
  ];

  static const nav = [
    BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, -4)),
  ];
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.background,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 52),
          textStyle:
          const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.darkGreen,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.green : null,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
    );
  }
}

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

const _weekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];
const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July',
  'August', 'September', 'October', 'November', 'December',
];

String timeLabel(DateTime t) {
  final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$hour:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
}

String longDateLabel(DateTime d) =>
    '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]}';

String shortDateLabel(DateTime d) =>
    '${d.day} ${_months[d.month - 1].substring(0, 3)} ${d.year}';

import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const PunchItApp());
}

class PunchItApp extends StatelessWidget {
  const PunchItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PunchIt',
      theme: AppTheme.light,
      home: const LoginScreen(),
    );
  }
}
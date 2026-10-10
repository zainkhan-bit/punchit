import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'data/mock_pos_repository.dart';
import 'data/pos_repository.dart';
import 'providers/order_provider.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        // Backend banne ke baad sirf yeh line badalni hai:
        // Provider<PosRepository>(create: (_) => ApiPosRepository()),
        Provider<PosRepository>(create: (_) => MockPosRepository()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: const PunchItApp(),
    ),
  );
}

class PunchItApp extends StatelessWidget {
  const PunchItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PunchIt',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const LoginScreen(),
    );
  }
}

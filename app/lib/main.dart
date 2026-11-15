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
        Provider<PosRepository>(create: (_) => MockPosRepository()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: const PunchItApp(),
    ),
  );
}

/// Root application widget configuring Theme, Navigation & Responsive Frame.
class PunchItApp extends StatelessWidget {
  const PunchItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PunchIt',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Wrap desktop/web window in a mobile frame layout
      builder: (context, child) {
        final media = MediaQuery.of(context);
        if (media.size.width > 500) {
          return Container(
            color: const Color(0xFF1A1A1A),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450, maxHeight: 900),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: child,
                ),
              ),
            ),
          );
        }
        return child!;
      },
      home: const LoginScreen(),
    );
  }
}

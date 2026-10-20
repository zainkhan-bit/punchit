import 'package:flutter/material.dart';

import 'daily_report_screen.dart';
import 'products_screen.dart';
import 'restaurant_settings_screen.dart';

void openManagerTab(BuildContext context, int index) {
  final nav = Navigator.of(context);
  nav.popUntil((route) => route.isFirst);
  final Widget? page = switch (index) {
    1 => const ProductsScreen(),
    2 => const DailyReportScreen(),
    3 => const RestaurantSettingsScreen(),
    _ => null,
  };
  if (page != null) {
    nav.push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

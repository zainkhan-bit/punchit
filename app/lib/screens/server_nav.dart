import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/order_provider.dart';
import 'choose_table_screen.dart';
import 'login_screen.dart';
import 'menu_screen.dart';
import 'order_type_screen.dart';
import 'your_orders_screen.dart';

void startNewOrder(NavigatorState nav, OrderProvider order, OrderType type) {
  order.startOrder(type);
  nav.push(MaterialPageRoute<void>(
    builder: (_) => type == OrderType.dineIn
        ? const ChooseTableScreen()
        : const MenuScreen(),
  ));
}

void openServerTab(BuildContext context, int index) {
  final nav = Navigator.of(context);
  final order = context.read<OrderProvider>();

  if (index == 3) {
    order.logout();
    nav.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
          (_) => false,
    );
    return;
  }

  order.resetOrder();
  nav.popUntil(ModalRoute.withName(OrderTypeScreen.routeName));
  nav.pushReplacement(OrderTypeScreen.route());
  if (index == 1) {
    nav.push(MaterialPageRoute<void>(builder: (_) => const YourOrdersScreen()));
  }
  if (index == 2) startNewOrder(nav, order, OrderType.dineIn);
}

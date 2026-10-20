import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/order_provider.dart';
import '../widgets/order_card.dart';
import '../widgets/ui_kit.dart';
import 'order_type_screen.dart';
import 'server_nav.dart';

class OrderSentScreen extends StatelessWidget {
  final PlacedOrder order;

  const OrderSentScreen({super.key, required this.order});

  void _startAnother(BuildContext context) {
    final nav = Navigator.of(context);
    final provider = context.read<OrderProvider>();
    nav.popUntil(ModalRoute.withName(OrderTypeScreen.routeName));
    nav.pushReplacement(OrderTypeScreen.route());
    startNewOrder(nav, provider, order.type);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Order sent',
              subtitle: 'Order #${order.id} · ${order.label}',
              onBack: () => openServerTab(context, 0),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  SuccessCard(
                    title: 'The kitchen has it.',
                    message: '${order.itemCount} items kitchen ko bhej diye. '
                        'Ready hone pe pata chal jayega.',
                  ),
                  const SizedBox(height: 12),
                  OrderCard(order: order),
                  const SizedBox(height: 20),
                  const Text(
                    'What happens next',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const ListRowCard(
                    title: '01  Preparing',
                    subtitle: 'Kitchen stations pe docket print hota hai',
                  ),
                  const SizedBox(height: 10),
                  ListRowCard(
                    title: order.isDineIn ? '02  Ready to serve' : '02  Pack for pickup',
                    subtitle: order.isDineIn
                        ? 'Items ready hon to table pe serve karo'
                        : 'Pack kar ke customer ko do',
                  ),
                  const SizedBox(height: 10),
                  const ListRowCard(
                    title: '03  Collect payment',
                    subtitle: 'Your orders se order khol kar payment lo',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  PrimaryButton(
                    label: 'View active orders',
                    onPressed: () => openServerTab(context, 1),
                  ),
                  const SizedBox(height: 10),
                  SecondaryButton(
                    label: 'Start another order',
                    onPressed: () => _startAnother(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

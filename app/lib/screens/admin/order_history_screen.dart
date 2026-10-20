import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../data/pos_repository.dart';
import '../../models/models.dart';
import '../../widgets/order_card.dart';
import '../../widgets/ui_kit.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<PlacedOrder> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final orders = await context.read<PosRepository>().getOrders();
    if (!mounted) return;
    setState(() {
      _orders = orders.where((o) => o.isPaid).toList()
        ..sort((a, b) => b.closedAt!.compareTo(a.closedAt!));
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _orders.fold(0.0, (sum, o) => sum + o.total);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Order history', subtitle: 'Completed orders'),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        if (_orders.isEmpty)
                          const NoteBanner(text: 'Abhi koi paid order nahi.'),
                        for (final o in _orders)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: OrderCard(order: o),
                          ),
                        if (_orders.isNotEmpty)
                          NoteBanner(
                            text: '${_orders.length} completed orders · ${rs(total)}',
                            type: NoteType.success,
                          ),
                        const SizedBox(height: 16),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: PrimaryButton(
                label: 'Back to daily report',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

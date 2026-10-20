import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/models.dart';
import '../widgets/ui_kit.dart';
import 'server_nav.dart';

class PaymentCompleteScreen extends StatelessWidget {
  final PlacedOrder order;
  final AppSettings settings;

  const PaymentCompleteScreen({super.key, required this.order, required this.settings});

  String _pct(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final isCash = order.paymentMethod?.name.toLowerCase() == 'cash';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Payment complete',
              subtitle: 'Order #${order.id}',
              onBack: () => openServerTab(context, 0),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  SuccessCard(
                    title: 'All settled.',
                    message: order.isDineIn
                        ? 'Payment record ho gayi. T${order.table?.tableNumber} ab agle customer ke liye free hai.'
                        : 'Payment record ho gayi. Shukriya!',
                  ),
                  const SizedBox(height: 12),
                  InfoCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          settings.restaurantName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Receipt #${order.id} · ${shortDateLabel(order.closedAt ?? DateTime.now())} · ${order.label}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Paid ${rs(order.total)}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        for (final c in order.items)
                          AmountRow('${c.quantity} × ${c.item.name}', rs(c.lineTotal)),
                        const Divider(color: AppColors.divider, height: 20),
                        AmountRow('Subtotal', rs(order.subtotal)),
                        if (order.discount > 0) AmountRow('Discount', '- ${rs(order.discount)}'),
                        if (order.serviceCharge > 0)
                          AmountRow('Service charge', rs(order.serviceCharge)),
                        AmountRow('Tax · ${_pct(order.taxPercent)}%', rs(order.tax)),
                        AmountRow('Total', rs(order.total), bold: true),
                        const Divider(color: AppColors.divider, height: 20),
                        if (isCash) ...[
                          AmountRow('Cash received', rs(order.amountReceived)),
                          AmountRow('Change returned', rs(order.change)),
                        ] else ...[
                          AmountRow('${order.paymentMethod?.name ?? ''} payment', rs(order.total)),
                          AmountRow('Reference', order.paymentReference),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          'Served by ${order.server.name}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        if (settings.receiptFooter.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            settings.receiptFooter,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: PrimaryButton(
                label: 'Back to home',
                onPressed: () => openServerTab(context, 0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

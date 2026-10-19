import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/models.dart';
import 'ui_kit.dart';

class OrderCard extends StatelessWidget {
  final PlacedOrder order;
  final VoidCallback? onTap;

  const OrderCard({super.key, required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    final time = order.closedAt ?? order.createdAt;
    return InfoCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${order.itemCount} items · ${timeLabel(time)} · ${order.server.name}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  order.statusLabel,
                  style: const TextStyle(fontSize: 11, color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  order.isPaid ? rs(order.total) : '${rs(order.subtotal)} + tax',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

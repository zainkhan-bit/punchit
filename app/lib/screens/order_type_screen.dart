import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/order_provider.dart';
import 'login_screen.dart';
import 'menu_screen.dart';

class OrderTypeScreen extends StatelessWidget {
  const OrderTypeScreen({super.key});

  static const routeName = '/order-type';

  /// Order bhejne ke baad isi screen pe wapas aate hain (popUntil routeName)
  static Route<void> route() => MaterialPageRoute(
        settings: const RouteSettings(name: routeName),
        builder: (_) => const OrderTypeScreen(),
      );

  void _start(BuildContext context, OrderType type) {
    context.read<OrderProvider>().startOrder(type);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MenuScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<OrderProvider>().loggedInStaff;
    return Scaffold(
      appBar: AppBar(
        title: Text('Salam, ${staff?.name ?? ''}'),
        actions: [
          if (!(staff?.isAdmin ?? false))
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<OrderProvider>().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: _TypeCard(
                icon: Icons.table_restaurant,
                title: 'Dine-in',
                subtitle: 'Hall aur table pe order',
                onTap: () => _start(context, OrderType.dineIn),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _TypeCard(
                icon: Icons.takeout_dining,
                title: 'Takeaway',
                subtitle: 'Parcel order',
                onTap: () => _start(context, OrderType.takeaway),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: cs.primaryContainer,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 72, color: cs.onPrimaryContainer),
              const SizedBox(height: 12),
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: cs.onPrimaryContainer)),
              Text(subtitle, style: TextStyle(color: cs.onPrimaryContainer)),
            ],
          ),
        ),
      ),
    );
  }
}

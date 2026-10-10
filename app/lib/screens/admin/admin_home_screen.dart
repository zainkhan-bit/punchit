import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/order_provider.dart';
import '../login_screen.dart';
import '../order_type_screen.dart';
import 'categories_screen.dart';
import 'floor_screen.dart';
import 'modifier_groups_screen.dart';
import 'products_screen.dart';
import 'staff_screen.dart';
import 'stations_screen.dart';
import 'tax_settings_screen.dart';

/// Manager / Owner ka panel. Yahan se sab kuch app ke andar hi set hota hai.
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<OrderProvider>().loggedInStaff;
    final cs = Theme.of(context).colorScheme;

    final tiles = <_Tile>[
      _Tile(Icons.category, 'Categories', 'Pizza, Burgers, Drinks',
          (_) => const CategoriesScreen()),
      _Tile(Icons.fastfood, 'Products', 'Naam, price, availability',
          (_) => const ProductsScreen()),
      _Tile(Icons.add_circle_outline, 'Toppings & Options',
          'Crust, extra cheese, add-ons', (_) => const ModifierGroupsScreen()),
      _Tile(Icons.percent, 'Tax & Settings', 'Cash / Card tax, service charge',
          (_) => const TaxSettingsScreen()),
      _Tile(Icons.print, 'Kitchen Stations', 'Printers aur routing',
          (_) => const StationsScreen()),
      _Tile(Icons.table_restaurant, 'Halls & Tables', 'Floor setup',
          (_) => const FloorScreen()),
      _Tile(Icons.badge, 'Staff', 'Servers, kitchen, managers, PIN',
          (_) => const StaffScreen()),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Manager Panel - ${staff?.name ?? ''}'),
        actions: [
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
            ),
            icon: const Icon(Icons.point_of_sale),
            label: const Text('Take Order'),
            onPressed: () => Navigator.of(context).push(OrderTypeScreen.route()),
          ),
          const SizedBox(height: 20),
          Text('Setup', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 260,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            itemCount: tiles.length,
            itemBuilder: (_, i) {
              final t = tiles[i];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: t.builder)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(t.icon, size: 32, color: cs.primary),
                        const Spacer(),
                        Text(t.title,
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 2),
                        Text(t.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Tile {
  final IconData icon;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;

  const _Tile(this.icon, this.title, this.subtitle, this.builder);
}

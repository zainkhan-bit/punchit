import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/pos_repository.dart';
import '../../models/models.dart';
import '../../widgets/ui_kit.dart';
import 'categories_screen.dart';
import 'floor_screen.dart';
import 'manager_nav.dart';
import 'modifier_groups_screen.dart';
import 'stations_screen.dart';
import 'tax_settings_screen.dart';

class RestaurantSettingsScreen extends StatefulWidget {
  const RestaurantSettingsScreen({super.key});

  @override
  State<RestaurantSettingsScreen> createState() => _RestaurantSettingsScreenState();
}

class _RestaurantSettingsScreenState extends State<RestaurantSettingsScreen> {
  AppSettings? _settings;
  List<PaymentMethod> _methods = [];
  int _halls = 0;
  int _tables = 0;
  int _stations = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<PosRepository>();
    final settings = await repo.getSettings();
    final methods = await repo.getPaymentMethods();
    final halls = await repo.getHalls();
    final tables = [for (final h in halls) ...await repo.getTables(h.id)];
    final stations = await repo.getStations();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _methods = methods.where((m) => m.isActive).toList();
      _halls = halls.length;
      _tables = tables.length;
      _stations = stations.length;
    });
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
    _load();
  }

  String _pct(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final taxText = _methods.map((m) => '${m.name} ${_pct(m.taxPercent)}%').join(' · ');

    return Scaffold(
      bottomNavigationBar: RoleBottomNav(
        items: managerNavItems,
        currentIndex: 3,
        onTap: (i) => openManagerTab(context, i),
      ),
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Restaurant settings',
              subtitle: _settings?.restaurantName ?? 'Manager access only',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  ListRowCard(
                    title: 'Halls & tables',
                    subtitle: '$_tables tables · $_halls halls',
                    onTap: () => _open(const FloorScreen()),
                  ),
                  const SizedBox(height: 10),
                  ListRowCard(
                    title: 'Kitchen stations',
                    subtitle: '$_stations stations aur printers',
                    onTap: () => _open(const StationsScreen()),
                  ),
                  const SizedBox(height: 10),
                  ListRowCard(
                    title: 'Tax & payments',
                    subtitle: _settings == null
                        ? '-'
                        : '$taxText · Service ${_pct(_settings!.serviceChargePercent)}%',
                    onTap: () => _open(const TaxSettingsScreen()),
                  ),
                  const SizedBox(height: 10),
                  ListRowCard(
                    title: 'Categories',
                    subtitle: 'Pizza, Burgers, Drinks',
                    onTap: () => _open(const CategoriesScreen()),
                  ),
                  const SizedBox(height: 10),
                  ListRowCard(
                    title: 'Toppings & options',
                    subtitle: 'Crust, extra cheese, add-ons',
                    onTap: () => _open(const ModifierGroupsScreen()),
                  ),
                  const SizedBox(height: 16),
                  const NoteBanner(text: 'Changes naye orders pe foran lag jati hain.'),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../data/pos_repository.dart';
import '../../models/models.dart';
import '../../providers/order_provider.dart';
import '../../widgets/sign_out_dialog.dart';
import '../../widgets/ui_kit.dart';
import '../login_screen.dart';
import '../order_type_screen.dart';
import 'daily_report_screen.dart';
import 'manager_nav.dart';
import 'products_screen.dart';
import 'restaurant_settings_screen.dart';
import 'staff_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  double _sales = 0;
  int _paidCount = 0;
  int _activeCount = 0;
  int _staffOnShift = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<PosRepository>();
    final orders = await repo.getOrders();
    final staff = await repo.getAllStaff();
    if (!mounted) return;
    final now = DateTime.now();
    final paidToday = orders.where((o) {
      final d = o.closedAt;
      return o.isPaid &&
          d != null &&
          d.year == now.year &&
          d.month == now.month &&
          d.day == now.day;
    }).toList();
    setState(() {
      _sales = paidToday.fold(0.0, (sum, o) => sum + o.total);
      _paidCount = paidToday.length;
      _activeCount = orders.where((o) => o.isActive).length;
      _staffOnShift = staff.where((s) => s.isActive).length;
      _loading = false;
    });
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
    _load();
  }

  Future<void> _takeOrder() async {
    await Navigator.of(context).push(OrderTypeScreen.route());
    _load();
  }

  Future<void> _logout() async {
    if (!await confirmSignOut(context) || !mounted) return;
    context.read<OrderProvider>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<OrderProvider>().loggedInStaff;

    return Scaffold(
      bottomNavigationBar: RoleBottomNav(
        items: managerNavItems,
        currentIndex: 0,
        onTap: (i) => openManagerTab(context, i),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Restaurant overview',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${staff?.name ?? ''} · ${staff == null ? '' : StaffRoles.label(staff.role)} · Today',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Logout',
                    icon: const Icon(Icons.logout),
                    onPressed: _logout,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              HeroCard(
                icon: Icons.bar_chart,
                title: _loading ? '-' : rs(_sales),
                subtitle: "Today's sales · $_paidCount completed orders",
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      label: 'Orders in progress',
                      value: _loading ? '-' : '$_activeCount',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      label: 'Staff on shift',
                      value: _loading ? '-' : '$_staffOnShift',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              PrimaryButton(label: 'Take order', onPressed: _takeOrder),
              const SizedBox(height: 20),
              ListRowCard(
                title: 'Menu management',
                subtitle: 'Products, prices aur availability',
                onTap: () => _open(const ProductsScreen()),
              ),
              const SizedBox(height: 10),
              ListRowCard(
                title: 'Staff & access',
                subtitle: 'Accounts, roles aur PIN',
                onTap: () => _open(const StaffScreen()),
              ),
              const SizedBox(height: 10),
              ListRowCard(
                title: 'Daily reports',
                subtitle: 'Sales, payments aur order history',
                onTap: () => _open(const DailyReportScreen()),
              ),
              const SizedBox(height: 10),
              ListRowCard(
                title: 'Restaurant settings',
                subtitle: 'Tables, stations, tax aur toppings',
                onTap: () => _open(const RestaurantSettingsScreen()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

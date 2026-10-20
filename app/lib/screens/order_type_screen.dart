import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../data/pos_repository.dart';
import '../models/models.dart';
import '../providers/order_provider.dart';
import '../widgets/order_card.dart';
import '../widgets/ui_kit.dart';
import 'collect_payment_screen.dart';
import 'server_nav.dart';

class OrderTypeScreen extends StatefulWidget {
  const OrderTypeScreen({super.key});

  static const routeName = '/order-type';

  static Route<void> route() => MaterialPageRoute(
    settings: const RouteSettings(name: routeName),
    builder: (_) => const OrderTypeScreen(),
  );

  @override
  State<OrderTypeScreen> createState() => _OrderTypeScreenState();
}

class _OrderTypeScreenState extends State<OrderTypeScreen> {
  List<PlacedOrder> _orders = [];
  int _freeTables = 0;
  int _totalTables = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<PosRepository>();
    final staff = context.read<OrderProvider>().loggedInStaff;
    final orders = await repo.getOrders(activeOnly: true);
    final halls = await repo.getHalls();
    final tables = [for (final h in halls) ...await repo.getTables(h.id)];
    if (!mounted) return;
    setState(() {
      _orders = staff != null && staff.role == StaffRoles.server
          ? orders.where((o) => o.server.id == staff.id).toList()
          : orders;
      _totalTables = tables.length;
      _freeTables = tables.where((t) => t.status == TableStatus.free).length;
      _loading = false;
    });
  }

  Future<void> _openPayment(PlacedOrder order) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => CollectPaymentScreen(order: order),
    ));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<OrderProvider>().loggedInStaff;
    final isAdmin = staff?.isAdmin ?? false;

    return Scaffold(
      bottomNavigationBar: RoleBottomNav(
        items: serverNavItems,
        currentIndex: 0,
        onTap: (i) => openServerTab(context, i),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  if (isAdmin)
                    IconButton(
                      tooltip: 'Manager panel',
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${staff?.name ?? ''}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${longDateLabel(DateTime.now())} · ${staff == null ? '' : StaffRoles.label(staff.role)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const HeroCard(
                icon: Icons.add,
                title: 'Ready for the rush?',
                subtitle: 'Start a table order or pack a takeaway.',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      label: 'Active orders',
                      value: _loading ? '-' : '${_orders.length}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      label: 'Tables free',
                      value: _loading ? '-' : '$_freeTables / $_totalTables',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Dine-in',
                      onPressed: () => startNewOrder(Navigator.of(context),
                          context.read<OrderProvider>(), OrderType.dineIn),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SecondaryButton(
                      label: 'Takeaway',
                      onPressed: () => startNewOrder(Navigator.of(context),
                          context.read<OrderProvider>(), OrderType.takeaway),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'On your floor',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_orders.isEmpty)
                const NoteBanner(text: 'Abhi koi active order nahi.', type: NoteType.success)
              else
                for (final o in _orders.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: OrderCard(order: o, onTap: () => _openPayment(o)),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

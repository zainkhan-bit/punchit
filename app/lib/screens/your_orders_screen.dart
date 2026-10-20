import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/pos_repository.dart';
import '../models/models.dart';
import '../providers/order_provider.dart';
import '../widgets/order_card.dart';
import '../widgets/ui_kit.dart';
import 'collect_payment_screen.dart';
import 'server_nav.dart';

class YourOrdersScreen extends StatefulWidget {
  const YourOrdersScreen({super.key});

  @override
  State<YourOrdersScreen> createState() => _YourOrdersScreenState();
}

class _YourOrdersScreenState extends State<YourOrdersScreen> {
  List<PlacedOrder> _orders = [];
  int _tab = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final staff = context.read<OrderProvider>().loggedInStaff;
    final orders = await context.read<PosRepository>().getOrders();
    if (!mounted) return;
    setState(() {
      _orders = staff != null && staff.role == StaffRoles.server
          ? orders.where((o) => o.server.id == staff.id).toList()
          : orders;
      _loading = false;
    });
  }

  Future<void> _collect(PlacedOrder order) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => CollectPaymentScreen(order: order),
    ));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final active = _orders.where((o) => o.isActive).toList();
    final history = _orders.where((o) => o.isPaid).toList();
    final shown = _tab == 0 ? active : history;

    return Scaffold(
      bottomNavigationBar: RoleBottomNav(
        items: serverNavItems,
        currentIndex: 1,
        onTap: (i) => openServerTab(context, i),
      ),
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Your orders',
              subtitle: '${active.length} active · ${history.length} paid',
              onBack: () => openServerTab(context, 0),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PillTabs(
                options: ['Active · ${active.length}', 'History'],
                selectedIndex: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (shown.isEmpty)
                      NoteBanner(
                        text: _tab == 0 ? 'Koi active order nahi.' : 'Abhi koi paid order nahi.',
                        type: NoteType.success,
                      ),
                    for (final o in shown)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: OrderCard(
                          order: o,
                          onTap: _tab == 0 ? () => _collect(o) : null,
                        ),
                      ),
                    if (_tab == 0 && active.isNotEmpty)
                      const NoteBanner(
                        text: 'Payment lene ke liye order pe tap karo.',
                        type: NoteType.success,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

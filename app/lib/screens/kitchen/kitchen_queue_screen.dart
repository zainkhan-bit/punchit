import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../data/pos_repository.dart';
import '../../models/models.dart';
import '../../providers/order_provider.dart';
import '../../widgets/sign_out_dialog.dart';
import '../../widgets/ui_kit.dart';
import '../login_screen.dart';

class KitchenQueueScreen extends StatefulWidget {
  const KitchenQueueScreen({super.key});

  @override
  State<KitchenQueueScreen> createState() => _KitchenQueueScreenState();
}

class _KitchenQueueScreenState extends State<KitchenQueueScreen> {
  List<PlacedOrder> _orders = [];
  int _tab = 0;
  String? _banner;
  int? _busyId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final orders = await context.read<PosRepository>().getOrders(activeOnly: true);
    if (!mounted) return;
    setState(() {
      _orders = orders.where((o) => o.status == OrderStatus.open).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _loading = false;
    });
  }

  List<PlacedOrder> get _inProgress => _orders
      .where((o) =>
          o.kitchenStatus == KitchenStatus.pending ||
          o.kitchenStatus == KitchenStatus.preparing)
      .toList();

  List<PlacedOrder> get _ready =>
      _orders.where((o) => o.kitchenStatus == KitchenStatus.ready).toList();

  Future<void> _setStatus(PlacedOrder order, KitchenStatus status) async {
    setState(() => _busyId = order.id);
    try {
      await context.read<PosRepository>().updateKitchenStatus(order.id, status);
      if (!mounted) return;
      setState(() {
        _banner = switch (status) {
          KitchenStatus.preparing => 'Order #${order.id} preparing mein hai.',
          KitchenStatus.ready => 'Order #${order.id} ready hai. ${order.server.name} ko pata chal jayega.',
          KitchenStatus.served => 'Order #${order.id} ${order.isDineIn ? 'serve' : 'hand over'} ho gaya.',
          KitchenStatus.pending => null,
        };
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _banner = e.toString().replaceFirst('Exception: ', ''));
    }
    _busyId = null;
    _load();
  }

  Future<void> _onNav(int i) async {
    if (i == 2) {
      if (!await confirmSignOut(context) || !mounted) return;
      context.read<OrderProvider>().logout();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (_) => false,
      );
      return;
    }
    setState(() {
      _tab = i;
      _banner = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<OrderProvider>().loggedInStaff;
    final shown = _tab == 0 ? _inProgress : _ready;

    return Scaffold(
      bottomNavigationBar: RoleBottomNav(
        items: kitchenNavItems,
        currentIndex: _tab,
        onTap: _onNav,
      ),
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: _tab == 0 ? 'Kitchen queue' : 'Ready for pickup',
              subtitle: 'Kitchen · ${staff?.name ?? ''}',
              showBack: false,
              trailing: IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                onPressed: _load,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: StatTile(label: 'In progress', value: '${_inProgress.length}')),
                      const SizedBox(width: 12),
                      Expanded(child: StatTile(label: 'Ready', value: '${_ready.length}')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  PillTabs(
                    options: ['Preparing · ${_inProgress.length}', 'Ready · ${_ready.length}'],
                    selectedIndex: _tab,
                    onChanged: _onNav,
                  ),
                  if (_banner != null) ...[
                    const SizedBox(height: 10),
                    NoteBanner(text: _banner!, type: NoteType.success),
                  ],
                ],
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
                              text: _tab == 0 ? 'Queue khali hai.' : 'Koi order ready nahi.',
                              type: NoteType.success,
                            ),
                          for (final o in shown)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _TicketCard(
                                order: o,
                                busy: _busyId == o.id,
                                onAction: () => _setStatus(
                                  o,
                                  switch (o.kitchenStatus) {
                                    KitchenStatus.pending => KitchenStatus.preparing,
                                    KitchenStatus.preparing => KitchenStatus.ready,
                                    _ => KitchenStatus.served,
                                  },
                                ),
                              ),
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

class _TicketCard extends StatelessWidget {
  final PlacedOrder order;
  final bool busy;
  final VoidCallback onAction;

  const _TicketCard({
    required this.order,
    required this.busy,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final notes = [
      for (final c in order.items)
        if (c.note.isNotEmpty) '${c.item.name}: ${c.note}',
    ];
    final minutes = DateTime.now().difference(order.createdAt).inMinutes;
    final actionLabel = switch (order.kitchenStatus) {
      KitchenStatus.pending => 'Start preparing',
      KitchenStatus.preparing => 'Mark ready',
      _ => order.isDineIn ? 'Mark served' : 'Handed over',
    };

    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '#${order.id} / ${order.label}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            '${order.statusLabel} · $minutes min · ${order.server.name}',
            style: const TextStyle(fontSize: 11, color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          for (final c in order.items) ...[
            Text(
              '${c.quantity} × ${c.item.name}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            if (c.modifiers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  c.modifiers.map((m) => m.name).join(' · '),
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
            const SizedBox(height: 4),
          ],
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            NoteBanner(text: 'NOTE: ${notes.join(' | ')}', type: NoteType.warning),
          ],
          const SizedBox(height: 12),
          PrimaryButton(label: actionLabel, loading: busy, onPressed: onAction),
        ],
      ),
    );
  }
}

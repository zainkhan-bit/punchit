import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../data/pos_repository.dart';
import '../../models/models.dart';
import '../../widgets/ui_kit.dart';
import 'manager_nav.dart';
import 'order_history_screen.dart';

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  List<PlacedOrder> _paid = [];
  int _busyTables = 0;
  int _totalTables = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<PosRepository>();
    final orders = await repo.getOrders();
    final halls = await repo.getHalls();
    final tables = [for (final h in halls) ...await repo.getTables(h.id)];
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      _paid = orders.where((o) {
        final d = o.closedAt;
        return o.isPaid &&
            d != null &&
            d.year == now.year &&
            d.month == now.month &&
            d.day == now.day;
      }).toList();
      _totalTables = tables.length;
      _busyTables = tables.where((t) => t.status != TableStatus.free).length;
      _loading = false;
    });
  }

  double get _sales => _paid.fold(0.0, (sum, o) => sum + o.total);

  Map<int, double> get _salesByHour {
    final map = <int, double>{};
    for (final o in _paid) {
      final h = o.closedAt!.hour;
      map[h] = (map[h] ?? 0) + o.total;
    }
    return map;
  }

  Map<String, List<PlacedOrder>> get _byMethod {
    final map = <String, List<PlacedOrder>>{};
    for (final o in _paid) {
      final name = o.paymentMethod?.name ?? '-';
      map.putIfAbsent(name, () => []).add(o);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: RoleBottomNav(
        items: managerNavItems,
        currentIndex: 2,
        onTap: (i) => openManagerTab(context, i),
      ),
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Daily report',
              subtitle: longDateLabel(DateTime.now()),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          Row(
                            children: [
                              Expanded(child: StatTile(label: 'Total sales', value: rs(_sales))),
                              const SizedBox(width: 12),
                              Expanded(
                                child: StatTile(label: 'Completed orders', value: '${_paid.length}'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          InfoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sales through the day',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 12),
                                if (_paid.isEmpty)
                                  const Text(
                                    'Aaj abhi koi payment nahi hui.',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  )
                                else
                                  _SalesChart(salesByHour: _salesByHour),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Payment breakdown',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          if (_byMethod.isEmpty)
                            const AmountRow('Koi payment nahi', '-'),
                          for (final e in _byMethod.entries)
                            AmountRow(
                              '${e.key} · ${e.value.length} orders',
                              rs(e.value.fold(0.0, (sum, o) => sum + o.total)),
                            ),
                          const Divider(color: AppColors.divider, height: 20),
                          AmountRow('Tables occupied', '$_busyTables / $_totalTables', bold: true),
                          const SizedBox(height: 12),
                          ListRowCard(
                            title: 'Order history',
                            subtitle: 'Completed orders aur payments',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(builder: (_) => const OrderHistoryScreen()),
                            ),
                          ),
                          const SizedBox(height: 16),
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

class _SalesChart extends StatelessWidget {
  final Map<int, double> salesByHour;

  const _SalesChart({required this.salesByHour});

  String _hourLabel(int h) {
    final hour = h % 12 == 0 ? 12 : h % 12;
    return '$hour${h < 12 ? 'a' : 'p'}';
  }

  @override
  Widget build(BuildContext context) {
    final first = salesByHour.keys.reduce((a, b) => a < b ? a : b);
    final last = salesByHour.keys.reduce((a, b) => a > b ? a : b);
    final start = (last - first < 5) ? (last - 5).clamp(0, 23) : first;
    final hours = [for (var h = start; h <= last; h++) h];
    final maxValue = salesByHour.values.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final h in hours)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: 100 * ((salesByHour[h] ?? 0) / maxValue) + 4,
                      decoration: BoxDecoration(
                        color: (salesByHour[h] ?? 0) == maxValue
                            ? AppColors.primary
                            : AppColors.peach,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _hourLabel(h),
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

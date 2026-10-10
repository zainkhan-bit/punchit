import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../data/pos_repository.dart';
import '../models/models.dart';
import '../providers/order_provider.dart';

/// Dine-in: pehla item add hone ke baad Hall -> Table -> Server select.
/// true return = details save ho gayi.
Future<bool> showTableSelectSheet(BuildContext context) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    builder: (_) => const _TableSelectSheet(),
  );
  return ok ?? false;
}

class _TableSelectSheet extends StatefulWidget {
  const _TableSelectSheet();

  @override
  State<_TableSelectSheet> createState() => _TableSelectSheetState();
}

class _TableSelectSheetState extends State<_TableSelectSheet> {
  List<Hall> _halls = [];
  List<DiningTable> _tables = [];
  List<Staff> _servers = [];

  Hall? _hall;
  DiningTable? _table;
  Staff? _server;

  bool _loadingTables = false;

  @override
  void initState() {
    super.initState();
    final order = context.read<OrderProvider>();
    _hall = order.hall;
    _table = order.table;
    _server = order.server;
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final repo = context.read<PosRepository>();
    final results = await Future.wait([repo.getHalls(), repo.getServers()]);
    if (!mounted) return;
    setState(() {
      _halls = results[0] as List<Hall>;
      _servers = results[1] as List<Staff>;
      _hall ??= _halls.isNotEmpty ? _halls.first : null;
      // Logged-in staff list mein na ho (e.g. manager) to pehla server
      if (_server == null || !_servers.any((s) => s.id == _server!.id)) {
        _server = _servers.isNotEmpty ? _servers.first : null;
      } else {
        _server = _servers.firstWhere((s) => s.id == _server!.id);
      }
    });
    if (_hall != null) _loadTables(_hall!);
  }

  Future<void> _loadTables(Hall hall) async {
    setState(() {
      _hall = hall;
      _loadingTables = true;
      if (_table?.hallId != hall.id) _table = null;
    });
    final tables = await context.read<PosRepository>().getTables(hall.id);
    if (!mounted) return;
    setState(() {
      _tables = tables;
      _loadingTables = false;
    });
  }

  Color _statusColor(TableStatus s) => switch (s) {
        TableStatus.free => AppColors.free,
        TableStatus.occupied => AppColors.occupied,
        TableStatus.billed => AppColors.billed,
      };

  void _confirm() {
    if (_hall == null || _table == null || _server == null) return;
    context
        .read<OrderProvider>()
        .setTableDetails(hall: _hall!, table: _table!, server: _server!);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text('Table details', style: t.titleLarge),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              children: [
                Text('Hall', style: t.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _halls
                      .map((h) => ChoiceChip(
                            label: Text(h.name),
                            selected: _hall?.id == h.id,
                            onSelected: (_) => _loadTables(h),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text('Table', style: t.titleSmall),
                    const Spacer(),
                    _legend('Free', AppColors.free),
                    _legend('Occupied', AppColors.occupied),
                    _legend('Bill', AppColors.billed),
                  ],
                ),
                const SizedBox(height: 8),
                if (_loadingTables)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: _tables.map((tb) {
                      final selected = _table?.id == tb.id;
                      final free = tb.status == TableStatus.free;
                      final color = _statusColor(tb.status);
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: free ? () => setState(() => _table = tb) : null,
                        child: Container(
                          decoration: BoxDecoration(
                            color: selected ? color : color.withAlpha(40),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: color,
                              width: selected ? 3 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('T${tb.tableNumber}',
                                  style: t.titleMedium?.copyWith(
                                      color: selected ? Colors.white : null,
                                      fontWeight: FontWeight.bold)),
                              Text('${tb.capacity} seats',
                                  style: t.bodySmall?.copyWith(
                                      color: selected ? Colors.white : null)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 20),
                Text('Server', style: t.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _servers
                      .map((s) => ChoiceChip(
                            avatar: const Icon(Icons.person, size: 18),
                            label: Text('${s.name} (${s.employeeCode})'),
                            selected: _server?.id == s.id,
                            onSelected: (_) => setState(() => _server = s),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
              ),
              onPressed: (_table != null && _server != null) ? _confirm : null,
              child: Text(_table == null
                  ? 'Table select karo'
                  : 'Confirm  ${_hall?.name} - T${_table!.tableNumber}'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(String label, Color c) => Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
}

/// Takeaway: customer name/phone (optional)
Future<void> showCustomerSheet(BuildContext context) async {
  final order = context.read<OrderProvider>();
  final nameCtrl = TextEditingController(text: order.customerName);
  final phoneCtrl = TextEditingController(text: order.customerPhone);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Takeaway customer (optional)',
              style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Customer name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  order.setCustomer(nameCtrl.text.trim(), phoneCtrl.text.trim());
}

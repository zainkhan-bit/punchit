import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../data/pos_repository.dart';
import '../models/models.dart';
import '../providers/order_provider.dart';
import '../widgets/ui_kit.dart';
import 'menu_screen.dart';

class ChooseTableScreen extends StatefulWidget {
  final bool changeOnly;

  const ChooseTableScreen({super.key, this.changeOnly = false});

  @override
  State<ChooseTableScreen> createState() => _ChooseTableScreenState();
}

class _ChooseTableScreenState extends State<ChooseTableScreen> {
  List<Hall> _halls = [];
  List<DiningTable> _tables = [];
  List<Staff> _servers = [];

  Hall? _hall;
  DiningTable? _table;
  Staff? _server;
  bool _loadingTables = true;

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
    final halls = await repo.getHalls();
    final servers = await repo.getServers();
    if (!mounted) return;
    setState(() {
      _halls = halls;
      _servers = servers;
      _hall = halls.where((h) => h.id == _hall?.id).firstOrNull ??
          (halls.isNotEmpty ? halls.first : null);
      _server = servers.where((s) => s.id == _server?.id).firstOrNull ??
          (servers.isNotEmpty ? servers.first : null);
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

  int _count(TableStatus s) => _tables.where((t) => t.status == s).length;

  void _continue() {
    context
        .read<OrderProvider>()
        .setTableDetails(hall: _hall!, table: _table!, server: _server!);
    if (widget.changeOnly) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const MenuScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const small = TextStyle(fontSize: 11, color: AppColors.textSecondary);
    final hallIndex = _halls.indexWhere((h) => h.id == _hall?.id);
    final canContinue = _table != null && _server != null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Choose a table',
              subtitle: 'Dine-in · ${_hall?.name ?? ''}',
            ),
            if (_halls.isNotEmpty)
              PillScroller(
                options: [for (final h in _halls) h.name],
                selectedIndex: hallIndex,
                onChanged: (i) => _loadTables(_halls[i]),
              ),
            Expanded(
              child: _loadingTables
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Text('${_count(TableStatus.free)} free', style: small),
                      const Spacer(),
                      Flexible(
                        child: Text(
                          '${_count(TableStatus.occupied)} occupied · '
                              '${_count(TableStatus.billed)} bill',
                          style: small,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.6,
                    children: [
                      for (final t in _tables)
                        _TableTile(
                          table: t,
                          selected: t.id == _table?.id,
                          onTap: () => setState(() => _table = t),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Server',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in _servers)
                        Pill(
                          label: '${s.name} (${s.employeeCode})',
                          selected: s.id == _server?.id,
                          onTap: () => setState(() => _server = s),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (_table != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: NoteBanner(
                  text: 'T${_table!.tableNumber} selected · ${_table!.capacity} seats'
                      '${_server == null ? '' : ' · ${_server!.name}'}',
                  type: NoteType.success,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: PrimaryButton(
                label: widget.changeOnly ? 'Save table' : 'Continue to menu',
                onPressed: canContinue ? _continue : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableTile extends StatelessWidget {
  final DiningTable table;
  final bool selected;
  final VoidCallback onTap;

  const _TableTile({
    required this.table,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final free = table.status == TableStatus.free;
    final background = selected
        ? AppColors.darkGreen
        : free
        ? AppColors.card
        : AppColors.peach;
    final (statusText, statusColor) = selected
        ? ('Selected', Colors.white)
        : switch (table.status) {
      TableStatus.free => ('Free', AppColors.free),
      TableStatus.occupied => ('Occupied', AppColors.occupied),
      TableStatus.billed => ('Bill printed', AppColors.billed),
    };

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: free ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'T${table.tableNumber}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${table.capacity} seats',
                style: TextStyle(
                  fontSize: 11,
                  color: selected ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(statusText, style: TextStyle(fontSize: 11, color: statusColor)),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../data/pos_repository.dart';
import '../../models/models.dart';
import '../../widgets/admin_widgets.dart';

class FloorScreen extends StatefulWidget {
  const FloorScreen({super.key});

  @override
  State<FloorScreen> createState() => _FloorScreenState();
}

class _FloorScreenState extends State<FloorScreen> {
  List<Hall> _halls = [];
  Map<int, List<DiningTable>> _tables = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<PosRepository>();
    final halls = await repo.getHalls();
    final map = <int, List<DiningTable>>{};
    for (final h in halls) {
      map[h.id] = await repo.getTables(h.id);
    }
    if (!mounted) return;
    setState(() {
      _halls = halls;
      _tables = map;
      _loading = false;
    });
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    try {
      await action();
      if (!mounted) return;
      showMessage(context, success);
      _load();
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), error: true);
    }
  }

  Future<void> _hallForm([Hall? existing]) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(
        title: existing == null ? 'New Hall' : 'Edit Hall',
        label: 'Hall naam',
        hint: 'e.g. Rooftop, Family Hall',
        initial: existing?.name ?? '',
      ),
    );
    if (name == null || !mounted) return;
    final repo = context.read<PosRepository>();
    await _run(() => repo.saveHall(Hall(id: existing?.id ?? 0, name: name)),
        'Hall save ho gaya');
  }

  Future<void> _deleteHall(Hall h) async {
    if (!await confirmDelete(context, '"${h.name}"')) return;
    if (!mounted) return;
    final repo = context.read<PosRepository>();
    await _run(() => repo.deleteHall(h.id), '${h.name} delete ho gaya');
  }

  Future<void> _tableForm(Hall hall, [DiningTable? existing]) async {
    final list = _tables[hall.id] ?? [];
    final nextNo = list.isEmpty
        ? 1
        : list.map((t) => t.tableNumber).reduce((a, b) => a > b ? a : b) + 1;
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _TableDialog(
        hall: hall,
        existing: existing,
        suggestedNumber: nextNo,
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _tableActions(Hall hall, DiningTable t) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('${hall.name} - Table ${t.tableNumber}'),
              subtitle: Text('${t.capacity} seats'),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'edit') {
      _tableForm(hall, t);
    } else if (action == 'delete') {
      if (!await confirmDelete(context, 'Table ${t.tableNumber}')) return;
      if (!mounted) return;
      final repo = context.read<PosRepository>();
      await _run(() => repo.deleteTable(t.id), 'Table delete ho gayi');
    }
  }

  Color _statusColor(TableStatus s) => switch (s) {
        TableStatus.free => AppColors.free,
        TableStatus.occupied => AppColors.occupied,
        TableStatus.billed => AppColors.billed,
      };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Halls & Tables')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _hallForm(),
        icon: const Icon(Icons.add),
        label: const Text('Hall'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _halls.isEmpty
              ? const EmptyHint(
                  icon: Icons.table_restaurant, text: 'Pehle hall banao')
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                  children: [
                    for (final h in _halls)
                      Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 4, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${h.name}  (${_tables[h.id]?.length ?? 0} tables)',
                                      style: t.titleMedium,
                                    ),
                                  ),
                                  EditDeleteMenu(
                                    onEdit: () => _hallForm(h),
                                    onDelete: () => _deleteHall(h),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final tb in _tables[h.id] ?? <DiningTable>[])
                                    ActionChip(
                                      avatar: CircleAvatar(
                                        backgroundColor:
                                            _statusColor(tb.status),
                                        radius: 6,
                                      ),
                                      label: Text(
                                          'T${tb.tableNumber} · ${tb.capacity} seats'),
                                      onPressed: () => _tableActions(h, tb),
                                    ),
                                  ActionChip(
                                    avatar: const Icon(Icons.add, size: 18),
                                    label: const Text('Table'),
                                    onPressed: () => _tableForm(h),
                                  ),
                                ],
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

class _NameDialog extends StatefulWidget {
  final String title;
  final String label;
  final String hint;
  final String initial;

  const _NameDialog({
    required this.title,
    required this.label,
    required this.hint,
    required this.initial,
  });

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _done() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _ctrl.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration:
              InputDecoration(labelText: widget.label, hintText: widget.hint),
          validator: V.req,
          onFieldSubmitted: (_) => _done(),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(onPressed: _done, child: const Text('Save')),
      ],
    );
  }
}

class _TableDialog extends StatefulWidget {
  final Hall hall;
  final DiningTable? existing;
  final int suggestedNumber;

  const _TableDialog({
    required this.hall,
    this.existing,
    required this.suggestedNumber,
  });

  @override
  State<_TableDialog> createState() => _TableDialogState();
}

class _TableDialogState extends State<_TableDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _number;
  late final TextEditingController _capacity;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _number =
        TextEditingController(text: '${t?.tableNumber ?? widget.suggestedNumber}');
    _capacity = TextEditingController(text: '${t?.capacity ?? 4}');
  }

  @override
  void dispose() {
    _number.dispose();
    _capacity.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<PosRepository>().saveTable(DiningTable(
            id: widget.existing?.id ?? 0,
            hallId: widget.hall.id,
            tableNumber: int.parse(_number.text.trim()),
            capacity: int.parse(_capacity.text.trim()),
          ));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = errorText(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null
          ? 'New Table - ${widget.hall.name}'
          : 'Edit Table - ${widget.hall.name}'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _number,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Table number'),
                validator: V.intMin(1),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _capacity,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Seats'),
                validator: V.intMin(1),
              ),
              FormError(_error),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        SaveButton(saving: _saving, onPressed: _save),
      ],
    );
  }
}

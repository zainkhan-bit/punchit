import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/pos_repository.dart';
import '../../models/models.dart';
import '../../widgets/admin_widgets.dart';

class StationsScreen extends StatefulWidget {
  const StationsScreen({super.key});

  @override
  State<StationsScreen> createState() => _StationsScreenState();
}

class _StationsScreenState extends State<StationsScreen> {
  List<Station> _stations = [];
  List<MenuCategory> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<PosRepository>();
    final stations = await repo.getStations();
    final cats = await repo.getCategories();
    if (!mounted) return;
    setState(() {
      _stations = stations;
      _categories = cats;
      _loading = false;
    });
  }

  String _routesText(Station s) {
    if (s.type == StationType.expo) return 'Poora order (har item)';
    final names = _categories
        .where((c) => c.stationId == s.id)
        .map((c) => c.name)
        .join(', ');
    return names.isEmpty ? 'Koi category linked nahi' : names;
  }

  Future<void> _openForm([Station? existing]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _StationDialog(existing: existing),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Station s) async {
    if (!await confirmDelete(context, '"${s.name}"')) return;
    if (!mounted) return;
    try {
      await context.read<PosRepository>().deleteStation(s.id);
      if (!mounted) return;
      showMessage(context,
          '${s.name} delete ho gaya. Is ki categories ab sirf Cut Table pe jayengi.');
      _load();
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Kitchen Stations')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Station'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _stations.isEmpty
              ? const EmptyHint(icon: Icons.print, text: 'Koi station nahi')
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: _stations.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final s = _stations[i];
                    final printer = s.printerIp == null
                        ? 'Printer nahi (screen pe dikhega)'
                        : 'Printer ${s.printerIp}:${s.printerPort}';
                    return ListTile(
                      onTap: () => _openForm(s),
                      leading: Icon(
                        s.type == StationType.expo
                            ? Icons.receipt_long
                            : Icons.soup_kitchen,
                        color: s.isActive ? cs.primary : cs.outline,
                      ),
                      title: Text(
                          '${s.name}${s.isActive ? '' : '  (inactive)'}'),
                      subtitle: Text('${_routesText(s)}\n$printer'),
                      isThreeLine: true,
                      trailing: EditDeleteMenu(
                        onEdit: () => _openForm(s),
                        onDelete: () => _delete(s),
                      ),
                    );
                  },
                ),
    );
  }
}

class _StationDialog extends StatefulWidget {
  final Station? existing;

  const _StationDialog({this.existing});

  @override
  State<_StationDialog> createState() => _StationDialogState();
}

class _StationDialogState extends State<_StationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _ip;
  late final TextEditingController _port;
  late StationType _type;
  late bool _active;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _name = TextEditingController(text: s?.name ?? '');
    _ip = TextEditingController(text: s?.printerIp ?? '');
    _port = TextEditingController(text: '${s?.printerPort ?? 9100}');
    _type = s?.type ?? StationType.item;
    _active = s?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _ip.dispose();
    _port.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<PosRepository>().saveStation(Station(
            id: widget.existing?.id ?? 0,
            name: _name.text,
            type: _type,
            printerIp: _ip.text.trim().isEmpty ? null : _ip.text.trim(),
            printerPort: int.parse(_port.text.trim()),
            isActive: _active,
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
      title: Text(widget.existing == null ? 'New Station' : 'Edit Station'),
      content: SizedBox(
        width: 400,
        child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    labelText: 'Naam', hintText: 'e.g. Pizza Make Table'),
                validator: V.req,
              ),
              const SizedBox(height: 12),
              SegmentedButton<StationType>(
                segments: const [
                  ButtonSegment(
                      value: StationType.item, label: Text('Item station')),
                  ButtonSegment(
                      value: StationType.expo, label: Text('Cut Table')),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _type == StationType.item
                      ? 'Sirf apni categories ke items ka docket'
                      : 'Har order ka poora docket (saare items)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ip,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Printer IP (optional)',
                  hintText: '192.168.1.50',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _port,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Printer port'),
                validator: V.intMin(1),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
              FormError(_error),
            ],
          ),
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

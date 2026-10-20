import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/pos_repository.dart';
import '../../models/models.dart';
import '../../widgets/admin_widgets.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<MenuCategory> _categories = [];
  List<Station> _stations = [];
  Map<int, int> _productCount = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<PosRepository>();
    final cats = await repo.getCategories();
    final stations = await repo.getStations();
    final items = await repo.getMenuItems();
    if (!mounted) return;
    final count = <int, int>{};
    for (final i in items) {
      count[i.categoryId] = (count[i.categoryId] ?? 0) + 1;
    }
    setState(() {
      _categories = cats;
      _stations = stations;
      _productCount = count;
      _loading = false;
    });
  }

  String _stationName(int? id) {
    if (id == null) return 'Sirf Cut Table';
    for (final s in _stations) {
      if (s.id == id) return s.name;
    }
    return '-';
  }

  Future<void> _openForm([MenuCategory? existing]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _CategoryDialog(
        existing: existing,
        stations: _stations.where((s) => s.type == StationType.item).toList(),
        nextSortOrder: _categories.length + 1,
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(MenuCategory c) async {
    if (!await confirmDelete(context, '"${c.name}"')) return;
    if (!mounted) return;
    try {
      await context.read<PosRepository>().deleteCategory(c.id);
      if (!mounted) return;
      showMessage(context, '${c.name} delete ho gayi');
      _load();
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Category'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? const EmptyHint(
                  icon: Icons.category, text: 'Abhi koi category nahi')
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: _categories.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final c = _categories[i];
                    return ListTile(
                      leading: CircleAvatar(child: Text('${c.sortOrder}')),
                      title: Text(c.name),
                      subtitle: Text(
                          '${_productCount[c.id] ?? 0} products  ·  Print: ${_stationName(c.stationId)}'),
                      trailing: EditDeleteMenu(
                        onEdit: () => _openForm(c),
                        onDelete: () => _delete(c),
                      ),
                      onTap: () => _openForm(c),
                    );
                  },
                ),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  final MenuCategory? existing;
  final List<Station> stations;
  final int nextSortOrder;

  const _CategoryDialog({
    this.existing,
    required this.stations,
    required this.nextSortOrder,
  });

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _sort;
  int _stationId = 0;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _sort = TextEditingController(
        text: '${e?.sortOrder ?? widget.nextSortOrder}');
    final sid = e?.stationId;
    _stationId = widget.stations.any((s) => s.id == sid) ? sid! : 0;
  }

  @override
  void dispose() {
    _name.dispose();
    _sort.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<PosRepository>().saveCategory(MenuCategory(
            id: widget.existing?.id ?? 0,
            name: _name.text,
            stationId: _stationId == 0 ? null : _stationId,
            sortOrder: int.parse(_sort.text.trim()),
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
      title: Text(widget.existing == null ? 'New Category' : 'Edit Category'),
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
                autofocus: widget.existing == null,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Naam'),
                validator: V.req,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _stationId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Kitchen station (printer)',
                  helperText: 'Is category ke items kis station pe print hon',
                ),
                items: [
                  const DropdownMenuItem<int>(
                      value: 0, child: Text('Koi nahi (sirf Cut Table)')),
                  ...widget.stations.map((s) => DropdownMenuItem<int>(
                      value: s.id, child: Text(s.name))),
                ],
                onChanged: (v) => setState(() => _stationId = v ?? 0),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sort,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Order (menu mein position)',
                ),
                validator: V.intMin(0),
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

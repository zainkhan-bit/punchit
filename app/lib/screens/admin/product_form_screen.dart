import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/pos_repository.dart';
import '../../models/models.dart';
import '../../widgets/admin_widgets.dart';

/// Product add / edit. Save hone pe pop(true).
class ProductFormScreen extends StatefulWidget {
  final MenuItem? existing;
  final int? defaultCategoryId;

  const ProductFormScreen({super.key, this.existing, this.defaultCategoryId});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;

  List<MenuCategory> _categories = [];
  List<Station> _stations = [];
  List<ModifierGroup> _groups = [];

  int? _categoryId;
  int _stationId = 0; // 0 = category wala station
  bool _available = true;
  final Set<int> _groupIds = {};

  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _price = TextEditingController(
        text: e == null ? '' : e.price.toStringAsFixed(0));
    _categoryId = e?.categoryId ?? widget.defaultCategoryId;
    _stationId = e?.stationId ?? 0;
    _available = e?.isAvailable ?? true;
    _groupIds.addAll(e?.modifierGroups.map((g) => g.id) ?? const <int>[]);
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<PosRepository>();
    final cats = await repo.getCategories();
    final stations = await repo.getStations();
    final groups = await repo.getModifierGroups();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _stations = stations.where((s) => s.type == StationType.item).toList();
      _groups = groups;
      if (!_categories.any((c) => c.id == _categoryId)) {
        _categoryId = _categories.isNotEmpty ? _categories.first.id : null;
      }
      if (!_stations.any((s) => s.id == _stationId)) _stationId = 0;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  String get _categoryStationName {
    final cat = _categories.where((c) => c.id == _categoryId).firstOrNull;
    final st = _stations.where((s) => s.id == cat?.stationId).firstOrNull;
    return st?.name ?? 'sirf Cut Table';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<PosRepository>().saveMenuItem(MenuItem(
            id: widget.existing?.id ?? 0,
            categoryId: _categoryId!,
            name: _name.text,
            price: double.parse(_price.text.trim()),
            stationId: _stationId == 0 ? null : _stationId,
            isAvailable: _available,
            modifierGroups:
                _groups.where((g) => _groupIds.contains(g.id)).toList(),
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
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Product' : 'New Product')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Product naam',
                      hintText: 'e.g. Chicken Tikka Pizza (M)',
                    ),
                    validator: V.req,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _price,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      prefixText: 'Rs ',
                      helperText: 'Tax ke bagair (tax bill pe lagega)',
                    ),
                    validator: V.price,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: _categoryId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: _categories
                        .map((c) => DropdownMenuItem(
                            value: c.id, child: Text(c.name)))
                        .toList(),
                    validator: (v) => v == null ? 'Category select karo' : null,
                    onChanged: (v) => setState(() => _categoryId = v),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    // category badalne pe label update ho
                    key: ValueKey('station-$_categoryId'),
                    initialValue: _stationId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Kitchen station',
                      helperText:
                          'Sirf tab badlo jab yeh item category se alag station pe banta ho',
                    ),
                    items: [
                      DropdownMenuItem<int>(
                        value: 0,
                        child: Text('Category wala ($_categoryStationName)'),
                      ),
                      ..._stations.map((s) => DropdownMenuItem<int>(
                          value: s.id, child: Text(s.name))),
                    ],
                    onChanged: (v) => setState(() => _stationId = v ?? 0),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Available'),
                    subtitle: const Text(
                        'Off karo to server ko "Not available" dikhega'),
                    value: _available,
                    onChanged: (v) => setState(() => _available = v),
                  ),
                  const Divider(height: 32),
                  Text('Toppings / Options', style: t.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Jo groups select karoge woh is product pe punch karte waqt khulenge.',
                    style: t.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  if (_groups.isEmpty)
                    const Text(
                        'Koi topping group nahi. "Toppings & Options" se banao.')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _groups
                          .map((g) => FilterChip(
                                label: Text(
                                    '${g.name} (${g.options.length})'),
                                selected: _groupIds.contains(g.id),
                                onSelected: (sel) => setState(() {
                                  if (sel) {
                                    _groupIds.add(g.id);
                                  } else {
                                    _groupIds.remove(g.id);
                                  }
                                }),
                              ))
                          .toList(),
                    ),
                  FormError(_error),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      bottomNavigationBar: _loading
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: SaveButton(
                    saving: _saving,
                    onPressed: _save,
                    label: _isEdit ? 'Update Product' : 'Save Product',
                  ),
                ),
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../data/pos_repository.dart';
import '../../models/models.dart';
import '../../widgets/admin_widgets.dart';

/// Topping groups: Crust (ek select, zaroori), Extra Toppings (max 5) waghera
class ModifierGroupsScreen extends StatefulWidget {
  const ModifierGroupsScreen({super.key});

  @override
  State<ModifierGroupsScreen> createState() => _ModifierGroupsScreenState();
}

class _ModifierGroupsScreenState extends State<ModifierGroupsScreen> {
  List<ModifierGroup> _groups = [];
  Map<int, int> _usedBy = {}; // groupId -> kitne products pe laga hai
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<PosRepository>();
    final groups = await repo.getModifierGroups();
    final items = await repo.getMenuItems();
    if (!mounted) return;
    final used = <int, int>{};
    for (final it in items) {
      for (final g in it.modifierGroups) {
        used[g.id] = (used[g.id] ?? 0) + 1;
      }
    }
    setState(() {
      _groups = groups;
      _usedBy = used;
      _loading = false;
    });
  }

  String _rule(ModifierGroup g) {
    final req = g.minSelect > 0 ? 'Zaroori' : 'Optional';
    final sel = g.isSingle ? 'ek select' : 'max ${g.maxSelect} select';
    return '$req · $sel';
  }

  Future<void> _openForm([ModifierGroup? existing]) async {
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => ModifierGroupFormScreen(existing: existing),
    ));
    if (saved == true) _load();
  }

  Future<void> _delete(ModifierGroup g) async {
    final used = _usedBy[g.id] ?? 0;
    final what = used > 0
        ? '"${g.name}" ($used products se bhi hat jayega)'
        : '"${g.name}"';
    if (!await confirmDelete(context, what)) return;
    if (!mounted) return;
    try {
      await context.read<PosRepository>().deleteModifierGroup(g.id);
      if (!mounted) return;
      showMessage(context, '${g.name} delete ho gaya');
      _load();
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Toppings & Options')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Group'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? const EmptyHint(
                  icon: Icons.add_circle_outline,
                  text: 'Koi topping group nahi.\ne.g. "Crust", "Extra Toppings"')
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: _groups.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final g = _groups[i];
                    final names = g.options.map((o) => o.name).join(', ');
                    return ListTile(
                      onTap: () => _openForm(g),
                      title: Text(g.name),
                      subtitle: Text(
                        '${_rule(g)} · ${_usedBy[g.id] ?? 0} products\n$names',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      isThreeLine: true,
                      trailing: EditDeleteMenu(
                        onEdit: () => _openForm(g),
                        onDelete: () => _delete(g),
                      ),
                    );
                  },
                ),
    );
  }
}

// ======================= Group form =======================

class ModifierGroupFormScreen extends StatefulWidget {
  final ModifierGroup? existing;

  const ModifierGroupFormScreen({super.key, this.existing});

  @override
  State<ModifierGroupFormScreen> createState() =>
      _ModifierGroupFormScreenState();
}

class _ModifierGroupFormScreenState extends State<ModifierGroupFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _max;
  late bool _multiple;
  late bool _required;
  late List<ModifierOption> _options;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    _name = TextEditingController(text: g?.name ?? '');
    _multiple = g == null ? true : !g.isSingle;
    _required = (g?.minSelect ?? 0) > 0;
    _max = TextEditingController(
        text: '${g == null || g.isSingle ? 3 : g.maxSelect}');
    _options = List.of(g?.options ?? const <ModifierOption>[]);
  }

  @override
  void dispose() {
    _name.dispose();
    _max.dispose();
    super.dispose();
  }

  Future<void> _editOption([int? index]) async {
    final result = await showDialog<ModifierOption>(
      context: context,
      builder: (_) =>
          _OptionDialog(existing: index == null ? null : _options[index]),
    );
    if (result == null) return;
    setState(() {
      if (index == null) {
        _options.add(result);
      } else {
        _options[index] = result;
      }
    });
  }

  void _toggleOption(int index, bool available) {
    final o = _options[index];
    setState(() => _options[index] = ModifierOption(
        id: o.id, name: o.name, price: o.price, isAvailable: available));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_options.isEmpty) {
      setState(() => _error = 'Kam az kam 1 option add karo');
      return;
    }
    final max = _multiple ? int.parse(_max.text.trim()) : 1;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<PosRepository>().saveModifierGroup(ModifierGroup(
            id: widget.existing?.id ?? 0,
            name: _name.text,
            minSelect: _required ? 1 : 0,
            maxSelect: max,
            options: _options,
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
      appBar: AppBar(
          title: Text(widget.existing == null ? 'New Group' : 'Edit Group')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Group naam',
                hintText: 'e.g. Crust, Extra Toppings, Drink Size',
              ),
              validator: V.req,
            ),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                    value: false,
                    label: Text('Ek select'),
                    icon: Icon(Icons.radio_button_checked)),
                ButtonSegment(
                    value: true,
                    label: Text('Multiple'),
                    icon: Icon(Icons.check_box)),
              ],
              selected: {_multiple},
              onSelectionChanged: (s) => setState(() => _multiple = s.first),
            ),
            const SizedBox(height: 8),
            if (_multiple)
              TextFormField(
                controller: _max,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Maximum kitne select ho sakte hain',
                ),
                validator: V.intMin(1),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Zaroori (required)'),
              subtitle: const Text(
                  'ON = server ko kam az kam 1 select karna hi parega (e.g. Crust)'),
              value: _required,
              onChanged: (v) => setState(() => _required = v),
            ),
            const Divider(height: 24),
            Row(
              children: [
                Text('Options (${_options.length})', style: t.titleMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _editOption(),
                  icon: const Icon(Icons.add),
                  label: const Text('Option'),
                ),
              ],
            ),
            if (_options.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('e.g. Extra Cheese Rs 200, Olives Rs 100'),
              ),
            // Drag kar ke order badlo
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorderItem: (oldIndex, newIndex) => setState(() {
                _options.insert(newIndex, _options.removeAt(oldIndex));
              }),
              children: [
                for (var i = 0; i < _options.length; i++)
                  ListTile(
                    key: ObjectKey(_options[i]),
                    contentPadding: EdgeInsets.zero,
                    leading: ReorderableDragStartListener(
                      index: i,
                      child: const Icon(Icons.drag_handle),
                    ),
                    title: Text(_options[i].name),
                    subtitle: Text(_options[i].price > 0
                        ? '+ ${rs(_options[i].price)}'
                        : 'Free'),
                    onTap: () => _editOption(i),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: _options[i].isAvailable,
                          onChanged: (v) => _toggleOption(i, v),
                        ),
                        IconButton(
                          tooltip: 'Remove',
                          icon: const Icon(Icons.close),
                          onPressed: () =>
                              setState(() => _options.removeAt(i)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            FormError(_error),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: SaveButton(
                saving: _saving, onPressed: _save, label: 'Save Group'),
          ),
        ),
      ),
    );
  }
}

class _OptionDialog extends StatefulWidget {
  final ModifierOption? existing;

  const _OptionDialog({this.existing});

  @override
  State<_OptionDialog> createState() => _OptionDialogState();
}

class _OptionDialogState extends State<_OptionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;

  @override
  void initState() {
    super.initState();
    final o = widget.existing;
    _name = TextEditingController(text: o?.name ?? '');
    _price = TextEditingController(text: (o?.price ?? 0).toStringAsFixed(0));
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  void _done() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      ModifierOption(
        id: widget.existing?.id ?? 0, // 0 = naya, save pe id milegi
        name: _name.text.trim(),
        price: double.parse(_price.text.trim()),
        isAvailable: widget.existing?.isAvailable ?? true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'New Option' : 'Edit Option'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Naam'),
              validator: V.req,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Extra price',
                prefixText: 'Rs ',
                helperText: '0 = free (e.g. Regular crust)',
              ),
              validator: V.price,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(onPressed: _done, child: const Text('OK')),
      ],
    );
  }
}

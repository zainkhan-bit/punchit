import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/models.dart';

/// Item tap karne pe yeh sheet khulti hai: crust/toppings, qty, comment.
/// [existing] do to edit mode (Order Summary se).
Future<CartItem?> showItemOptionsSheet(
  BuildContext context,
  MenuItem item, {
  CartItem? existing,
}) {
  return showModalBottomSheet<CartItem>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ItemOptionsSheet(item: item, existing: existing),
  );
}

class _ItemOptionsSheet extends StatefulWidget {
  final MenuItem item;
  final CartItem? existing;

  const _ItemOptionsSheet({required this.item, this.existing});

  @override
  State<_ItemOptionsSheet> createState() => _ItemOptionsSheetState();
}

class _ItemOptionsSheetState extends State<_ItemOptionsSheet> {
  static const _quickNotes = [
    'Less spicy',
    'Extra spicy',
    'No onion',
    'Well done',
    'Sauce on side',
    'Cut in 8',
  ];

  // groupId -> selected option ids
  final Map<int, Set<int>> _selected = {};
  late int _qty;
  String? _error;
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    for (final g in widget.item.modifierGroups) {
      _selected[g.id] = {};
    }
    final ex = widget.existing;
    if (ex != null) {
      for (final m in ex.modifiers) {
        for (final g in widget.item.modifierGroups) {
          if (g.options.any((o) => o.id == m.id)) _selected[g.id]!.add(m.id);
        }
      }
    } else {
      // Required single-select group (jaise Crust) ka pehla option default
      for (final g in widget.item.modifierGroups) {
        if (g.isSingle && g.minSelect > 0 && g.availableOptions.isNotEmpty) {
          _selected[g.id]!.add(g.availableOptions.first.id);
        }
      }
    }
    _qty = ex?.quantity ?? 1;
    _noteCtrl = TextEditingController(text: ex?.note ?? '');
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  List<ModifierOption> get _selectedOptions => [
        for (final g in widget.item.modifierGroups)
          for (final o in g.options)
            if (_selected[g.id]!.contains(o.id)) o,
      ];

  double get _total =>
      (widget.item.price +
          _selectedOptions.fold(0.0, (s, o) => s + o.price)) *
      _qty;

  String? get _validationError {
    for (final g in widget.item.modifierGroups) {
      if (_selected[g.id]!.length < g.minSelect) return '${g.name} select karo';
    }
    return null;
  }

  void _toggle(ModifierGroup g, ModifierOption o) {
    final chosen = _selected[g.id]!;
    setState(() {
      _error = null;
      if (g.isSingle) {
        chosen
          ..clear()
          ..add(o.id);
      } else if (chosen.contains(o.id)) {
        chosen.remove(o.id);
      } else if (chosen.length < g.maxSelect) {
        chosen.add(o.id);
      } else {
        _error = '${g.name}: max ${g.maxSelect} select ho sakti hain';
      }
    });
  }

  void _addQuickNote(String n) {
    final cur = _noteCtrl.text.trim();
    if (cur.toLowerCase().contains(n.toLowerCase())) return;
    _noteCtrl.text = cur.isEmpty ? n : '$cur, $n';
  }

  void _submit() {
    final err = _validationError;
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    Navigator.of(context).pop(CartItem(
      item: widget.item,
      modifiers: _selectedOptions,
      quantity: _qty,
      note: _noteCtrl.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      // keyboard khulne pe sheet upar aaye
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(widget.item.name, style: t.titleLarge),
              subtitle: Text(rs(widget.item.price)),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final g in widget.item.modifierGroups) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        g.minSelect > 0
                            ? '${g.name} (required)'
                            : '${g.name} (max ${g.maxSelect})',
                        style: t.titleSmall,
                      ),
                    ),
                    for (final o in g.availableOptions)
                      g.isSingle
                          ? ListTile(
                              dense: true,
                              leading: Icon(
                                _selected[g.id]!.contains(o.id)
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: cs.primary,
                              ),
                              title: Text(o.name),
                              trailing: o.price > 0
                                  ? Text('+ ${rs(o.price)}')
                                  : null,
                              onTap: () => _toggle(g, o),
                            )
                          : CheckboxListTile(
                              dense: true,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: _selected[g.id]!.contains(o.id),
                              title: Text(o.name),
                              secondary: o.price > 0
                                  ? Text('+ ${rs(o.price)}')
                                  : null,
                              onChanged: (_) => _toggle(g, o),
                            ),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text('Comment', style: t.titleSmall),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _quickNotes
                          .map((n) => ActionChip(
                                label: Text(n),
                                onPressed: () => _addQuickNote(n),
                              ))
                          .toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: TextField(
                      controller: _noteCtrl,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        hintText: 'e.g. no onion, extra sauce',
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: TextStyle(color: cs.error)),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  IconButton.outlined(
                    icon: const Icon(Icons.remove),
                    onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                  ),
                  SizedBox(
                    width: 40,
                    child: Text('$_qty',
                        textAlign: TextAlign.center, style: t.titleLarge),
                  ),
                  IconButton.outlined(
                    icon: const Icon(Icons.add),
                    onPressed: () => setState(() => _qty++),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                      ),
                      onPressed: _submit,
                      child: Text(
                        '${widget.existing == null ? 'Add' : 'Update'}  ${rs(_total)}',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

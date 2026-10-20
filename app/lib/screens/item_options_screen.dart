import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/models.dart';
import '../widgets/ui_kit.dart';

class ItemOptionsScreen extends StatefulWidget {
  final MenuItem item;
  final CartItem? existing;

  const ItemOptionsScreen({super.key, required this.item, this.existing});

  static Future<CartItem?> open(BuildContext context, MenuItem item, {CartItem? existing}) {
    return Navigator.of(context).push<CartItem>(MaterialPageRoute(
      builder: (_) => ItemOptionsScreen(item: item, existing: existing),
    ));
  }

  @override
  State<ItemOptionsScreen> createState() => _ItemOptionsScreenState();
}

class _ItemOptionsScreenState extends State<ItemOptionsScreen> {
  static const _quickNotes = [
    'Less spicy',
    'Extra spicy',
    'No onion',
    'Well done',
    'Sauce on side',
    'Cut in 8',
  ];

  final Map<int, Set<int>> _selected = {};
  late int _qty;
  String? _error;
  late final TextEditingController _noteCtrl;

  MenuItem get _item => widget.item;

  @override
  void initState() {
    super.initState();
    for (final g in _item.modifierGroups) {
      _selected[g.id] = {};
    }
    final ex = widget.existing;
    if (ex != null) {
      for (final m in ex.modifiers) {
        for (final g in _item.modifierGroups) {
          if (g.options.any((o) => o.id == m.id)) _selected[g.id]!.add(m.id);
        }
      }
    } else {
      for (final g in _item.modifierGroups) {
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
    for (final g in _item.modifierGroups)
      for (final o in g.options)
        if (_selected[g.id]!.contains(o.id)) o,
  ];

  double get _total =>
      (_item.price + _selectedOptions.fold(0.0, (s, o) => s + o.price)) * _qty;

  String? get _validationError {
    for (final g in _item.modifierGroups) {
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
    setState(() => _noteCtrl.text = cur.isEmpty ? n : '$cur, $n');
  }

  void _submit() {
    final err = _validationError;
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    Navigator.of(context).pop(CartItem(
      item: _item,
      modifiers: _selectedOptions,
      quantity: _qty,
      note: _noteCtrl.text.trim(),
    ));
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Make it their way',
              subtitle: widget.existing == null ? _item.name : 'Edit · ${_item.name}',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Container(
                    height: 120,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.peach,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _item.name[0],
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _item.name,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        rs(_item.price),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  for (final g in _item.modifierGroups) ...[
                    _sectionTitle(g.minSelect > 0
                        ? '${g.name} · required'
                        : '${g.name} · max ${g.maxSelect}'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final o in g.availableOptions)
                          Pill(
                            label: '${_selected[g.id]!.contains(o.id) ? '✓ ' : ''}'
                                '${o.name}${o.price > 0 ? ' +${rs(o.price)}' : ''}',
                            selected: _selected[g.id]!.contains(o.id),
                            onTap: () => _toggle(g, o),
                          ),
                      ],
                    ),
                  ],
                  _sectionTitle('Kitchen note'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final n in _quickNotes)
                        Pill(label: n, selected: false, onTap: () => _addQuickNote(n)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LabeledField(
                    label: 'Comment',
                    controller: _noteCtrl,
                    hint: 'e.g. no onion, extra sauce',
                    maxLength: 100,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Quantity',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      _StepButton(
                        icon: Icons.remove,
                        onTap: _qty > 1 ? () => setState(() => _qty--) : null,
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '$_qty',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      _StepButton(icon: Icons.add, onTap: () => setState(() => _qty++)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_error != null) NoteBanner(text: _error!, type: NoteType.error),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: PrimaryButton(
                label: widget.existing == null
                    ? 'Add $_qty to order · ${rs(_total)}'
                    : 'Update · ${rs(_total)}',
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 18,
            color: onTap == null ? AppColors.divider : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

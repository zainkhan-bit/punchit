import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../data/pos_repository.dart';
import '../../models/models.dart';
import '../../widgets/admin_widgets.dart';
import 'product_form_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<MenuCategory> _categories = [];
  List<MenuItem> _items = [];
  int? _categoryFilter; // null = sab
  String _search = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<PosRepository>();
    final cats = await repo.getCategories();
    final items = await repo.getMenuItems();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _items = items;
      _loading = false;
    });
  }

  List<MenuItem> get _visible {
    final q = _search.toLowerCase();
    return _items.where((i) {
      if (_categoryFilter != null && i.categoryId != _categoryFilter) {
        return false;
      }
      return q.isEmpty || i.name.toLowerCase().contains(q);
    }).toList();
  }

  String _categoryName(int id) {
    for (final c in _categories) {
      if (c.id == id) return c.name;
    }
    return '-';
  }

  Future<void> _openForm([MenuItem? existing]) async {
    if (_categories.isEmpty) {
      showMessage(context, 'Pehle koi category banao', error: true);
      return;
    }
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => ProductFormScreen(
        existing: existing,
        defaultCategoryId: _categoryFilter,
      ),
    ));
    if (saved == true) _load();
  }

  /// "Item khatam" quick switch: form khole bina available / unavailable
  Future<void> _toggleAvailable(MenuItem item, bool value) async {
    try {
      await context.read<PosRepository>().saveMenuItem(MenuItem(
            id: item.id,
            categoryId: item.categoryId,
            name: item.name,
            price: item.price,
            stationId: item.stationId,
            isAvailable: value,
            modifierGroups: item.modifierGroups,
          ));
      if (!mounted) return;
      showMessage(context,
          '${item.name} ${value ? 'available' : 'unavailable (khatam)'}');
      _load();
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), error: true);
    }
  }

  Future<void> _delete(MenuItem item) async {
    if (!await confirmDelete(context, '"${item.name}"')) return;
    if (!mounted) return;
    try {
      await context.read<PosRepository>().deleteMenuItem(item.id);
      if (!mounted) return;
      showMessage(context, '${item.name} delete ho gaya');
      _load();
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final visible = _visible;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Product search karo',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v.trim()),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Product'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(
                  height: 56,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('Sab (${_items.length})'),
                          selected: _categoryFilter == null,
                          onSelected: (_) =>
                              setState(() => _categoryFilter = null),
                        ),
                      ),
                      ..._categories.map((c) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(c.name),
                              selected: _categoryFilter == c.id,
                              onSelected: (_) =>
                                  setState(() => _categoryFilter = c.id),
                            ),
                          )),
                    ],
                  ),
                ),
                Expanded(
                  child: visible.isEmpty
                      ? const EmptyHint(
                          icon: Icons.fastfood, text: 'Koi product nahi mila')
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 88),
                          itemCount: visible.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final it = visible[i];
                            final groups =
                                it.modifierGroups.map((g) => g.name).join(', ');
                            return ListTile(
                              onTap: () => _openForm(it),
                              title: Text(
                                it.name,
                                style: TextStyle(
                                  decoration: it.isAvailable
                                      ? null
                                      : TextDecoration.lineThrough,
                                ),
                              ),
                              subtitle: Text(
                                '${_categoryName(it.categoryId)}'
                                '${groups.isEmpty ? '' : '  ·  $groups'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              leading: Text(
                                rs(it.price),
                                style: TextStyle(
                                    color: cs.primary,
                                    fontWeight: FontWeight.bold),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(
                                    value: it.isAvailable,
                                    onChanged: (v) => _toggleAvailable(it, v),
                                  ),
                                  EditDeleteMenu(
                                    onEdit: () => _openForm(it),
                                    onDelete: () => _delete(it),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

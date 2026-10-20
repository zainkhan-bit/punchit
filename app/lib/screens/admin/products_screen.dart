import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../data/pos_repository.dart';
import '../../models/models.dart';
import '../../widgets/admin_widgets.dart';
import '../../widgets/ui_kit.dart';
import 'manager_nav.dart';
import 'product_form_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<MenuCategory> _categories = [];
  List<MenuItem> _items = [];
  int _tab = 0;
  int _categoryIndex = 0;
  String _search = '';
  String? _banner;
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

  int? get _categoryFilter =>
      _categoryIndex == 0 ? null : _categories[_categoryIndex - 1].id;

  List<MenuItem> get _visible {
    final q = _search.toLowerCase();
    return _items.where((i) {
      if (_tab == 1 && i.isAvailable) return false;
      if (_categoryFilter != null && i.categoryId != _categoryFilter) return false;
      return q.isEmpty || i.name.toLowerCase().contains(q);
    }).toList();
  }

  String _categoryName(int id) =>
      _categories.where((c) => c.id == id).firstOrNull?.name ?? '-';

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
    if (saved == true) {
      setState(() => _banner = existing == null
          ? 'Naya product menu mein add ho gaya.'
          : 'Changes save ho gaye. Server menu update ho gaya.');
      _load();
    }
  }

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
      setState(() => _banner = '${item.name} ab ${value ? 'available' : 'unavailable'} hai.');
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
      setState(() => _banner = '${item.name} delete ho gaya.');
      _load();
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final unavailable = _items.where((i) => !i.isAvailable).length;

    return Scaffold(
      bottomNavigationBar: RoleBottomNav(
        items: managerNavItems,
        currentIndex: 1,
        onTap: (i) => openManagerTab(context, i),
      ),
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Manage menu',
              subtitle: '${_items.length} products · ${_categories.length} categories',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  if (_banner != null) ...[
                    NoteBanner(text: _banner!, type: NoteType.success),
                    const SizedBox(height: 10),
                  ],
                  PillTabs(
                    options: ['All products', 'Unavailable · $unavailable'],
                    selectedIndex: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v.trim()),
                      decoration: const InputDecoration(
                        hintText: 'Search products',
                        hintStyle: TextStyle(fontSize: 13),
                        prefixIcon: Icon(Icons.search, size: 20),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            PillScroller(
              options: ['All', for (final c in _categories) c.name],
              selectedIndex: _categoryIndex,
              onChanged: (i) => setState(() => _categoryIndex = i),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : visible.isEmpty
                      ? const EmptyHint(icon: Icons.fastfood, text: 'Koi product nahi mila')
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            for (final it in visible)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _ProductCard(
                                  item: it,
                                  category: _categoryName(it.categoryId),
                                  onTap: () => _openForm(it),
                                  onToggle: (v) => _toggleAvailable(it, v),
                                  onDelete: () => _delete(it),
                                ),
                              ),
                          ],
                        ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: PrimaryButton(label: 'Add a product', onPressed: () => _openForm()),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final MenuItem item;
  final String category;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.item,
    required this.category,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final groups = item.modifierGroups.map((g) => g.name).join(', ');
    return InfoCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration: item.isAvailable ? null : TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$category · ${rs(item.price)} · ${item.isAvailable ? 'Available' : 'Unavailable'}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                if (groups.isNotEmpty)
                  Text(
                    groups,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.primary),
                  ),
              ],
            ),
          ),
          Switch(value: item.isAvailable, onChanged: onToggle),
          EditDeleteMenu(onEdit: onTap, onDelete: onDelete),
        ],
      ),
    );
  }
}

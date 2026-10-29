import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../data/pos_repository.dart';
import '../models/models.dart';
import '../providers/order_provider.dart';
import '../widgets/ui_kit.dart';
import 'choose_table_screen.dart';
import 'item_options_screen.dart';
import 'order_summary_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<MenuCategory> _categories = [];
  List<MenuItem> _items = [];
  int _categoryIndex = 0;
  String _search = '';
  final _searchCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() => _search = '');
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

  List<MenuItem> get _visibleItems {
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      return _items.where((i) => i.name.toLowerCase().contains(q)).toList();
    }
    if (_categories.isEmpty) return _items;
    final catId = _categories[_categoryIndex].id;
    return _items.where((i) => i.categoryId == catId).toList();
  }

  void _notAvailable(MenuItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.name} abhi available nahi')));
  }

  Future<void> _openOptions(MenuItem item) async {
    if (!item.isAvailable) return _notAvailable(item);
    final order = context.read<OrderProvider>();
    final cartItem = await ItemOptionsScreen.open(context, item);
    if (cartItem != null) order.addToCart(cartItem);
  }

  void _quickAdd(MenuItem item) {
    if (!item.isAvailable) return _notAvailable(item);
    if (item.modifierGroups.any((g) => g.minSelect > 0)) {
      _openOptions(item);
      return;
    }
    final order = context.read<OrderProvider>();
    final i = order.cart.indexWhere(
            (c) => c.item.id == item.id && c.modifiers.isEmpty && c.note.isEmpty);
    if (i == -1) {
      order.addToCart(CartItem(item: item, modifiers: []));
    } else {
      order.changeQty(i, 1);
    }
  }

  Future<bool> _confirmDiscard() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Order discard karna hai?'),
        content: const Text('Cart mein items hain, woh delete ho jayenge.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Nahi')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Haan, discard')),
        ],
      ),
    );
    return res ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderProvider>();
    final items = _visibleItems;
    final subtitle = order.isDineIn
        ? '${order.hall?.name ?? ''} · T${order.table?.tableNumber ?? '-'} · ${order.server?.name ?? ''}'
        : (order.customerName.isEmpty ? 'Takeaway' : 'Takeaway · ${order.customerName}');
    const small = TextStyle(fontSize: 10, color: AppColors.textSecondary);

    return PopScope(
      canPop: order.cart.isEmpty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await _confirmDiscard();
        if (discard && context.mounted) {
          order.resetOrder();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              ScreenHeader(
                title: 'Take an order',
                subtitle: subtitle,
                trailing: order.isDineIn
                    ? IconButton(
                  tooltip: 'Table badlo',
                  icon: const Icon(Icons.table_restaurant_outlined),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ChooseTableScreen(changeOnly: true),
                    ),
                  ),
                )
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _search = v.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search menu',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _search.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Search clear karo',
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: _clearSearch,
                            ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              if (_search.isEmpty && _categories.isNotEmpty)
                PillScroller(
                  options: [for (final c in _categories) c.name],
                  selectedIndex: _categoryIndex,
                  onChanged: (i) => setState(() => _categoryIndex = i),
                ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        Text(
                          _search.isNotEmpty
                              ? 'SEARCH RESULTS'
                              : _categories.isEmpty
                              ? 'MENU'
                              : _categories[_categoryIndex].name.toUpperCase(),
                          style: small,
                        ),
                        const Spacer(),
                        Text('${items.length} items', style: small),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('Koi item nahi mila')),
                      ),
                    for (final item in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _MenuItemCard(
                          item: item,
                          qtyInCart: order.cart
                              .where((c) => c.item.id == item.id)
                              .fold(0, (s, c) => s + c.quantity),
                          onTap: () => _openOptions(item),
                          onAdd: () => _quickAdd(item),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: PrimaryButton(
                  label: order.cart.isEmpty
                      ? 'Items add karo'
                      : 'View order · ${order.itemCount} items · ${rs(order.subtotal)}',
                  onPressed: order.cart.isEmpty
                      ? null
                      : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const OrderSummaryScreen()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final int qtyInCart;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _MenuItemCard({
    required this.item,
    required this.qtyInCart,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final details = !item.isAvailable
        ? 'Not available'
        : item.hasOptions
        ? item.modifierGroups.map((g) => g.name).join(' · ')
        : 'Tap for comment & qty';

    return Opacity(
      opacity: item.isAvailable ? 1 : 0.45,
      child: InfoCard(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.peach,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                item.name[0],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    details,
                    style: TextStyle(
                      fontSize: 11,
                      color: item.isAvailable
                          ? AppColors.textSecondary
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                  Text(
                    rs(item.price),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            if (qtyInCart > 0)
              Text('×$qtyInCart',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            IconButton(
              tooltip: 'Add',
              onPressed: onAdd,
              icon: const Icon(Icons.add, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

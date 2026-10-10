import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../data/pos_repository.dart';
import '../models/models.dart';
import '../providers/order_provider.dart';
import '../widgets/item_options_sheet.dart';
import '../widgets/table_select_sheet.dart';
import 'order_summary_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<MenuCategory> _categories = [];
  List<MenuItem> _items = [];
  int? _selectedCategoryId;
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
      _selectedCategoryId = cats.isNotEmpty ? cats.first.id : null;
      _loading = false;
    });
  }

  List<MenuItem> get _visibleItems {
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      return _items.where((i) => i.name.toLowerCase().contains(q)).toList();
    }
    return _items.where((i) => i.categoryId == _selectedCategoryId).toList();
  }

  Future<void> _onItemTap(MenuItem item) async {
    if (!item.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name} abhi available nahi')));
      return;
    }
    final order = context.read<OrderProvider>();
    final wasEmpty = order.cart.isEmpty;

    final cartItem = await showItemOptionsSheet(context, item);
    if (cartItem == null || !mounted) return;
    order.addToCart(cartItem);

    // Pehla item add hua -> table/customer details lo
    if (wasEmpty) {
      if (order.isDineIn && !order.hasTableDetails) {
        await showTableSelectSheet(context);
      } else if (!order.isDineIn) {
        await showCustomerSheet(context);
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${cartItem.quantity} x ${item.name} added'),
        duration: const Duration(seconds: 1),
      ));
    }
  }

  Future<bool> _confirmDiscard() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Order discard karna hai?'),
        content: const Text('Cart mein items hain, woh delete ho jayenge.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Nahi')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Haan, discard')),
        ],
      ),
    );
    return res ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderProvider>();

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
        appBar: AppBar(
          title: Text(order.isDineIn ? 'Dine-in' : 'Takeaway'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Item search karo',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _search = v.trim()),
              ),
            ),
          ),
          actions: [
            if (order.cart.isNotEmpty) _OrderInfoChip(order: order),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (_search.isEmpty)
                    SizedBox(
                      height: 56,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        children: _categories
                            .map((c) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(c.name),
                                    selected: c.id == _selectedCategoryId,
                                    onSelected: (_) => setState(
                                        () => _selectedCategoryId = c.id),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 220,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.25,
                      ),
                      itemCount: _visibleItems.length,
                      itemBuilder: (_, i) => _MenuItemCard(
                        item: _visibleItems[i],
                        qtyInCart: order.cart
                            .where((c) => c.item.id == _visibleItems[i].id)
                            .fold(0, (s, c) => s + c.quantity),
                        onTap: () => _onItemTap(_visibleItems[i]),
                      ),
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: order.cart.isEmpty
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const OrderSummaryScreen()),
                    ),
                    child: Text(
                        'View Order (${order.itemCount})   ${rs(order.subtotal)}'),
                  ),
                ),
              ),
      ),
    );
  }
}

class _OrderInfoChip extends StatelessWidget {
  final OrderProvider order;

  const _OrderInfoChip({required this.order});

  @override
  Widget build(BuildContext context) {
    final label = order.isDineIn
        ? (order.table == null
            ? 'Table select karo'
            : '${order.hall!.name} T${order.table!.tableNumber} · ${order.server!.name}')
        : (order.customerName.isEmpty ? 'Customer' : order.customerName);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(order.isDineIn ? Icons.table_restaurant : Icons.person,
            size: 18),
        label: Text(label),
        onPressed: () => order.isDineIn
            ? showTableSelectSheet(context)
            : showCustomerSheet(context),
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final int qtyInCart;
  final VoidCallback onTap;

  const _MenuItemCard({
    required this.item,
    required this.qtyInCart,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Opacity(
      opacity: item.isAvailable ? 1 : 0.45,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.titleSmall),
                    const Spacer(),
                    Row(
                      children: [
                        Text(rs(item.price),
                            style: t.titleMedium?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.bold)),
                        const Spacer(),
                        if (item.hasOptions)
                          Icon(Icons.tune, size: 18, color: cs.outline),
                      ],
                    ),
                    if (!item.isAvailable)
                      Text('Not available',
                          style: t.bodySmall?.copyWith(color: cs.error)),
                  ],
                ),
              ),
              if (qtyInCart > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: cs.primary,
                    child: Text('$qtyInCart',
                        style: TextStyle(color: cs.onPrimary, fontSize: 12)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

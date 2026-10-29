import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/bill_calculator.dart';
import '../data/pos_repository.dart';
import '../models/models.dart';
import '../providers/order_provider.dart';
import '../widgets/ui_kit.dart';
import 'choose_table_screen.dart';
import 'item_options_screen.dart';
import 'order_sent_screen.dart';
import 'order_type_screen.dart';

class OrderSummaryScreen extends StatefulWidget {
  const OrderSummaryScreen({super.key});

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  bool _sending = false;
  String? _error;

  AppSettings? _settings;
  List<PaymentMethod> _methods = [];

  @override
  void initState() {
    super.initState();
    _loadTaxInfo();
  }

  Future<void> _loadTaxInfo() async {
    final repo = context.read<PosRepository>();
    final settings = await repo.getSettings();
    final methods = await repo.getPaymentMethods();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _methods = methods.where((m) => m.isActive).toList();
    });
  }

  Future<void> _editItem(int index) async {
    final order = context.read<OrderProvider>();
    final current = order.cart[index];
    final updated = await ItemOptionsScreen.open(context, current.item, existing: current);
    if (updated != null) order.updateCartItem(index, updated);
  }

  Future<void> _clearCart() async {
    final order = context.read<OrderProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Saare items hata dein?'),
        content: const Text('Cart khali ho jayega. Table aur customer wahi rahenge.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Nahi')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Haan, clear')),
        ],
      ),
    );
    if (ok == true) order.clearCart();
  }

  Future<void> _sendToKitchen() async {
    final order = context.read<OrderProvider>();
    final repo = context.read<PosRepository>();

    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final orderId = await repo.placeOrder(
        type: order.orderType!,
        tableId: order.table?.id,
        serverId: order.server?.id ?? order.loggedInStaff!.id,
        customerName: order.customerName.isEmpty ? null : order.customerName,
        customerPhone: order.customerPhone.isEmpty ? null : order.customerPhone,
        items: List.of(order.cart),
      );
      final placed = (await repo.getOrders()).firstWhere((o) => o.id == orderId);
      if (!mounted) return;
      order.resetOrder();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => OrderSentScreen(order: placed)),
        ModalRoute.withName(OrderTypeScreen.routeName),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderProvider>();
    final subtitle = order.isDineIn
        ? '${order.hall?.name ?? ''} · T${order.table?.tableNumber ?? '-'} · ${order.itemCount} items'
        : 'Takeaway · ${order.itemCount} items';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Review order',
              subtitle: subtitle,
              trailing: order.isDineIn
                  ? IconButton(
                tooltip: 'Table badlo',
                icon: const Icon(Icons.table_restaurant_outlined),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const ChooseTableScreen(changeOnly: true),
                )),
              )
                  : null,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (!order.isDineIn) ...[
                    LabeledField(
                      label: 'Customer name (optional)',
                      initialValue: order.customerName,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (v) => order.setCustomer(v.trim(), order.customerPhone),
                    ),
                    const SizedBox(height: 10),
                    LabeledField(
                      label: 'Phone (optional)',
                      initialValue: order.customerPhone,
                      keyboardType: TextInputType.phone,
                      onChanged: (v) => order.setCustomer(order.customerName, v.trim()),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (order.cart.isEmpty)
                    const NoteBanner(text: 'Cart khali hai. Wapas ja kar items add karo.')
                  else
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _sending ? null : _clearCart,
                        icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                        label: const Text('Clear cart'),
                      ),
                    ),
                  for (var i = 0; i < order.cart.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CartLine(
                        cartItem: order.cart[i],
                        onEdit: () => _editItem(i),
                        onMinus: () => order.changeQty(i, -1),
                        onPlus: () => order.changeQty(i, 1),
                        onDelete: () => order.removeFromCart(i),
                      ),
                    ),
                  if (order.cart.isNotEmpty) ...[
                    const Text(
                      'Item pe tap = edit · left swipe = delete',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    AmountRow('Subtotal', rs(order.subtotal), bold: true),
                    if (_settings != null && _methods.isNotEmpty)
                      _TaxPreview(
                        subtotal: order.subtotal,
                        isDineIn: order.isDineIn,
                        settings: _settings!,
                        methods: _methods,
                      ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    NoteBanner(text: _error!, type: NoteType.error),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Add items',
                      onPressed: _sending ? null : () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      label: 'Send to kitchen',
                      loading: _sending,
                      onPressed: order.cart.isEmpty ? null : _sendToKitchen,
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

class _CartLine extends StatelessWidget {
  final CartItem cartItem;
  final VoidCallback onEdit;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onDelete;

  const _CartLine({
    required this.cartItem,
    required this.onEdit,
    required this.onMinus,
    required this.onPlus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = cartItem;
    return Dismissible(
      key: ObjectKey(c),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.peach,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.primary),
      ),
      onDismissed: (_) => onDelete(),
      child: InfoCard(
        onTap: onEdit,
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${c.quantity} × ${c.item.name}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  if (c.modifiers.isNotEmpty)
                    Text(
                      c.modifiers
                          .map((m) => m.price > 0 ? '${m.name} (+${rs(m.price)})' : m.name)
                          .join(' · '),
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  if (c.note.isNotEmpty)
                    Text(
                      '** ${c.note} **',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    rs(c.lineTotal),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: onMinus),
            Text('${c.quantity}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: onPlus),
          ],
        ),
      ),
    );
  }
}

class _TaxPreview extends StatelessWidget {
  final double subtotal;
  final bool isDineIn;
  final AppSettings settings;
  final List<PaymentMethod> methods;

  const _TaxPreview({
    required this.subtotal,
    required this.isDineIn,
    required this.settings,
    required this.methods,
  });

  String _pct(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bill estimate (payment ke hisaab se)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            for (final m in methods)
              Builder(builder: (_) {
                final b = BillCalculator.calculate(
                  subtotal: subtotal,
                  method: m,
                  settings: settings,
                  isDineIn: isDineIn,
                );
                final service =
                b.serviceCharge > 0 ? ' + service ${rs(b.serviceCharge)}' : '';
                return AmountRow(
                  '${m.name} (tax ${_pct(m.taxPercent)}% = ${rs(b.tax)}$service)',
                  rs(b.total),
                );
              }),
          ],
        ),
      ),
    );
  }
}

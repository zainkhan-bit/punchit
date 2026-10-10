import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/bill_calculator.dart';
import '../data/pos_repository.dart';
import '../models/models.dart';
import '../providers/order_provider.dart';
import '../widgets/item_options_sheet.dart';
import '../widgets/table_select_sheet.dart';
import 'order_type_screen.dart';

class OrderSummaryScreen extends StatefulWidget {
  const OrderSummaryScreen({super.key});

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  bool _sending = false;

  // Tax preview ke liye (Manager panel mein set hota hai)
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
    final updated =
        await showItemOptionsSheet(context, current.item, existing: current);
    if (updated != null) order.updateCartItem(index, updated);
  }

  Future<void> _sendToKitchen() async {
    final order = context.read<OrderProvider>();
    final repo = context.read<PosRepository>();

    if (order.isDineIn && !order.hasTableDetails) {
      final ok = await showTableSelectSheet(context);
      if (!ok || !mounted) return;
    }

    setState(() => _sending = true);
    try {
      final orderId = await repo.placeOrder(
        type: order.orderType!,
        tableId: order.table?.id,
        serverId: order.server?.id ?? order.loggedInStaff!.id,
        customerName: order.customerName.isEmpty ? null : order.customerName,
        customerPhone:
            order.customerPhone.isEmpty ? null : order.customerPhone,
        items: List.of(order.cart),
      );
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: AppColors.free, size: 48),
          title: Text('Order #$orderId sent'),
          content: Text(order.isDineIn
              ? '${order.hall!.name} - Table ${order.table!.tableNumber}\nKitchen ko bhej diya gaya.'
              : 'Takeaway order kitchen ko bhej diya gaya.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('New Order'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      order.resetOrder();
      // Wapas Order Type screen pe
      Navigator.of(context)
          .popUntil(ModalRoute.withName(OrderTypeScreen.routeName));
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderProvider>();
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Order Summary')),
      body: order.cart.isEmpty
          ? const Center(child: Text('Cart khali hai'))
          : ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                // ----- Header: table / customer -----
                Card(
                  margin: const EdgeInsets.all(12),
                  child: ListTile(
                    leading: Icon(order.isDineIn
                        ? Icons.table_restaurant
                        : Icons.takeout_dining),
                    title: Text(order.isDineIn
                        ? (order.table == null
                            ? 'Table select nahi hui'
                            : '${order.hall!.name} - Table ${order.table!.tableNumber}')
                        : 'Takeaway${order.customerName.isEmpty ? '' : ' - ${order.customerName}'}'),
                    subtitle: Text(order.isDineIn
                        ? 'Server: ${order.server?.name ?? '-'}'
                        : (order.customerPhone.isEmpty
                            ? 'Phone: -'
                            : 'Phone: ${order.customerPhone}')),
                    trailing: const Icon(Icons.edit),
                    onTap: () => order.isDineIn
                        ? showTableSelectSheet(context)
                        : showCustomerSheet(context),
                  ),
                ),

                // ----- Items -----
                for (var i = 0; i < order.cart.length; i++)
                  _CartLine(
                    cartItem: order.cart[i],
                    onEdit: () => _editItem(i),
                    onMinus: () => order.changeQty(i, -1),
                    onPlus: () => order.changeQty(i, 1),
                    onDelete: () => order.removeFromCart(i),
                  ),

                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text('Subtotal', style: t.titleMedium),
                      const Spacer(),
                      Text(rs(order.subtotal),
                          style: t.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                if (_settings != null && _methods.isNotEmpty)
                  _TaxPreview(
                    subtotal: order.subtotal,
                    isDineIn: order.isDineIn,
                    settings: _settings!,
                    methods: _methods,
                  ),
              ],
            ),
      bottomNavigationBar: order.cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52)),
                        onPressed:
                            _sending ? null : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Items'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                        ),
                        onPressed: _sending ? null : _sendToKitchen,
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send),
                        label: const Text('Send to Kitchen'),
                      ),
                    ),
                  ],
                ),
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
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final c = cartItem;

    return Dismissible(
      key: ObjectKey(c),
      direction: DismissDirection.endToStart,
      background: Container(
        color: cs.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: cs.onError),
      ),
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.item.name, style: t.titleSmall),
                    for (final m in c.modifiers)
                      Text(
                        '+ ${m.name}${m.price > 0 ? '  (${rs(m.price)})' : ''}',
                        style: t.bodySmall,
                      ),
                    if (c.note.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('** ${c.note} **',
                            style: t.bodySmall?.copyWith(
                                color: cs.error,
                                fontStyle: FontStyle.italic)),
                      ),
                    const SizedBox(height: 4),
                    Text(rs(c.lineTotal),
                        style: t.bodyMedium?.copyWith(
                            color: cs.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: onMinus),
              SizedBox(
                width: 24,
                child: Text('${c.quantity}',
                    textAlign: TextAlign.center, style: t.titleMedium),
              ),
              IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: onPlus),
            ],
          ),
        ),
      ),
    );
  }
}

/// Har payment method pe total kitna banega (Cash vs Card tax difference)
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
    final t = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bill estimate (payment ke hisaab se)', style: t.titleSmall),
            const SizedBox(height: 8),
            for (final m in methods)
              Builder(builder: (_) {
                final b = BillCalculator.calculate(
                  subtotal: subtotal,
                  method: m,
                  settings: settings,
                  isDineIn: isDineIn,
                );
                final service = b.serviceCharge > 0
                    ? ' + service ${rs(b.serviceCharge)}'
                    : '';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${m.name}  (tax ${_pct(m.taxPercent)}% = ${rs(b.tax)}$service)',
                          style: t.bodyMedium,
                        ),
                      ),
                      Text(rs(b.total),
                          style: t.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 4),
            Text('Discount bill banate waqt lagega.', style: t.bodySmall),
          ],
        ),
      ),
    );
  }
}

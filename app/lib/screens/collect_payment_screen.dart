import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/bill_calculator.dart';
import '../data/pos_repository.dart';
import '../models/models.dart';
import '../widgets/ui_kit.dart';
import 'payment_complete_screen.dart';

class CollectPaymentScreen extends StatefulWidget {
  final PlacedOrder order;

  const CollectPaymentScreen({super.key, required this.order});

  @override
  State<CollectPaymentScreen> createState() => _CollectPaymentScreenState();
}

class _CollectPaymentScreenState extends State<CollectPaymentScreen> {
  AppSettings? _settings;
  List<PaymentMethod> _methods = [];
  int _methodIndex = 0;
  final _cashCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  bool _paying = false;
  String? _error;

  PlacedOrder get _order => widget.order;
  PaymentMethod? get _method => _methods.isEmpty ? null : _methods[_methodIndex];
  bool get _isCash => _method?.name.toLowerCase() == 'cash';

  BillBreakdown? get _bill => _method == null || _settings == null
      ? null
      : BillCalculator.calculate(
    subtotal: _order.subtotal,
    discount: _discount,
    method: _method!,
    settings: _settings!,
    isDineIn: _order.isDineIn,
  );

  double get _discount =>
      double.tryParse(_discountCtrl.text.replaceAll(',', '').trim()) ?? 0;

  bool get _discountTooBig => _discount > _order.subtotal;

  double get _cashReceived => double.tryParse(_cashCtrl.text.replaceAll(',', '').trim()) ?? 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _cashCtrl.dispose();
    _refCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = context.read<PosRepository>();
    final settings = await repo.getSettings();
    final methods = (await repo.getPaymentMethods()).where((m) => m.isActive).toList();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _methods = methods;
    });
    _onMethodChanged(0);
  }

  void _onMethodChanged(int i) {
    setState(() {
      _methodIndex = i;
      _error = null;
      final total = _bill?.total ?? 0;
      _cashCtrl.text = ((total / 500).ceil() * 500).toStringAsFixed(0);
      _refCtrl.text = 'TXN-${_order.id}-${_method?.name.substring(0, 1).toUpperCase() ?? ''}';
    });
  }

  bool get _canPay {
    final bill = _bill;
    if (bill == null || _discount < 0 || _discountTooBig) return false;
    return _isCash ? _cashReceived >= bill.total : _refCtrl.text.trim().isNotEmpty;
  }

  Future<void> _pay() async {
    setState(() {
      _paying = true;
      _error = null;
    });
    try {
      final paid = await context.read<PosRepository>().payOrder(
        orderId: _order.id,
        method: _method!,
        discount: _discount,
        amountReceived: _isCash ? _cashReceived : _bill!.total,
        reference: _isCash ? '' : _refCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
        builder: (_) => PaymentCompleteScreen(order: paid, settings: _settings!),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _paying = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _pct(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final bill = _bill;
    const greenText = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.green);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Collect payment',
              subtitle: 'Order #${_order.id} · ${_order.label}',
            ),
            Expanded(
              child: bill == null
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.payments_outlined, color: AppColors.green),
                        const SizedBox(height: 10),
                        Text(
                          rs(bill.total),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_order.itemCount} items · ${_order.statusLabel}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  AmountRow('Subtotal', rs(bill.subtotal)),
                  if (bill.discount > 0) AmountRow('Discount', '- ${rs(bill.discount)}'),
                  if (bill.serviceCharge > 0)
                    AmountRow(
                      'Service charge · ${_pct(_settings!.serviceChargePercent)}%',
                      rs(bill.serviceCharge),
                    ),
                  AmountRow('Tax · ${_pct(bill.taxPercent)}% (${_method!.name})', rs(bill.tax)),
                  const Divider(color: AppColors.divider, height: 20),
                  AmountRow('Total', rs(bill.total), bold: true),
                  const SizedBox(height: 12),
                  LabeledField(
                    label: 'Discount (Rs)',
                    controller: _discountCtrl,
                    hint: '0',
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_discountTooBig) ...[
                    const SizedBox(height: 8),
                    const NoteBanner(
                      text: 'Discount subtotal se zyada nahi ho sakta',
                      type: NoteType.error,
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    'Payment method',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  PillTabs(
                    options: [for (final m in _methods) m.name],
                    selectedIndex: _methodIndex,
                    onChanged: _onMethodChanged,
                  ),
                  const SizedBox(height: 12),
                  if (_isCash) ...[
                    LabeledField(
                      key: ValueKey('cash-$_methodIndex'),
                      label: 'Cash received',
                      controller: _cashCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Change to return', style: greenText),
                        const Spacer(),
                        Text(
                          _cashReceived >= bill.total
                              ? rs(_cashReceived - bill.total)
                              : 'Kam hai: ${rs(bill.total - _cashReceived)}',
                          style: greenText.copyWith(
                            color: _cashReceived >= bill.total
                                ? AppColors.green
                                : Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    LabeledField(
                      key: ValueKey('ref-$_methodIndex'),
                      label: '${_method!.name} reference',
                      controller: _refCtrl,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Payment status', style: greenText),
                        const Spacer(),
                        Text(
                          _refCtrl.text.trim().isEmpty ? 'Pending' : 'Verified',
                          style: greenText,
                        ),
                      ],
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
              child: PrimaryButton(
                label: _isCash ? 'Confirm cash payment' : 'Record ${_method?.name ?? ''} payment',
                loading: _paying,
                onPressed: _canPay ? _pay : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

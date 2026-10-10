import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/bill_calculator.dart';
import '../../data/pos_repository.dart';
import '../../models/models.dart';
import '../../widgets/admin_widgets.dart';

/// Payment methods ka tax (Cash / Card alag), service charge, restaurant info.
/// Tax rates owner apne area ke hisaab se khud set kare.
class TaxSettingsScreen extends StatefulWidget {
  const TaxSettingsScreen({super.key});

  @override
  State<TaxSettingsScreen> createState() => _TaxSettingsScreenState();
}

class _TaxSettingsScreenState extends State<TaxSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _service = TextEditingController();
  final _footer = TextEditingController();
  bool _serviceDineInOnly = true;

  List<PaymentMethod> _methods = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _service.dispose();
    _footer.dispose();
    super.dispose();
  }

  String _pct(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  Future<void> _load({bool settingsToo = true}) async {
    final repo = context.read<PosRepository>();
    final methods = await repo.getPaymentMethods();
    final settings = settingsToo ? await repo.getSettings() : null;
    if (!mounted) return;
    setState(() {
      _methods = methods;
      if (settings != null) {
        _name.text = settings.restaurantName;
        _service.text = _pct(settings.serviceChargePercent);
        _footer.text = settings.receiptFooter;
        _serviceDineInOnly = settings.serviceChargeDineInOnly;
      }
      _loading = false;
    });
  }

  /// Form ki abhi wali values (save se pehle preview ke liye)
  AppSettings get _draftSettings => AppSettings(
        restaurantName: _name.text.trim(),
        serviceChargePercent: double.tryParse(_service.text.trim()) ?? 0,
        serviceChargeDineInOnly: _serviceDineInOnly,
        receiptFooter: _footer.text.trim(),
      );

  Future<void> _methodForm([PaymentMethod? existing]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _PaymentMethodDialog(existing: existing),
    );
    if (saved == true) _load(settingsToo: false);
  }

  Future<void> _deleteMethod(PaymentMethod m) async {
    if (!await confirmDelete(context, '"${m.name}"')) return;
    if (!mounted) return;
    try {
      await context.read<PosRepository>().deletePaymentMethod(m.id);
      if (!mounted) return;
      showMessage(context, '${m.name} delete ho gaya');
      _load(settingsToo: false);
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), error: true);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<PosRepository>().saveSettings(_draftSettings);
      if (!mounted) return;
      setState(() => _saving = false);
      showMessage(context, 'Settings save ho gayi');
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Tax & Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ---------- Payment methods ----------
                  Row(
                    children: [
                      Expanded(
                          child: Text('Payment methods & tax',
                              style: t.titleMedium)),
                      TextButton.icon(
                        onPressed: () => _methodForm(),
                        icon: const Icon(Icons.add),
                        label: const Text('Method'),
                      ),
                    ],
                  ),
                  Text(
                    'Har method ka apna tax rate. e.g. Cash aur Card pe alag tax.',
                    style: t.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        for (final m in _methods)
                          ListTile(
                            onTap: () => _methodForm(m),
                            leading: Icon(
                              m.name.toLowerCase().contains('cash')
                                  ? Icons.payments
                                  : Icons.credit_card,
                              color: m.isActive ? cs.primary : cs.outline,
                            ),
                            title: Text(
                                '${m.name}${m.isActive ? '' : '  (inactive)'}'),
                            subtitle: Text('Tax ${_pct(m.taxPercent)}%'),
                            trailing: EditDeleteMenu(
                              onEdit: () => _methodForm(m),
                              onDelete: () => _deleteMethod(m),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ---------- Live example ----------
                  const SizedBox(height: 12),
                  _ExampleBill(
                    methods: _methods.where((m) => m.isActive).toList(),
                    settings: _draftSettings,
                  ),

                  // ---------- Restaurant settings ----------
                  const Divider(height: 40),
                  Text('Restaurant', style: t.titleMedium),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Restaurant naam (bill pe print hoga)',
                    ),
                    validator: V.req,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _service,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Service charge',
                      suffixText: '%',
                      helperText: '0 = service charge nahi',
                    ),
                    validator: V.percent,
                    onChanged: (_) => setState(() {}), // preview update
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Service charge sirf Dine-in pe'),
                    subtitle: const Text('Takeaway pe nahi lagega'),
                    value: _serviceDineInOnly,
                    onChanged: (v) => setState(() => _serviceDineInOnly = v),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _footer,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Bill ke neeche message',
                      hintText: 'e.g. Thank you! Dobara zaroor aayein.',
                    ),
                  ),
                  FormError(_error),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      bottomNavigationBar: _loading
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: SaveButton(
                    saving: _saving,
                    onPressed: _saveSettings,
                    label: 'Save Settings',
                  ),
                ),
              ),
            ),
    );
  }
}

/// Rs 1,000 ke dine-in bill pe har method ka total
class _ExampleBill extends StatelessWidget {
  final List<PaymentMethod> methods;
  final AppSettings settings;

  const _ExampleBill({required this.methods, required this.settings});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Example: Rs 1,000 ka dine-in order', style: t.titleSmall),
            const SizedBox(height: 6),
            for (final m in methods)
              Builder(builder: (_) {
                final b = BillCalculator.calculate(
                  subtotal: 1000,
                  method: m,
                  settings: settings,
                  isDineIn: true,
                );
                final service = b.serviceCharge > 0
                    ? ' + service ${rs(b.serviceCharge)}'
                    : '';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text('${m.name}: tax ${rs(b.tax)}$service')),
                      Text(rs(b.total),
                          style: t.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodDialog extends StatefulWidget {
  final PaymentMethod? existing;

  const _PaymentMethodDialog({this.existing});

  @override
  State<_PaymentMethodDialog> createState() => _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends State<_PaymentMethodDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _tax;
  late bool _active;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    _name = TextEditingController(text: m?.name ?? '');
    _tax = TextEditingController(
        text: m == null ? '' : m.taxPercent.toString().replaceAll(RegExp(r'\.0$'), ''));
    _active = m?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _tax.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<PosRepository>().savePaymentMethod(PaymentMethod(
            id: widget.existing?.id ?? 0,
            name: _name.text,
            taxPercent: double.parse(_tax.text.trim()),
            isActive: _active,
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
    return AlertDialog(
      title: Text(widget.existing == null
          ? 'New Payment Method'
          : 'Edit Payment Method'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Naam',
                    hintText: 'e.g. Cash, Card, JazzCash',
                  ),
                  validator: V.req,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tax,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Tax rate',
                    suffixText: '%',
                  ),
                  validator: V.percent,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  subtitle: const Text('Off = bill pe option nahi aayega'),
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                ),
                FormError(_error),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        SaveButton(saving: _saving, onPressed: _save),
      ],
    );
  }
}

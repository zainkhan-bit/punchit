import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/pos_repository.dart';
import '../../models/models.dart';
import '../../providers/order_provider.dart';
import '../../widgets/admin_widgets.dart';

/// Staff add / edit, role, PIN reset, active/inactive.
/// Staff delete nahi hota (purane orders mein naam chahiye), sirf inactive.
class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  List<Staff> _staff = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await context.read<PosRepository>().getAllStaff();
    if (!mounted) return;
    // Active pehle, phir role, phir naam
    list.sort((a, b) {
      if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
      final r = StaffRoles.all
          .indexOf(a.role)
          .compareTo(StaffRoles.all.indexOf(b.role));
      return r != 0 ? r : a.name.compareTo(b.name);
    });
    setState(() {
      _staff = list;
      _loading = false;
    });
  }

  Future<void> _openForm([Staff? existing]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _StaffDialog(existing: existing),
    );
    if (saved == true) _load();
  }

  IconData _roleIcon(String role) => switch (role) {
        StaffRoles.kitchen => Icons.soup_kitchen,
        StaffRoles.manager => Icons.manage_accounts,
        StaffRoles.owner => Icons.workspace_premium,
        _ => Icons.room_service,
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Staff')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add),
        label: const Text('Staff'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: _staff.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final s = _staff[i];
                return ListTile(
                  onTap: () => _openForm(s),
                  leading: CircleAvatar(
                    backgroundColor:
                        s.isActive ? cs.primaryContainer : cs.surfaceContainerHighest,
                    child: Icon(_roleIcon(s.role),
                        color: s.isActive ? cs.onPrimaryContainer : cs.outline),
                  ),
                  title: Text(
                    s.name,
                    style: TextStyle(color: s.isActive ? null : cs.outline),
                  ),
                  subtitle: Text(
                      '${s.employeeCode}  ·  ${StaffRoles.label(s.role)}'
                      '${s.isActive ? '' : '  ·  Inactive'}'),
                  trailing: const Icon(Icons.edit),
                );
              },
            ),
    );
  }
}

class _StaffDialog extends StatefulWidget {
  final Staff? existing;

  const _StaffDialog({this.existing});

  @override
  State<_StaffDialog> createState() => _StaffDialogState();
}

class _StaffDialogState extends State<_StaffDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _code;
  final _pin = TextEditingController();
  late String _role;
  late bool _active;
  bool _saving = false;
  String? _error;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _name = TextEditingController(text: s?.name ?? '');
    _code = TextEditingController(text: s?.employeeCode ?? '');
    _role = s?.role ?? StaffRoles.server;
    _active = s?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final pin = _pin.text.trim();
    try {
      final saved = await context.read<PosRepository>().saveStaff(
            Staff(
              id: widget.existing?.id ?? 0,
              employeeCode: _code.text,
              name: _name.text,
              role: _role,
              isActive: _active,
            ),
            newPin: pin.isEmpty ? null : pin,
          );
      if (!mounted) return;
      // Apni hi profile edit ki ho to logged-in info update karo
      final order = context.read<OrderProvider>();
      if (order.loggedInStaff?.id == saved.id) order.login(saved);
      Navigator.pop(context, true);
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
    final me = context.read<OrderProvider>().loggedInStaff;
    final isMe = me != null && me.id == widget.existing?.id;

    return AlertDialog(
      title: Text(_isNew ? 'New Staff' : 'Edit Staff'),
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
                  decoration: const InputDecoration(labelText: 'Naam'),
                  validator: V.req,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Employee code (Server ID)',
                    hintText: 'e.g. S104',
                  ),
                  validator: V.req,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: StaffRoles.all
                      .map((r) => DropdownMenuItem(
                          value: r, child: Text(StaffRoles.label(r))))
                      .toList(),
                  // Apna role khud nahi badal sakte (lock-out se bachne ke liye)
                  onChanged:
                      isMe ? null : (v) => setState(() => _role = v ?? _role),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pin,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: InputDecoration(
                    labelText: _isNew ? 'PIN (4 digits)' : 'Naya PIN',
                    helperText:
                        _isNew ? null : 'Khali chhoro to purana PIN rahega',
                  ),
                  validator: (v) =>
                      (!_isNew && (v ?? '').trim().isEmpty) ? null : V.pin(v),
                ),
                if (!isMe)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active'),
                    subtitle: const Text('Off = login nahi kar sakega'),
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

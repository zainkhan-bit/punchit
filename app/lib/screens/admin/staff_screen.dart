import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/pos_repository.dart';
import '../../models/models.dart';
import '../../providers/order_provider.dart';
import '../../widgets/admin_widgets.dart';
import '../../widgets/ui_kit.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  List<Staff> _staff = [];
  int _tab = 0;
  String? _banner;
  bool _loading = true;

  static const _permissions = {
    StaffRoles.server: 'Orders, tables aur payment lena',
    StaffRoles.kitchen: 'Kitchen queue aur ready status',
    StaffRoles.manager: 'Menu, staff, settings aur reports',
    StaffRoles.owner: 'Manager wale sab kaam',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await context.read<PosRepository>().getAllStaff();
    if (!mounted) return;
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
    if (saved == true) {
      setState(() => _banner = existing == null
          ? 'Naya staff account ready hai.'
          : '${existing.name} ka record update ho gaya.');
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _staff.where((s) => s.isActive).length;
    final roles = _staff.map((s) => s.role).toSet().length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Staff & access',
              subtitle: '$active team members · $roles roles',
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
                    options: const ['Team members', 'Permissions'],
                    selectedIndex: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: _tab == 0 ? _membersList() : _permissionsList(),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: PrimaryButton(label: 'Add staff member', onPressed: () => _openForm()),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _membersList() => [
        for (final s in _staff)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ListRowCard(
              title: s.name,
              subtitle: 'ID ${s.employeeCode} · ${StaffRoles.label(s.role)} · '
                  '${s.isActive ? 'Active' : 'Inactive'}',
              onTap: () => _openForm(s),
            ),
          ),
      ];

  List<Widget> _permissionsList() => [
        for (final role in StaffRoles.all)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ListRowCard(
              title: '${StaffRoles.label(role)} · '
                  '${_staff.where((s) => s.role == role && s.isActive).length} active',
              subtitle: _permissions[role],
              trailing: const SizedBox.shrink(),
            ),
          ),
        const NoteBanner(
          text: 'Sirf Manager ya Owner staff bana ya badal sakta hai.',
          type: NoteType.warning,
        ),
      ];
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

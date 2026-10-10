import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/pos_repository.dart';
import '../providers/order_provider.dart';
import 'admin/admin_home_screen.dart';
import 'order_type_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _codeCtrl = TextEditingController();
  String _pin = '';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _tapDigit(String d) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length == 4) _login();
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _login() async {
    if (_codeCtrl.text.trim().isEmpty) {
      setState(() {
        _error = 'Server ID enter karo';
        _pin = '';
      });
      return;
    }
    setState(() => _loading = true);
    final repo = context.read<PosRepository>();
    final staff = await repo.login(_codeCtrl.text, _pin);
    if (!mounted) return;

    if (staff == null) {
      setState(() {
        _loading = false;
        _error = 'Galat Server ID ya PIN';
        _pin = '';
      });
      return;
    }
    context.read<OrderProvider>().login(staff);
    // Manager / Owner -> Admin panel, baqi sab -> order screen
    Navigator.of(context).pushReplacement(
      staff.isAdmin
          ? MaterialPageRoute<void>(builder: (_) => const AdminHomeScreen())
          : OrderTypeScreen.route(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                children: [
                  Icon(Icons.restaurant_menu, size: 64, color: cs.primary),
                  const SizedBox(height: 8),
                  Text('PunchIt',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  const Text('Demo: Server S101, Manager M201, Owner O301\nPIN 1234',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Server ID',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // PIN dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      final filled = i < _pin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled ? cs.primary : Colors.transparent,
                          border: Border.all(color: cs.primary, width: 2),
                        ),
                      );
                    }),
                  ),
                  SizedBox(
                    height: 32,
                    child: Center(
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_error ?? '',
                              style: TextStyle(color: cs.error)),
                    ),
                  ),
                  _PinPad(onDigit: _tapDigit, onBackspace: _backspace),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PinPad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onBackspace;

  const _PinPad({required this.onDigit, required this.onBackspace});

  @override
  Widget build(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '<'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: keys.map((k) {
        if (k.isEmpty) return const SizedBox();
        return OutlinedButton(
          onPressed: () => k == '<' ? onBackspace() : onDigit(k),
          child: k == '<'
              ? const Icon(Icons.backspace_outlined)
              : Text(k, style: const TextStyle(fontSize: 22)),
        );
      }).toList(),
    );
  }
}

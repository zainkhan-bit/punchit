import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../data/pos_repository.dart';
import '../models/models.dart';
import '../providers/order_provider.dart';
import '../widgets/ui_kit.dart';
import 'admin/admin_home_screen.dart';
import 'kitchen/kitchen_queue_screen.dart';
import 'order_type_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _codeCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _loading = false;
  bool _showPin = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final code = _codeCtrl.text.trim();
    final pin = _pinCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Employee ID enter karo');
      return;
    }
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      setState(() => _error = 'PIN 4 digits ka hai');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    final staff = await context.read<PosRepository>().login(code, pin);
    if (!mounted) return;

    if (staff == null) {
      setState(() {
        _loading = false;
        _error = 'Galat Employee ID ya PIN';
        _pinCtrl.clear();
      });
      return;
    }

    context.read<OrderProvider>().login(staff);
    final Route<void> next = staff.isAdmin
        ? MaterialPageRoute(builder: (_) => const AdminHomeScreen())
        : staff.role == StaffRoles.kitchen
        ? MaterialPageRoute(builder: (_) => const KitchenQueueScreen())
        : OrderTypeScreen.route();
    Navigator.of(context).pushReplacement(next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'PunchIt',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'RESTAURANT WORKSPACE',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const HeroCard(
                    icon: Icons.room_service_outlined,
                    title: 'Good food.\nGreat service.',
                    subtitle: 'Your shift, your tables, your orders.\nEverything in one place.',
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Welcome back',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sign in with your employee ID and PIN',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  LabeledField(
                    label: 'Employee ID',
                    controller: _codeCtrl,
                    hint: 'S101',
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 12),
                  LabeledField(
                    label: '4-digit PIN',
                    controller: _pinCtrl,
                    hint: '••••',
                    keyboardType: TextInputType.number,
                    obscureText: !_showPin,
                    maxLength: 4,
                    suffix: IconButton(
                      tooltip: _showPin ? 'PIN chhupao' : 'PIN dikhao',
                      icon: Icon(
                        _showPin ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(() => _showPin = !_showPin),
                    ),
                    onSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 12),
                  if (_error != null) NoteBanner(text: _error!, type: NoteType.error),
                  const SizedBox(height: 12),
                  const Text(
                    'Demo: S101 Server · K101 Kitchen · M201 Manager · O301 Owner · PIN 1234',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: PrimaryButton(label: 'Sign in', loading: _loading, onPressed: _login),
            ),
          ],
        ),
      ),
    );
  }
}

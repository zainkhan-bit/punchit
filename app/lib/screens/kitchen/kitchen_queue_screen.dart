import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/order_provider.dart';
import '../../widgets/ui_kit.dart';
import '../login_screen.dart';

class KitchenQueueScreen extends StatelessWidget {
  const KitchenQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<OrderProvider>().loggedInStaff;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Kitchen queue',
              subtitle: staff?.name,
              showBack: false,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: NoteBanner(text: 'Kitchen screens abhi baqi hain (Part B).'),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: PrimaryButton(
                label: 'Sign out',
                onPressed: () {
                  context.read<OrderProvider>().logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

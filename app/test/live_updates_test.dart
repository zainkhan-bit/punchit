import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:punchit_app/data/mock_pos_repository.dart';
import 'package:punchit_app/data/pos_repository.dart';
import 'package:punchit_app/main.dart';
import 'package:punchit_app/models/models.dart';
import 'package:punchit_app/providers/order_provider.dart';

void main() {
  testWidgets('Repository change hote hi Home khud update hota hai', (t) async {
    t.view.physicalSize = const Size(412 * 3, 892 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);

    final repo = MockPosRepository();
    await t.pumpWidget(MultiProvider(
      providers: [
        Provider<PosRepository>.value(value: repo),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: const PunchItApp(),
    ));

    await t.enterText(find.byType(TextFormField).at(0), 'S101');
    await t.enterText(find.byType(TextFormField).at(1), '1234');
    await t.tap(find.text('Sign in'));
    await t.pumpAndSettle();
    expect(find.text('Ready to serve'), findsOneWidget);

    final update = repo.updateKitchenStatus(998, KitchenStatus.served);
    await t.pump(const Duration(seconds: 1));
    await update;
    await t.pumpAndSettle();

    expect(find.text('Ready to serve'), findsNothing);
    expect(find.text('Served · Payment baqi'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:punchit_app/data/mock_pos_repository.dart';
import 'package:punchit_app/data/pos_repository.dart';
import 'package:punchit_app/main.dart';
import 'package:punchit_app/providers/order_provider.dart';

Widget buildApp() => MultiProvider(
  providers: [
    Provider<PosRepository>(create: (_) => MockPosRepository()),
    ChangeNotifierProvider(create: (_) => OrderProvider()),
  ],
  child: const PunchItApp(),
);

void main() {
  testWidgets('App login screen pe khulti hai', (tester) async {
    await tester.pumpWidget(buildApp());
    expect(find.text('PunchIt'), findsOneWidget);
    expect(find.text('EMPLOYEE ID'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('Server login karke Home pe jata hai', (tester) async {
    tester.view.physicalSize = const Size(412 * 3, 892 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildApp());
    await tester.enterText(find.byType(TextFormField).at(0), 'S101');
    await tester.enterText(find.byType(TextFormField).at(1), '1234');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Hello, Ali'), findsOneWidget);
    expect(find.text('Ready for the rush?'), findsOneWidget);
  });
}

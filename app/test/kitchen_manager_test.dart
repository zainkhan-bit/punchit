import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test.dart' show buildApp;

Future<void> tapText(WidgetTester t, String s, {bool last = false}) async {
  final f = last ? find.text(s).last : find.text(s).first;
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

Future<void> login(WidgetTester t, String id) async {
  await t.enterText(find.byType(TextFormField).at(0), id);
  await t.enterText(find.byType(TextFormField).at(1), '1234');
  await tapText(t, 'Sign in');
}

void phoneSize(WidgetTester t) {
  t.view.physicalSize = const Size(360 * 3, 740 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

void main() {
  testWidgets('Kitchen order ko ready karta hai', (t) async {
    phoneSize(t);
    await t.pumpWidget(buildApp());
    await login(t, 'K101');
    expect(find.text('Kitchen queue'), findsOneWidget);
    expect(find.text('#999 / Takeaway · Usman'), findsOneWidget);
    await tapText(t, 'Mark ready');
    expect(find.textContaining('Order #999 ready hai'), findsOneWidget);
    await tapText(t, 'Ready', last: true);
    expect(find.text('Ready for pickup'), findsOneWidget);
    expect(find.text('#999 / Takeaway · Usman'), findsOneWidget);
    expect(find.text('#998 / Main Hall · T2'), findsOneWidget);
    await tapText(t, 'Handed over');
    expect(find.text('#999 / Takeaway · Usman'), findsNothing);
    await tapText(t, 'Sign out');
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('Manager panel ki screens khulti hain', (t) async {
    phoneSize(t);
    await t.pumpWidget(buildApp());
    await login(t, 'M201');
    expect(find.text('Restaurant overview'), findsOneWidget);
    expect(find.text('Rs 1,450'), findsOneWidget);

    await tapText(t, 'Menu');
    expect(find.text('Manage menu'), findsOneWidget);
    await tapText(t, 'Unavailable · 1');
    expect(find.text('Mint Margarita'), findsOneWidget);
    await tapText(t, 'All products');
    await t.tap(find.byType(Switch).first);
    await t.pump(const Duration(seconds: 1));
    await t.pumpAndSettle();
    expect(find.textContaining('ab unavailable hai'), findsOneWidget);

    await tapText(t, 'Reports');
    expect(find.text('Daily report'), findsOneWidget);
    expect(find.text('Cash · 1 orders'), findsOneWidget);
    await tapText(t, 'Order history');
    expect(find.text('#996 · Main Hall · T1'), findsOneWidget);
    await tapText(t, 'Back to daily report');

    await tapText(t, 'Settings');
    expect(find.text('Restaurant settings'), findsOneWidget);
    await tapText(t, 'Halls & tables');
    expect(find.text('Halls & Tables'), findsOneWidget);
    await t.pageBack();
    await t.pumpAndSettle();

    await tapText(t, 'Home');
    await tapText(t, 'Staff & access');
    expect(find.text('Staff & access'), findsWidgets);
    await tapText(t, 'Permissions');
    expect(find.textContaining('Kitchen · 1 active'), findsOneWidget);
    await t.tap(find.byIcon(Icons.chevron_left).first);
    await t.pumpAndSettle();

    await tapText(t, 'Take order');
    expect(find.text('Hello, Zain'), findsOneWidget);
  });
}

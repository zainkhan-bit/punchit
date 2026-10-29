import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test.dart' show buildApp;

Future<void> tapText(WidgetTester t, String s) async {
  final f = find.text(s).first;
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
  testWidgets('PIN dikhao / chhupao', (t) async {
    phoneSize(t);
    await t.pumpWidget(buildApp());
    await t.enterText(find.byType(TextFormField).at(1), '1234');
    await t.pump();
    expect(find.byTooltip('PIN dikhao'), findsOneWidget);
    await t.tap(find.byTooltip('PIN dikhao'));
    await t.pump();
    expect(find.byTooltip('PIN chhupao'), findsOneWidget);
  });

  testWidgets('Search clear, clear cart, discount aur sign out confirm', (t) async {
    phoneSize(t);
    await t.pumpWidget(buildApp());
    await login(t, 'S101');

    await tapText(t, 'Takeaway');
    await t.enterText(find.byType(TextField).first, 'zinger');
    await t.pumpAndSettle();
    expect(find.text('SEARCH RESULTS'), findsOneWidget);
    await t.tap(find.byTooltip('Search clear karo'));
    await t.pumpAndSettle();
    expect(find.text('SEARCH RESULTS'), findsNothing);

    await tapText(t, 'Burgers');
    await t.tap(find.byTooltip('Add').first);
    await t.pumpAndSettle();
    await tapText(t, 'View order · 1 items · Rs 650');
    await tapText(t, 'Clear cart');
    await tapText(t, 'Haan, clear');
    expect(find.text('Cart khali hai. Wapas ja kar items add karo.'), findsOneWidget);

    await t.tap(find.byIcon(Icons.chevron_left).first);
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Add').first);
    await t.pumpAndSettle();
    await tapText(t, 'View order · 1 items · Rs 650');
    await tapText(t, 'Send to kitchen');
    await tapText(t, 'View active orders');
    await tapText(t, '#1001 · Takeaway');
    expect(find.text('Rs 754'), findsWidgets);
    await t.enterText(find.widgetWithText(TextFormField, '0'), '50');
    await t.pumpAndSettle();
    expect(find.text('- Rs 50'), findsOneWidget);
    expect(find.text('Rs 696'), findsWidgets);
    await t.enterText(find.byType(TextFormField).at(0), '5000');
    await t.pumpAndSettle();
    expect(find.text('Discount subtotal se zyada nahi ho sakta'), findsOneWidget);
    await t.enterText(find.byType(TextFormField).at(0), '50');
    await t.pumpAndSettle();
    await tapText(t, 'Confirm cash payment');
    expect(find.text('All settled.'), findsOneWidget);
    expect(find.text('- Rs 50'), findsOneWidget);
    await tapText(t, 'Back to home');

    await tapText(t, 'Sign out');
    await tapText(t, 'Nahi');
    expect(find.textContaining('Hello, Ali'), findsOneWidget);
    await tapText(t, 'Sign out');
    await tapText(t, 'Haan, sign out');
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('Kitchen pe last updated time', (t) async {
    phoneSize(t);
    await t.pumpWidget(buildApp());
    await login(t, 'K101');
    expect(find.textContaining('Updated '), findsOneWidget);
    await t.pump(const Duration(seconds: 16));
    await t.pumpAndSettle();
    expect(find.textContaining('Updated '), findsOneWidget);
    await tapText(t, 'Sign out');
    await tapText(t, 'Haan, sign out');
  });
}

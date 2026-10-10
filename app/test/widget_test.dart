import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:punchit_app/data/mock_pos_repository.dart';
import 'package:punchit_app/data/pos_repository.dart';
import 'package:punchit_app/main.dart';
import 'package:punchit_app/providers/order_provider.dart';

void main() {
  testWidgets('App login screen pe khulti hai', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<PosRepository>(create: (_) => MockPosRepository()),
          ChangeNotifierProvider(create: (_) => OrderProvider()),
        ],
        child: const PunchItApp(),
      ),
    );
    expect(find.text('PunchIt'), findsOneWidget);
    expect(find.text('Server ID'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:punchit_app/data/local_store.dart';
import 'package:punchit_app/data/mock_pos_repository.dart';
import 'package:punchit_app/models/models.dart';

void main() {
  test('Order, payment aur naya staff app restart ke baad bhi rehte hain', () async {
    final store = MemoryStore();
    final repo = MockPosRepository(store: store);

    final items = await repo.getMenuItems();
    final fries = items.firstWhere((i) => i.name == 'Fries');
    final orderId = await repo.placeOrder(
      type: OrderType.takeaway,
      serverId: 1,
      customerName: 'Usman',
      items: [CartItem(item: fries, modifiers: [], quantity: 2, note: 'Extra salt')],
    );
    final cash = (await repo.getPaymentMethods()).first;
    await repo.payOrder(orderId: orderId, method: cash, discount: 50, amountReceived: 1000);
    await repo.saveStaff(
      const Staff(id: 0, employeeCode: 'S104', name: 'Bilal', role: 'server'),
      newPin: '4321',
    );

    final reopened = MockPosRepository(store: store);
    final order = (await reopened.getOrders()).firstWhere((o) => o.id == orderId);
    expect(order.isPaid, isTrue);
    expect(order.customerName, 'Usman');
    expect(order.items.single.note, 'Extra salt');
    expect(order.discount, 50);
    expect(order.total, 754);
    expect(await reopened.login('S104', '4321'), isNotNull);

    final nextId = await reopened.placeOrder(
      type: OrderType.takeaway,
      serverId: 1,
      items: [CartItem(item: fries, modifiers: [])],
    );
    expect(nextId, orderId + 1);
  });

  test('Reset demo data se shuru wala data wapas aata hai', () async {
    final store = MemoryStore();
    final repo = MockPosRepository(store: store);
    final fries = (await repo.getMenuItems()).firstWhere((i) => i.name == 'Fries');
    await repo.placeOrder(
      type: OrderType.takeaway,
      serverId: 1,
      items: [CartItem(item: fries, modifiers: [])],
    );
    expect((await repo.getOrders()).length, 5);

    await repo.resetDemoData();
    expect((await repo.getOrders()).length, 4);
    expect(store.read(), isNull);
    expect((await MockPosRepository(store: store).getOrders()).length, 4);
  });

  test('Kharab saved data se app crash nahi hoti', () async {
    final store = MemoryStore();
    await store.write('{not json');
    final repo = MockPosRepository(store: store);
    expect((await repo.getOrders()).length, 4);
    expect(store.read(), isNull);
  });
}

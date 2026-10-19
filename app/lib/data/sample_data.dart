import 'models.dart';
class AppData {
  AppData._();

  static StaffMember? currentStaff;

  static final List<StaffMember> staff = [
    StaffMember(id: '1024', name: 'Sameer Abdullah', role: StaffRole.server, pin: '1234'),
    StaffMember(id: '1025', name: 'Zain Khan', role: StaffRole.kitchen, pin: '1234'),
    StaffMember(id: '1002', name: 'Ayesha Ali', role: StaffRole.manager, pin: '1234'),
  ];

  static StaffMember? findStaff(String id) {
    for (final member in staff) {
      if (member.id == id.trim()) return member;
    }
    return null;
  }

  static const categories = ['Popular', 'Burgers', 'Sides', 'Drinks'];

  static final List<MenuItem> menu = [
    MenuItem(
      id: 'signature_burger',
      name: 'Signature burger',
      category: 'Burgers',
      description: 'Beef patty · House sauce',
      price: 700,
      station: 'Grill',
      extras: ['Cheese', 'Jalapeños'],
    ),
    MenuItem(
      id: 'crispy_chicken',
      name: 'Crispy chicken',
      category: 'Burgers',
      description: 'Crunchy fillet · Slaw',
      price: 650,
      station: 'Grill',
      extras: ['Cheese'],
    ),
    MenuItem(
      id: 'classic_fries',
      name: 'Classic fries',
      category: 'Sides',
      description: 'Golden & lightly salted',
      price: 320,
      station: 'Grill',
    ),
    MenuItem(
      id: 'mint_lemonade',
      name: 'Mint lemonade',
      category: 'Drinks',
      description: 'Fresh mint · Lemon',
      price: 220,
      station: 'Drinks',
    ),
  ];

  static final List<DiningTable> tables = [
    for (var n = 1; n <= 12; n++)
      DiningTable(
        number: n,
        hall: 'Main hall',
        seats: n.isEven ? 4 : 2,
        status: switch (n) {
          2 || 6 || 9 => TableStatus.occupied,
          11 => TableStatus.reserved,
          _ => TableStatus.available,
        },
      ),
    for (var n = 13; n <= 16; n++)
      DiningTable(
        number: n,
        hall: 'Terrace',
        seats: 4,
        status: n == 14 ? TableStatus.occupied : TableStatus.available,
      ),
  ];

  static MenuItem _item(String id) => menu.firstWhere((m) => m.id == id);
  static DiningTable _table(int number) =>
      tables.firstWhere((t) => t.number == number);

  static final List<Order> activeOrders = [
    Order(
      number: 1040,
      serverName: 'Sameer Abdullah',
      createdAt: DateTime.now().subtract(const Duration(minutes: 6)),
      lines: [
        CartLine(item: _item('crispy_chicken')),
        CartLine(item: _item('mint_lemonade')),
      ],
    ),
    Order(
      number: 1038,
      table: _table(2),
      status: OrderStatus.ready,
      serverName: 'Sameer Abdullah',
      createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
      lines: [
        CartLine(item: _item('signature_burger')),
        CartLine(item: _item('classic_fries')),
        CartLine(item: _item('mint_lemonade')),
      ],
    ),
  ];

  static final List<Order> completedOrders = [
    _paid(1036, _table(5), PaymentMethod.cash, 'Sameer Abdullah', 95, [
      CartLine(item: _item('signature_burger'), quantity: 2),
      CartLine(item: _item('mint_lemonade'), quantity: 2),
    ]),
    _paid(1035, null, PaymentMethod.card, 'Hamza Ahmed', 120, [
      CartLine(item: _item('crispy_chicken')),
      CartLine(item: _item('classic_fries')),
    ]),
    _paid(1034, _table(1), PaymentMethod.wallet, 'Sameer Abdullah', 150, [
      CartLine(item: _item('signature_burger')),
    ]),
  ];

  static Order _paid(int number, DiningTable? table, PaymentMethod method,
      String server, int minutesAgo, List<CartLine> lines) {
    final order = Order(
      number: number,
      table: table,
      lines: lines,
      status: OrderStatus.paid,
      serverName: server,
      createdAt: DateTime.now().subtract(Duration(minutes: minutesAgo)),
    );
    order.paymentMethod = method;
    order.cashReceived = order.total;
    order.paidAt = order.createdAt.add(const Duration(minutes: 30));
    return order;
  }

  static int _nextOrderNumber = 1042;

  /// Starts a new empty order. Pass a [table] for dine-in, leave it null for takeaway.
  static Order newOrder({DiningTable? table}) => Order(
    number: _nextOrderNumber++,
    table: table,
    lines: [],
    serverName: currentStaff?.name ?? 'Server',
  );

  static void sendToKitchen(Order order) {
    order.createdAt = DateTime.now();
    order.status = OrderStatus.preparing;
    activeOrders.insert(0, order);
    order.table?.status = TableStatus.occupied;
  }

  static void completePayment(
      Order order, {
        required PaymentMethod method,
        String reference = '',
        required int cashReceived,
      }) {
    order
      ..paymentMethod = method
      ..paymentReference = reference
      ..cashReceived = cashReceived
      ..paidAt = DateTime.now()
      ..status = OrderStatus.paid;
    activeOrders.remove(order);
    completedOrders.insert(0, order);
    order.table?.status = TableStatus.available;
  }
}
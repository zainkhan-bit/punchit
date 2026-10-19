enum StaffRole { server, kitchen, manager }

class StaffMember {
  StaffMember({
    required this.id,
    required this.name,
    required this.role,
    required this.pin,
    this.onShift = true,
  });

  final String id;
  String name;
  StaffRole role;
  String pin;
  bool onShift;

  String get firstName => name.split(' ').first;

  String get roleLabel => switch (role) {
    StaffRole.server => 'Server',
    StaffRole.kitchen => 'Kitchen',
    StaffRole.manager => 'Manager',
  };
}

class MenuItem {
  MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.station,
    this.extras = const [],
    this.available = true,
  });

  final String id;
  String name;
  String category;
  String description;
  int price;
  String station;
  List<String> extras;
  bool available;
}

class CartLine {
  CartLine({
    required this.item,
    this.quantity = 1,
    List<String>? extras,
    this.note = '',
  }) : extras = extras ?? [];

  static const extraPrice = 50;

  final MenuItem item;
  int quantity;
  final List<String> extras;
  String note;

  int get unitPrice => item.price + extras.length * extraPrice;
  int get total => unitPrice * quantity;
  String get details {
    final parts = [...extras.map((e) => 'Extra ${e.toLowerCase()}'), if (note.isNotEmpty) note];
    return parts.isEmpty ? 'Regular' : parts.join(' · ');
  }
}

enum TableStatus { available, occupied, reserved }

class DiningTable {
  DiningTable({
    required this.number,
    required this.hall,
    required this.seats,
    this.status = TableStatus.available,
  });

  final int number;
  final String hall;
  int seats;
  TableStatus status;

  String get code => 'T${number.toString().padLeft(2, '0')}';
  String get name => 'Table ${number.toString().padLeft(2, '0')}';
}

/// Tax and service charge, editable later from Restaurant settings.
class RestaurantSettings {
  RestaurantSettings._();

  static int taxPercent = 10;
  static int serviceChargePercent = 5;
}

enum OrderStatus { preparing, ready, paid }

enum PaymentMethod { cash, card, wallet }

class Order {
  Order({
    required this.number,
    required this.lines,
    this.table,
    this.status = OrderStatus.preparing,
    this.serverName = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final int number;
  final List<CartLine> lines;
  final DiningTable? table;
  OrderStatus status;
  final String serverName;
  DateTime createdAt;

  PaymentMethod? paymentMethod;
  String paymentReference = '';
  int cashReceived = 0;
  DateTime? paidAt;

  bool get isTakeaway => table == null;
  String get label => isTakeaway ? 'Takeaway' : table!.name;
  String get title => '#$number · $label';

  int get itemCount => lines.fold(0, (sum, line) => sum + line.quantity);
  int get subtotal => lines.fold(0, (sum, line) => sum + line.total);
  int get serviceCharge => isTakeaway
      ? 0
      : (subtotal * RestaurantSettings.serviceChargePercent / 100).round();
  int get tax => (subtotal * RestaurantSettings.taxPercent / 100).round();
  int get total => subtotal + serviceCharge + tax;
  int get change => cashReceived - total;

  String get stations => lines.map((l) => l.item.station).toSet().join(' & ');

  String get paymentLabel => switch (paymentMethod) {
    PaymentMethod.cash => 'Cash',
    PaymentMethod.card => 'Card',
    PaymentMethod.wallet => 'Wallet',
    null => '',
  };

  String get statusText => switch (status) {
    OrderStatus.preparing => 'Preparing · $stations',
    OrderStatus.ready =>
    isTakeaway ? 'Ready · Waiting for pickup' : 'Ready to serve',
    OrderStatus.paid => 'Paid · $paymentLabel',
  };
}
String formatRs(int amount) {
  final negative = amount < 0;
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return '${negative ? '-' : ''}Rs $buffer';
}

const _weekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];
const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July',
  'August', 'September', 'October', 'November', 'December',
];

String formatTime(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${time.hour < 12 ? 'AM' : 'PM'}';
}

String formatLongDate(DateTime date) =>
    '${_weekdays[date.weekday - 1]}, ${date.day} ${_months[date.month - 1]}';

String formatShortDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1].substring(0, 3)} ${date.year}';
enum OrderType { dineIn, takeaway }

enum TableStatus { free, occupied, billed }

enum StationType { item, expo }

double _toDouble(dynamic v) => v == null ? 0 : double.parse(v.toString());
bool _toBool(dynamic v) => v == true || v == 1 || v == '1';

class StaffRoles {
  static const server = 'server';
  static const kitchen = 'kitchen';
  static const manager = 'manager';
  static const owner = 'owner';

  static const all = [server, kitchen, manager, owner];

  static String label(String role) => switch (role) {
    server => 'Server',
    kitchen => 'Kitchen',
    manager => 'Manager',
    owner => 'Owner',
    _ => role,
  };
}

class Staff {
  final int id;
  final String employeeCode;
  final String name;
  final String role;
  final bool isActive;

  const Staff({
    required this.id,
    required this.employeeCode,
    required this.name,
    required this.role,
    this.isActive = true,
  });

  bool get isAdmin => role == StaffRoles.manager || role == StaffRoles.owner;

  factory Staff.fromJson(Map<String, dynamic> j) => Staff(
    id: j['id'],
    employeeCode: j['employee_code'],
    name: j['name'],
    role: j['role'],
    isActive: j['is_active'] == null ? true : _toBool(j['is_active']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'employee_code': employeeCode,
    'name': name,
    'role': role,
    'is_active': isActive,
  };
}

class Station {
  final int id;
  final String name;
  final StationType type;
  final String? printerIp;
  final int printerPort;
  final bool isActive;

  const Station({
    required this.id,
    required this.name,
    this.type = StationType.item,
    this.printerIp,
    this.printerPort = 9100,
    this.isActive = true,
  });

  factory Station.fromJson(Map<String, dynamic> j) => Station(
    id: j['id'],
    name: j['name'],
    type: j['station_type'] == 'expo' ? StationType.expo : StationType.item,
    printerIp: j['printer_ip'],
    printerPort: j['printer_port'] ?? 9100,
    isActive: _toBool(j['is_active']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'station_type': type.name,
    'printer_ip': printerIp,
    'printer_port': printerPort,
    'is_active': isActive,
  };
}

class MenuCategory {
  final int id;
  final String name;
  final int? stationId;
  final int sortOrder;

  const MenuCategory({
    required this.id,
    required this.name,
    this.stationId,
    this.sortOrder = 0,
  });

  factory MenuCategory.fromJson(Map<String, dynamic> j) => MenuCategory(
    id: j['id'],
    name: j['name'],
    stationId: j['station_id'],
    sortOrder: j['sort_order'] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'station_id': stationId,
    'sort_order': sortOrder,
  };
}

class ModifierOption {
  final int id;
  final String name;
  final double price;
  final bool isAvailable;

  const ModifierOption({
    required this.id,
    required this.name,
    this.price = 0,
    this.isAvailable = true,
  });

  factory ModifierOption.fromJson(Map<String, dynamic> j) => ModifierOption(
    id: j['id'],
    name: j['name'],
    price: _toDouble(j['price']),
    isAvailable:
    j['is_available'] == null ? true : _toBool(j['is_available']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'is_available': isAvailable,
  };
}

class ModifierGroup {
  final int id;
  final String name;
  final int minSelect;
  final int maxSelect;
  final List<ModifierOption> options;

  const ModifierGroup({
    required this.id,
    required this.name,
    required this.minSelect,
    required this.maxSelect,
    required this.options,
  });

  bool get isSingle => maxSelect == 1;

  List<ModifierOption> get availableOptions =>
      options.where((o) => o.isAvailable).toList();

  factory ModifierGroup.fromJson(Map<String, dynamic> j) => ModifierGroup(
    id: j['id'],
    name: j['name'],
    minSelect: j['min_select'],
    maxSelect: j['max_select'],
    options: ((j['options'] ?? []) as List)
        .map((o) => ModifierOption.fromJson(o))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'min_select': minSelect,
    'max_select': maxSelect,
    'options': options.map((o) => o.toJson()).toList(),
  };
}

class MenuItem {
  final int id;
  final int categoryId;
  final String name;
  final double price;
  final int? stationId;
  final bool isAvailable;
  final List<ModifierGroup> modifierGroups;

  const MenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.price,
    this.stationId,
    this.isAvailable = true,
    this.modifierGroups = const [],
  });

  bool get hasOptions => modifierGroups.isNotEmpty;

  MenuItem withGroups(List<ModifierGroup> groups) => MenuItem(
    id: id,
    categoryId: categoryId,
    name: name,
    price: price,
    stationId: stationId,
    isAvailable: isAvailable,
    modifierGroups: groups,
  );

  factory MenuItem.fromJson(Map<String, dynamic> j) => MenuItem(
    id: j['id'],
    categoryId: j['category_id'],
    name: j['name'],
    price: _toDouble(j['price']),
    stationId: j['station_id'],
    isAvailable: _toBool(j['is_available']),
    modifierGroups: ((j['modifier_groups'] ?? []) as List)
        .map((g) => ModifierGroup.fromJson(g))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'category_id': categoryId,
    'name': name,
    'price': price,
    'station_id': stationId,
    'is_available': isAvailable,
    'modifier_group_ids': modifierGroups.map((g) => g.id).toList(),
  };
}

class Hall {
  final int id;
  final String name;

  const Hall({required this.id, required this.name});

  factory Hall.fromJson(Map<String, dynamic> j) =>
      Hall(id: j['id'], name: j['name']);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class DiningTable {
  final int id;
  final int hallId;
  final int tableNumber;
  final int capacity;
  final TableStatus status;

  const DiningTable({
    required this.id,
    required this.hallId,
    required this.tableNumber,
    required this.capacity,
    this.status = TableStatus.free,
  });

  DiningTable withStatus(TableStatus s) => DiningTable(
    id: id,
    hallId: hallId,
    tableNumber: tableNumber,
    capacity: capacity,
    status: s,
  );

  factory DiningTable.fromJson(Map<String, dynamic> j) => DiningTable(
    id: j['id'],
    hallId: j['hall_id'],
    tableNumber: j['table_number'],
    capacity: j['capacity'],
    status: switch (j['order_status']) {
      'open' => TableStatus.occupied,
      'billed' => TableStatus.billed,
      _ => TableStatus.free,
    },
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'hall_id': hallId,
    'table_number': tableNumber,
    'capacity': capacity,
  };
}

class PaymentMethod {
  final int id;
  final String name;
  final double taxPercent;
  final bool isActive;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.taxPercent,
    this.isActive = true,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> j) => PaymentMethod(
    id: j['id'],
    name: j['name'],
    taxPercent: _toDouble(j['tax_percent']),
    isActive: _toBool(j['is_active']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'tax_percent': taxPercent,
    'is_active': isActive,
  };
}

class AppSettings {
  final String restaurantName;
  final double serviceChargePercent;
  final bool serviceChargeDineInOnly;
  final String receiptFooter;

  const AppSettings({
    required this.restaurantName,
    this.serviceChargePercent = 0,
    this.serviceChargeDineInOnly = true,
    this.receiptFooter = '',
  });

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
    restaurantName: j['restaurant_name'],
    serviceChargePercent: _toDouble(j['service_charge_percent']),
    serviceChargeDineInOnly: _toBool(j['service_charge_dine_in_only']),
    receiptFooter: j['receipt_footer'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'restaurant_name': restaurantName,
    'service_charge_percent': serviceChargePercent,
    'service_charge_dine_in_only': serviceChargeDineInOnly,
    'receipt_footer': receiptFooter,
  };
}

class CartItem {
  final MenuItem item;
  final List<ModifierOption> modifiers;
  int quantity;
  String note;

  CartItem({
    required this.item,
    required this.modifiers,
    this.quantity = 1,
    this.note = '',
  });

  double get unitTotal =>
      item.price + modifiers.fold(0.0, (sum, m) => sum + m.price);

  double get lineTotal => unitTotal * quantity;

  Map<String, dynamic> toJson() => {
    'menu_item_id': item.id,
    'quantity': quantity,
    'note': note.isEmpty ? null : note,
    'modifier_option_ids': modifiers.map((m) => m.id).toList(),
  };
}

enum OrderStatus { open, billed, paid, cancelled }

enum KitchenStatus { pending, preparing, ready, served }

class PlacedOrder {
  final int id;
  final OrderType type;
  final Hall? hall;
  final DiningTable? table;
  final Staff server;
  final String customerName;
  final String customerPhone;
  final List<CartItem> items;
  final DateTime createdAt;

  OrderStatus status;
  KitchenStatus kitchenStatus;

  PaymentMethod? paymentMethod;
  double discount = 0;
  double serviceCharge = 0;
  double taxPercent = 0;
  double tax = 0;
  double total = 0;
  double amountReceived = 0;
  String paymentReference = '';
  DateTime? closedAt;

  PlacedOrder({
    required this.id,
    required this.type,
    this.hall,
    this.table,
    required this.server,
    this.customerName = '',
    this.customerPhone = '',
    required this.items,
    this.status = OrderStatus.open,
    this.kitchenStatus = KitchenStatus.pending,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isDineIn => type == OrderType.dineIn;
  bool get isPaid => status == OrderStatus.paid;

  bool get isActive =>
      status == OrderStatus.open || status == OrderStatus.billed;

  int get itemCount => items.fold(0, (sum, c) => sum + c.quantity);
  double get subtotal => items.fold(0.0, (sum, c) => sum + c.lineTotal);
  double get change => amountReceived - total;

  String get label => isDineIn
      ? '${hall?.name ?? 'Hall'} · T${table?.tableNumber ?? '-'}'
      : (customerName.isEmpty ? 'Takeaway' : 'Takeaway · $customerName');

  String get title => '#$id · $label';

  String get statusLabel => switch (status) {
    OrderStatus.paid => 'Paid · ${paymentMethod?.name ?? ''}',
    OrderStatus.cancelled => 'Cancelled',
    OrderStatus.billed => 'Bill printed · Payment baqi',
    OrderStatus.open => switch (kitchenStatus) {
      KitchenStatus.pending => 'Sent to kitchen',
      KitchenStatus.preparing => 'Preparing',
      KitchenStatus.ready =>
      isDineIn ? 'Ready to serve' : 'Ready · Waiting for pickup',
      KitchenStatus.served => 'Served · Payment baqi',
    },
  };
}

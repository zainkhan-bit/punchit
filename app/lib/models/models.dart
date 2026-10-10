// Saare models ek file mein.
// fromJson / toJson abhi mock mein use nahi ho rahe, lekin backend connect
// karte waqt API ka data yahin se parse aur send hoga.
//
// Rule: id == 0 matlab naya record (abhi save nahi hua).

enum OrderType { dineIn, takeaway }

enum TableStatus { free, occupied, billed }

enum StationType { item, expo }

double _toDouble(dynamic v) => v == null ? 0 : double.parse(v.toString());
bool _toBool(dynamic v) => v == true || v == 1 || v == '1';

// ======================= STAFF =======================

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
  final String role; // server | kitchen | manager | owner
  final bool isActive;

  const Staff({
    required this.id,
    required this.employeeCode,
    required this.name,
    required this.role,
    this.isActive = true,
  });

  /// Manager aur Owner ko admin panel milta hai
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

// ======================= STATIONS =======================

class Station {
  final int id;
  final String name; // Pizza Make Table, Cut Table
  final StationType type; // item = sirf apne items, expo = poora order
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

// ======================= MENU =======================

class MenuCategory {
  final int id;
  final String name;
  final int? stationId; // is category ke items kis station pe print hon
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
  final String name; // Crust, Extra Toppings
  final int minSelect; // 1 = zaroori
  final int maxSelect; // 1 = ek hi (radio), >1 = checkbox
  final List<ModifierOption> options;

  const ModifierGroup({
    required this.id,
    required this.name,
    required this.minSelect,
    required this.maxSelect,
    required this.options,
  });

  bool get isSingle => maxSelect == 1;

  /// Order screen pe sirf available options dikhane hain
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
  final int? stationId; // null = category wala station
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

  /// Save karte waqt sirf group ids jati hain
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

// ======================= FLOOR =======================

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

// ======================= TAX & SETTINGS =======================

/// Har payment method ka apna tax rate (e.g. Cash aur Card ka alag)
class PaymentMethod {
  final int id;
  final String name; // Cash, Card, JazzCash
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

/// Restaurant level settings (DB mein sirf 1 row)
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

// ======================= CART =======================

/// Cart ki ek line: item + selected toppings + qty + comment
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

  /// Backend ko yahi format jayega (POST /api/orders -> items[])
  Map<String, dynamic> toJson() => {
        'menu_item_id': item.id,
        'quantity': quantity,
        'note': note.isEmpty ? null : note,
        'modifier_option_ids': modifiers.map((m) => m.id).toList(),
      };
}

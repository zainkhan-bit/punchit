import '../models/models.dart';
import 'pos_repository.dart';

/// Dummy data, memory mein. Manager panel se jo add/edit karo woh
/// server screens pe foran dikhta hai (app band karne pe reset ho jata hai).
/// Wohi sample data jo database/schema.sql mein hai.
///
/// Jo rules yahan hain (e.g. "category mein products hain to delete nahi"),
/// backend mein bhi wohi lagane hain.
class MockPosRepository implements PosRepository {
  static const _delay = Duration(milliseconds: 250); // fake network

  int _nextId = 1000;
  int _newId() => _nextId++;

  int _nextOrderId = 1001;

  // ---------------- Staff (PIN sab ka 1234) ----------------
  final List<Staff> _staff = [
    const Staff(id: 1, employeeCode: 'S101', name: 'Ali', role: 'server'),
    const Staff(id: 2, employeeCode: 'S102', name: 'Hamza', role: 'server'),
    const Staff(id: 3, employeeCode: 'S103', name: 'Ayesha', role: 'server'),
    const Staff(id: 4, employeeCode: 'K101', name: 'Bilal', role: 'kitchen'),
    const Staff(id: 5, employeeCode: 'M201', name: 'Zain', role: 'manager'),
    const Staff(id: 6, employeeCode: 'O301', name: 'Owner', role: 'owner'),
  ];
  final Map<int, String> _pins = {1: '1234', 2: '1234', 3: '1234', 4: '1234', 5: '1234', 6: '1234'};

  // ---------------- Stations ----------------
  final List<Station> _stations = [
    const Station(id: 1, name: 'Pizza Make Table'),
    const Station(id: 2, name: 'Starter Station'),
    const Station(id: 3, name: 'Grill Station'),
    const Station(id: 4, name: 'Cut Table', type: StationType.expo),
  ];

  // ---------------- Toppings ----------------
  final List<ModifierGroup> _groups = [
    const ModifierGroup(id: 1, name: 'Crust', minSelect: 1, maxSelect: 1, options: [
      ModifierOption(id: 1, name: 'Regular'),
      ModifierOption(id: 2, name: 'Stuffed Crust', price: 300),
      ModifierOption(id: 3, name: 'Thin Crust'),
    ]),
    const ModifierGroup(id: 2, name: 'Extra Toppings', minSelect: 0, maxSelect: 5, options: [
      ModifierOption(id: 4, name: 'Extra Cheese', price: 200),
      ModifierOption(id: 5, name: 'Olives', price: 100),
      ModifierOption(id: 6, name: 'Jalapeno', price: 100),
      ModifierOption(id: 7, name: 'Mushroom', price: 150),
      ModifierOption(id: 8, name: 'Extra Chicken', price: 250),
    ]),
    const ModifierGroup(id: 3, name: 'Add-ons', minSelect: 0, maxSelect: 3, options: [
      ModifierOption(id: 9, name: 'Cheese Slice', price: 100),
      ModifierOption(id: 10, name: 'Extra Patty', price: 300),
      ModifierOption(id: 11, name: 'Make it Spicy'),
    ]),
  ];

  // ---------------- Menu ----------------
  final List<MenuCategory> _categories = [
    const MenuCategory(id: 1, name: 'Pizza', stationId: 1, sortOrder: 1),
    const MenuCategory(id: 2, name: 'Starters', stationId: 2, sortOrder: 2),
    const MenuCategory(id: 3, name: 'Burgers', stationId: 3, sortOrder: 3),
    const MenuCategory(id: 4, name: 'Drinks', sortOrder: 4), // station nahi = sirf Cut Table
  ];

  // Items ke groups sirf id ke liye store hain, read karte waqt latest groups lagte hain
  late final List<MenuItem> _items = [
    _item(1, 1, 'Chicken Tikka Pizza (M)', 1450, groups: [1, 2]),
    _item(2, 1, 'Fajita Pizza (M)', 1450, groups: [1, 2]),
    _item(3, 1, 'Veggie Pizza (M)', 1250, groups: [1, 2]),
    _item(4, 2, 'Nuggets (6pc)', 450),
    _item(5, 2, 'Fries', 350),
    _item(6, 2, 'Oven Baked Wings', 650),
    _item(7, 3, 'Zinger Burger', 650, groups: [3]),
    _item(8, 3, 'Beef Burger', 750, groups: [3]),
    _item(9, 4, 'Soft Drink', 150),
    _item(10, 4, 'Mineral Water', 100),
    _item(11, 4, 'Mint Margarita', 350, available: false),
  ];

  MenuItem _item(int id, int cat, String name, double price,
      {List<int> groups = const [], bool available = true}) {
    return MenuItem(
      id: id,
      categoryId: cat,
      name: name,
      price: price,
      isAvailable: available,
      modifierGroups: _groups.where((g) => groups.contains(g.id)).toList(),
    );
  }

  // ---------------- Floor ----------------
  final List<Hall> _halls = [
    const Hall(id: 1, name: 'Main Hall'),
    const Hall(id: 2, name: 'Family Hall'),
  ];

  final List<DiningTable> _tables = [
    const DiningTable(id: 1, hallId: 1, tableNumber: 1, capacity: 4),
    const DiningTable(id: 2, hallId: 1, tableNumber: 2, capacity: 4, status: TableStatus.occupied),
    const DiningTable(id: 3, hallId: 1, tableNumber: 3, capacity: 6),
    const DiningTable(id: 4, hallId: 1, tableNumber: 4, capacity: 2),
    const DiningTable(id: 5, hallId: 2, tableNumber: 1, capacity: 4),
    const DiningTable(id: 6, hallId: 2, tableNumber: 2, capacity: 6, status: TableStatus.billed),
    const DiningTable(id: 7, hallId: 2, tableNumber: 3, capacity: 8),
    const DiningTable(id: 8, hallId: 2, tableNumber: 4, capacity: 4),
  ];

  // ---------------- Tax & Settings (sample values, owner khud set karega) ----------------
  final List<PaymentMethod> _paymentMethods = [
    const PaymentMethod(id: 1, name: 'Cash', taxPercent: 16),
    const PaymentMethod(id: 2, name: 'Card', taxPercent: 5),
  ];

  AppSettings _settings = const AppSettings(
    restaurantName: 'PunchIt Demo Restaurant',
    serviceChargePercent: 0,
    serviceChargeDineInOnly: true,
    receiptFooter: 'Thank you! Dobara zaroor aayein.',
  );

  // ================= Helpers =================

  void _require(bool ok, String message) {
    if (!ok) throw Exception(message);
  }

  /// list mein id match ho to replace, warna naya id de ke add
  T _upsert<T>(List<T> list, T value, int Function(T) idOf, T Function(int) withId) {
    final id = idOf(value);
    if (id == 0) {
      final created = withId(_newId());
      list.add(created);
      return created;
    }
    final i = list.indexWhere((e) => idOf(e) == id);
    _require(i != -1, 'Record nahi mila');
    list[i] = value;
    return value;
  }

  // ================= Auth =================

  @override
  Future<Staff?> login(String employeeCode, String pin) async {
    await Future.delayed(_delay);
    final code = employeeCode.trim().toUpperCase();
    for (final s in _staff) {
      if (s.employeeCode.toUpperCase() == code && s.isActive && _pins[s.id] == pin) {
        return s;
      }
    }
    return null;
  }

  // ================= Order taking =================

  @override
  Future<List<MenuCategory>> getCategories() async {
    await Future.delayed(_delay);
    return List.of(_categories)..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  Future<List<MenuItem>> getMenuItems() async {
    await Future.delayed(_delay);
    // Har item ko latest topping groups ke saath lautao
    return _items.map((it) {
      final ids = it.modifierGroups.map((g) => g.id).toSet();
      return it.withGroups(_groups.where((g) => ids.contains(g.id)).toList());
    }).toList();
  }

  @override
  Future<List<Hall>> getHalls() async {
    await Future.delayed(_delay);
    return List.of(_halls);
  }

  @override
  Future<List<DiningTable>> getTables(int hallId) async {
    await Future.delayed(_delay);
    return _tables.where((t) => t.hallId == hallId).toList()
      ..sort((a, b) => a.tableNumber.compareTo(b.tableNumber));
  }

  @override
  Future<List<Staff>> getServers() async {
    await Future.delayed(_delay);
    return _staff.where((s) => s.role == StaffRoles.server && s.isActive).toList();
  }

  @override
  Future<int> placeOrder({
    required OrderType type,
    int? tableId,
    required int serverId,
    String? customerName,
    String? customerPhone,
    required List<CartItem> items,
  }) async {
    await Future.delayed(_delay);
    _require(items.isNotEmpty, 'Kam az kam 1 item add karo');

    if (type == OrderType.dineIn) {
      final i = _tables.indexWhere((t) => t.id == tableId);
      _require(i != -1, 'Table select karo');
      final t = _tables[i];
      _require(t.status == TableStatus.free, 'Table ${t.tableNumber} already occupied hai');
      _tables[i] = t.withStatus(TableStatus.occupied);
    }
    return _nextOrderId++;
  }

  @override
  Future<AppSettings> getSettings() async {
    await Future.delayed(_delay);
    return _settings;
  }

  @override
  Future<List<PaymentMethod>> getPaymentMethods() async {
    await Future.delayed(_delay);
    return List.of(_paymentMethods);
  }

  // ================= Admin: Menu =================

  @override
  Future<MenuCategory> saveCategory(MenuCategory c) async {
    await Future.delayed(_delay);
    final name = c.name.trim();
    _require(name.isNotEmpty, 'Category ka naam likho');
    _require(
      !_categories.any((x) => x.id != c.id && x.name.toLowerCase() == name.toLowerCase()),
      '"$name" naam ki category pehle se hai',
    );
    final clean = MenuCategory(id: c.id, name: name, stationId: c.stationId, sortOrder: c.sortOrder);
    return _upsert<MenuCategory>(_categories, clean, (x) => x.id,
        (id) => MenuCategory(id: id, name: name, stationId: c.stationId, sortOrder: c.sortOrder));
  }

  @override
  Future<void> deleteCategory(int id) async {
    await Future.delayed(_delay);
    final count = _items.where((i) => i.categoryId == id).length;
    _require(count == 0, 'Is category mein $count products hain. Pehle unhein delete ya move karo.');
    _categories.removeWhere((c) => c.id == id);
  }

  @override
  Future<MenuItem> saveMenuItem(MenuItem item) async {
    await Future.delayed(_delay);
    final name = item.name.trim();
    _require(name.isNotEmpty, 'Product ka naam likho');
    _require(item.price >= 0, 'Price sahi likho');
    _require(_categories.any((c) => c.id == item.categoryId), 'Category select karo');
    _require(
      !_items.any((x) => x.id != item.id && x.name.toLowerCase() == name.toLowerCase()),
      '"$name" naam ka product pehle se hai',
    );
    MenuItem build(int id) => MenuItem(
          id: id,
          categoryId: item.categoryId,
          name: name,
          price: item.price,
          stationId: item.stationId,
          isAvailable: item.isAvailable,
          modifierGroups: item.modifierGroups,
        );
    return _upsert<MenuItem>(_items, build(item.id), (x) => x.id, build);
  }

  @override
  Future<void> deleteMenuItem(int id) async {
    await Future.delayed(_delay);
    // Backend mein: agar item kisi purane order mein hai to delete ki jagah
    // is_available = false karo (purane bills ke liye record zaroori hai)
    _items.removeWhere((i) => i.id == id);
  }

  @override
  Future<List<ModifierGroup>> getModifierGroups() async {
    await Future.delayed(_delay);
    return List.of(_groups);
  }

  @override
  Future<ModifierGroup> saveModifierGroup(ModifierGroup g) async {
    await Future.delayed(_delay);
    final name = g.name.trim();
    _require(name.isNotEmpty, 'Group ka naam likho');
    _require(g.options.isNotEmpty, 'Kam az kam 1 option add karo');
    _require(g.maxSelect >= 1, 'Max select kam az kam 1 ho');
    _require(g.minSelect >= 0 && g.minSelect <= g.maxSelect, 'Min select, max se zyada nahi ho sakta');
    _require(g.minSelect <= g.options.length, 'Min select options se zyada hai');

    // Naye options (id 0) ko id do
    final options = g.options
        .map((o) => o.id == 0
            ? ModifierOption(id: _newId(), name: o.name.trim(), price: o.price, isAvailable: o.isAvailable)
            : o)
        .toList();

    ModifierGroup build(int id) =>
        ModifierGroup(id: id, name: name, minSelect: g.minSelect, maxSelect: g.maxSelect, options: options);
    return _upsert<ModifierGroup>(_groups, build(g.id), (x) => x.id, build);
  }

  @override
  Future<void> deleteModifierGroup(int id) async {
    await Future.delayed(_delay);
    _groups.removeWhere((g) => g.id == id);
    // Jin products pe yeh group laga tha unse hata do
    for (var i = 0; i < _items.length; i++) {
      final it = _items[i];
      if (it.modifierGroups.any((g) => g.id == id)) {
        _items[i] = it.withGroups(it.modifierGroups.where((g) => g.id != id).toList());
      }
    }
  }

  // ================= Admin: Kitchen =================

  @override
  Future<List<Station>> getStations() async {
    await Future.delayed(_delay);
    return List.of(_stations);
  }

  @override
  Future<Station> saveStation(Station s) async {
    await Future.delayed(_delay);
    final name = s.name.trim();
    _require(name.isNotEmpty, 'Station ka naam likho');
    final ip = (s.printerIp ?? '').trim();
    _require(ip.isEmpty || RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(ip), 'Printer IP sahi likho (e.g. 192.168.1.50)');
    Station build(int id) => Station(
          id: id,
          name: name,
          type: s.type,
          printerIp: ip.isEmpty ? null : ip,
          printerPort: s.printerPort,
          isActive: s.isActive,
        );
    return _upsert<Station>(_stations, build(s.id), (x) => x.id, build);
  }

  @override
  Future<void> deleteStation(int id) async {
    await Future.delayed(_delay);
    _stations.removeWhere((s) => s.id == id);
    // DB jaisa: ON DELETE SET NULL
    for (var i = 0; i < _categories.length; i++) {
      final c = _categories[i];
      if (c.stationId == id) {
        _categories[i] = MenuCategory(id: c.id, name: c.name, sortOrder: c.sortOrder);
      }
    }
    for (var i = 0; i < _items.length; i++) {
      final it = _items[i];
      if (it.stationId == id) {
        _items[i] = MenuItem(
          id: it.id,
          categoryId: it.categoryId,
          name: it.name,
          price: it.price,
          isAvailable: it.isAvailable,
          modifierGroups: it.modifierGroups,
        );
      }
    }
  }

  // ================= Admin: Floor =================

  @override
  Future<Hall> saveHall(Hall h) async {
    await Future.delayed(_delay);
    final name = h.name.trim();
    _require(name.isNotEmpty, 'Hall ka naam likho');
    return _upsert<Hall>(_halls, Hall(id: h.id, name: name), (x) => x.id, (id) => Hall(id: id, name: name));
  }

  @override
  Future<void> deleteHall(int id) async {
    await Future.delayed(_delay);
    final count = _tables.where((t) => t.hallId == id).length;
    _require(count == 0, 'Is hall mein $count tables hain. Pehle tables delete karo.');
    _halls.removeWhere((h) => h.id == id);
  }

  @override
  Future<DiningTable> saveTable(DiningTable t) async {
    await Future.delayed(_delay);
    _require(t.tableNumber > 0, 'Table number sahi likho');
    _require(t.capacity > 0, 'Seats kam az kam 1');
    _require(
      !_tables.any((x) => x.id != t.id && x.hallId == t.hallId && x.tableNumber == t.tableNumber),
      'Is hall mein Table ${t.tableNumber} pehle se hai',
    );
    // Status edit nahi hota, purana status rakho
    final old = _tables.where((x) => x.id == t.id).firstOrNull;
    DiningTable build(int id) => DiningTable(
          id: id,
          hallId: t.hallId,
          tableNumber: t.tableNumber,
          capacity: t.capacity,
          status: old?.status ?? TableStatus.free,
        );
    return _upsert<DiningTable>(_tables, build(t.id), (x) => x.id, build);
  }

  @override
  Future<void> deleteTable(int id) async {
    await Future.delayed(_delay);
    final t = _tables.firstWhere((x) => x.id == id);
    _require(t.status == TableStatus.free, 'Table ${t.tableNumber} pe order chal raha hai, abhi delete nahi ho sakti');
    _tables.removeWhere((x) => x.id == id);
  }

  // ================= Admin: Staff =================

  @override
  Future<List<Staff>> getAllStaff() async {
    await Future.delayed(_delay);
    return List.of(_staff);
  }

  @override
  Future<Staff> saveStaff(Staff s, {String? newPin}) async {
    await Future.delayed(_delay);
    final name = s.name.trim();
    final code = s.employeeCode.trim().toUpperCase();
    _require(name.isNotEmpty, 'Naam likho');
    _require(code.isNotEmpty, 'Employee code likho');
    _require(StaffRoles.all.contains(s.role), 'Role select karo');
    _require(!_staff.any((x) => x.id != s.id && x.employeeCode.toUpperCase() == code),
        'Employee code $code pehle se kisi aur ka hai');
    if (s.id == 0) _require(newPin != null, 'Naye staff ka PIN zaroori hai');
    if (newPin != null) _require(RegExp(r'^\d{4}$').hasMatch(newPin), 'PIN 4 digits ka ho');

    // Aakhri active manager/owner ko inactive ya server nahi bana sakte
    final old = _staff.where((x) => x.id == s.id).firstOrNull;
    final wasActiveAdmin = old != null && old.isActive && old.isAdmin;
    final staysActiveAdmin = s.isActive && s.isAdmin;
    if (wasActiveAdmin && !staysActiveAdmin) {
      final otherAdmins = _staff.where((x) => x.id != s.id && x.isActive && x.isAdmin).length;
      _require(otherAdmins > 0, 'Kam az kam 1 active Manager/Owner hona zaroori hai');
    }

    Staff build(int id) => Staff(id: id, employeeCode: code, name: name, role: s.role, isActive: s.isActive);
    final saved = _upsert<Staff>(_staff, build(s.id), (x) => x.id, build);
    if (newPin != null) _pins[saved.id] = newPin;
    return saved;
  }

  // ================= Admin: Tax & Settings =================

  @override
  Future<PaymentMethod> savePaymentMethod(PaymentMethod m) async {
    await Future.delayed(_delay);
    final name = m.name.trim();
    _require(name.isNotEmpty, 'Payment method ka naam likho');
    _require(m.taxPercent >= 0 && m.taxPercent <= 100, 'Tax 0 se 100% ke beech ho');
    _require(!_paymentMethods.any((x) => x.id != m.id && x.name.toLowerCase() == name.toLowerCase()),
        '"$name" pehle se hai');
    if (!m.isActive) {
      final otherActive = _paymentMethods.where((x) => x.id != m.id && x.isActive).length;
      _require(otherActive > 0, 'Kam az kam 1 payment method active hona chahiye');
    }
    PaymentMethod build(int id) => PaymentMethod(id: id, name: name, taxPercent: m.taxPercent, isActive: m.isActive);
    return _upsert<PaymentMethod>(_paymentMethods, build(m.id), (x) => x.id, build);
  }

  @override
  Future<void> deletePaymentMethod(int id) async {
    await Future.delayed(_delay);
    final otherActive = _paymentMethods.where((x) => x.id != id && x.isActive).length;
    _require(otherActive > 0, 'Kam az kam 1 payment method active hona chahiye');
    _paymentMethods.removeWhere((x) => x.id == id);
  }

  @override
  Future<AppSettings> saveSettings(AppSettings s) async {
    await Future.delayed(_delay);
    _require(s.restaurantName.trim().isNotEmpty, 'Restaurant ka naam likho');
    _require(s.serviceChargePercent >= 0 && s.serviceChargePercent <= 100, 'Service charge 0 se 100% ke beech ho');
    _settings = s;
    return s;
  }
}

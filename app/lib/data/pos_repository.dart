import '../models/models.dart';

abstract class PosRepository {
  Future<Staff?> login(String employeeCode, String pin);

  Future<List<MenuCategory>> getCategories();

  Future<List<MenuItem>> getMenuItems();

  Future<List<Hall>> getHalls();

  Future<List<DiningTable>> getTables(int hallId);

  Future<List<Staff>> getServers();

  Future<int> placeOrder({
    required OrderType type,
    int? tableId,
    required int serverId,
    String? customerName,
    String? customerPhone,
    required List<CartItem> items,
  });

  Future<AppSettings> getSettings();

  Future<List<PlacedOrder>> getOrders({bool activeOnly = false});

  Future<void> updateKitchenStatus(int orderId, KitchenStatus status);

  Future<PlacedOrder> payOrder({
    required int orderId,
    required PaymentMethod method,
    double discount = 0,
    required double amountReceived,
    String reference = '',
  });

  Future<List<PaymentMethod>> getPaymentMethods();

  Future<MenuCategory> saveCategory(MenuCategory category);
  Future<void> deleteCategory(int id);

  Future<MenuItem> saveMenuItem(MenuItem item);
  Future<void> deleteMenuItem(int id);

  Future<List<ModifierGroup>> getModifierGroups();
  Future<ModifierGroup> saveModifierGroup(ModifierGroup group);
  Future<void> deleteModifierGroup(int id);

  Future<List<Station>> getStations();
  Future<Station> saveStation(Station station);
  Future<void> deleteStation(int id);

  Future<Hall> saveHall(Hall hall);
  Future<void> deleteHall(int id);

  Future<DiningTable> saveTable(DiningTable table);
  Future<void> deleteTable(int id);

  Future<List<Staff>> getAllStaff();

  Future<Staff> saveStaff(Staff staff, {String? newPin});

  Future<PaymentMethod> savePaymentMethod(PaymentMethod method);
  Future<void> deletePaymentMethod(int id);

  Future<AppSettings> saveSettings(AppSettings settings);
}

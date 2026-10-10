import '../models/models.dart';

/// Screens sirf is interface se baat karti hain.
/// Abhi MockPosRepository (dummy data), baad mein ApiPosRepository (Node API).
/// Screens ka code change nahi hoga, sirf main.dart mein ek line.
///
/// save...() methods: id == 0 to naya record banao, warna update karo.
/// Galti ho to Exception('Roman Urdu message') throw karo, screen woh dikha degi.
abstract class PosRepository {
  // ================= Auth =================

  /// Employee code + PIN se login. Galat ho ya staff inactive ho to null.
  Future<Staff?> login(String employeeCode, String pin);

  // ================= Order taking (server) =================

  /// sort_order ke hisaab se
  Future<List<MenuCategory>> getCategories();

  /// Saare items (unavailable bhi). Har item ke saath uske topping groups.
  Future<List<MenuItem>> getMenuItems();

  Future<List<Hall>> getHalls();

  /// Hall ki tables, current status (free/occupied/billed) ke saath
  Future<List<DiningTable>> getTables(int hallId);

  /// Sirf active servers (order pe server name select karne ke liye)
  Future<List<Staff>> getServers();

  /// Order banao + kitchen ko bhejo. Return: order id
  Future<int> placeOrder({
    required OrderType type,
    int? tableId,
    required int serverId,
    String? customerName,
    String? customerPhone,
    required List<CartItem> items,
  });

  Future<AppSettings> getSettings();

  /// Saare methods (inactive bhi). Order/bill pe sirf active use karo.
  Future<List<PaymentMethod>> getPaymentMethods();

  // ================= Admin: Menu =================

  Future<MenuCategory> saveCategory(MenuCategory category);
  Future<void> deleteCategory(int id);

  Future<MenuItem> saveMenuItem(MenuItem item);
  Future<void> deleteMenuItem(int id);

  Future<List<ModifierGroup>> getModifierGroups();
  Future<ModifierGroup> saveModifierGroup(ModifierGroup group);
  Future<void> deleteModifierGroup(int id);

  // ================= Admin: Kitchen =================

  Future<List<Station>> getStations();
  Future<Station> saveStation(Station station);
  Future<void> deleteStation(int id);

  // ================= Admin: Floor =================

  Future<Hall> saveHall(Hall hall);
  Future<void> deleteHall(int id);

  Future<DiningTable> saveTable(DiningTable table);
  Future<void> deleteTable(int id);

  // ================= Admin: Staff =================

  /// Saara staff (inactive bhi)
  Future<List<Staff>> getAllStaff();

  /// Naye staff ke liye [newPin] zaroori. Purane ka PIN reset karna ho to do.
  Future<Staff> saveStaff(Staff staff, {String? newPin});

  // ================= Admin: Tax & Settings =================

  Future<PaymentMethod> savePaymentMethod(PaymentMethod method);
  Future<void> deletePaymentMethod(int id);

  Future<AppSettings> saveSettings(AppSettings settings);
}

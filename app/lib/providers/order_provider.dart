import 'package:flutter/foundation.dart';

import '../models/models.dart';

class OrderProvider extends ChangeNotifier {
  Staff? loggedInStaff;

  OrderType? orderType;

  Hall? hall;
  DiningTable? table;
  Staff? server;

  String customerName = '';
  String customerPhone = '';

  final List<CartItem> cart = [];

  int get itemCount => cart.fold(0, (sum, c) => sum + c.quantity);

  double get subtotal => cart.fold(0.0, (sum, c) => sum + c.lineTotal);

  bool get isDineIn => orderType == OrderType.dineIn;

  bool get hasTableDetails => !isDineIn || (table != null && server != null);

  void login(Staff staff) {
    loggedInStaff = staff;
    notifyListeners();
  }

  void logout() {
    loggedInStaff = null;
    resetOrder();
  }

  void startOrder(OrderType type) {
    resetOrder(notify: false);
    orderType = type;
    server = loggedInStaff;
    notifyListeners();
  }

  void setTableDetails({
    required Hall hall,
    required DiningTable table,
    required Staff server,
  }) {
    this.hall = hall;
    this.table = table;
    this.server = server;
    notifyListeners();
  }

  void setCustomer(String name, String phone) {
    customerName = name;
    customerPhone = phone;
    notifyListeners();
  }

  void addToCart(CartItem item) {
    cart.add(item);
    notifyListeners();
  }

  void updateCartItem(int index, CartItem updated) {
    cart[index] = updated;
    notifyListeners();
  }

  void changeQty(int index, int delta) {
    final c = cart[index];
    c.quantity += delta;
    if (c.quantity <= 0) cart.removeAt(index);
    notifyListeners();
  }

  void removeFromCart(int index) {
    cart.removeAt(index);
    notifyListeners();
  }

  void resetOrder({bool notify = true}) {
    orderType = null;
    hall = null;
    table = null;
    server = null;
    customerName = '';
    customerPhone = '';
    cart.clear();
    if (notify) notifyListeners();
  }
}

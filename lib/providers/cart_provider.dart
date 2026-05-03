import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartItem {
  final int id;
  final String name;
  final double priceUsd;
  final String? imageUrl;
  int qty;

  CartItem({required this.id, required this.name, required this.priceUsd, this.imageUrl, this.qty = 1});
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void add(CartItem item) {
    final idx = state.indexWhere((i) => i.id == item.id);
    if (idx >= 0) {
      final updated = List<CartItem>.from(state);
      updated[idx].qty++;
      state = updated;
    } else {
      state = [...state, item];
    }
  }

  void remove(int id) => state = state.where((i) => i.id != id).toList();

  void increment(int id) {
    final updated = List<CartItem>.from(state);
    final idx = updated.indexWhere((i) => i.id == id);
    if (idx >= 0) updated[idx].qty++;
    state = updated;
  }

  void decrement(int id) {
    final updated = List<CartItem>.from(state);
    final idx = updated.indexWhere((i) => i.id == id);
    if (idx >= 0) {
      updated[idx].qty--;
      if (updated[idx].qty <= 0) updated.removeAt(idx);
    }
    state = updated;
  }

  void clear() => state = [];

  double get total => state.fold(0, (sum, i) => sum + i.priceUsd * i.qty);
  int get count => state.fold(0, (sum, i) => sum + i.qty);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>(
  (_) => CartNotifier(),
);

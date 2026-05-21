import 'menu_product.dart';

class CartItem {
  const CartItem({
    required this.product,
    required this.quantity,
  });

  final MenuProduct product;
  final int quantity;

  double get subtotal => product.price * quantity;

  CartItem copyWith({
    MenuProduct? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

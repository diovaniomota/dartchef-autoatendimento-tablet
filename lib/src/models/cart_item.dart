import 'menu_product.dart';

class CartItem {
  const CartItem({
    required this.product,
    required this.quantity,
    this.notes = '',
  });

  final MenuProduct product;
  final int quantity;

  /// Observacao do cliente para ESTE item ("sem salada", "com gelo").
  ///
  /// Vai para restaurant_order_items.notes e aparece no PDV, na tela de
  /// Comandas e na impressao da conferencia de conta.
  final String notes;

  double get subtotal => product.price * quantity;

  /// Duas linhas do carrinho so sao "o mesmo item" quando produto E observacao
  /// coincidem: um lanche sem salada nao pode ser somado com um normal, senao
  /// a cozinha perde a instrucao.
  bool matches(MenuProduct other, String otherNotes) =>
      product.id == other.id && notes.trim() == otherNotes.trim();

  CartItem copyWith({
    MenuProduct? product,
    int? quantity,
    String? notes,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }
}

import 'menu_product.dart';

class CartItem {
  const CartItem({
    required this.product,
    required this.quantity,
    this.notes = '',
    this.chosenOptions = const [],
  });

  final MenuProduct product;
  final int quantity;

  /// Observacao do cliente para ESTE item ("sem salada", "com gelo").
  ///
  /// Vai para restaurant_order_items.notes e aparece no PDV, na tela de
  /// Comandas e na impressao da conferencia de conta.
  final String notes;

  /// Variacoes escolhidas pelo cliente (vodka, cachaca...). Diferente de
  /// [notes]: aqui ele escolheu de uma lista, la ele digitou.
  final List<ProductOptionChoice> chosenOptions;

  /// Texto das escolhas, para exibir no carrinho e na confirmacao.
  String get optionsLabel => chosenOptions.map((o) => o.name).join(', ');

  /// Preco unitario com as escolhas somadas. Vale so para a tela: o valor
  /// cobrado e recalculado no servidor a partir dos IDs enviados.
  double get unitPrice =>
      product.price + chosenOptions.fold(0.0, (soma, o) => soma + o.priceDelta);

  double get subtotal => unitPrice * quantity;

  /// Duas linhas do carrinho so sao "o mesmo item" quando produto E observacao
  /// coincidem: um lanche sem salada nao pode ser somado com um normal, senao
  /// a cozinha perde a instrucao.
  bool matches(MenuProduct other, String otherNotes) =>
      product.id == other.id &&
      notes.trim() == otherNotes.trim() &&
      chosenOptions.isEmpty;

  /// Mesmo criterio de [matches], mas comparando tambem as variacoes: uma
  /// caipira com vodka nao pode virar "2x" junto com uma de cachaca.
  bool matchesWithOptions(
    MenuProduct other,
    String otherNotes,
    List<ProductOptionChoice> otherOptions,
  ) {
    if (product.id != other.id) return false;
    if (notes.trim() != otherNotes.trim()) return false;
    if (chosenOptions.length != otherOptions.length) return false;
    final meus = chosenOptions.map((o) => o.id).toList()..sort();
    final deles = otherOptions.map((o) => o.id).toList()..sort();
    for (var i = 0; i < meus.length; i += 1) {
      if (meus[i] != deles[i]) return false;
    }
    return true;
  }

  CartItem copyWith({
    MenuProduct? product,
    int? quantity,
    String? notes,
    List<ProductOptionChoice>? chosenOptions,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      chosenOptions: chosenOptions ?? this.chosenOptions,
    );
  }
}

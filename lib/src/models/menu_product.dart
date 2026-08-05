class MenuProduct {
  const MenuProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    this.subcategory,
    this.imageUrl,
    this.description = '',
  });

  final int id;
  final String name;
  final String brand;
  final String category;
  final double price;
  final String? subcategory;
  final String? imageUrl;

  /// Descricao cadastrada pelo RESTAURANTE em Cardapio Tablet ("pao brioche,
  /// hamburguer 180g..."), exibida abaixo do nome para o cliente saber o que
  /// vem no prato.
  ///
  /// Nao confundir com CartItem.notes, que e a observacao que o CLIENTE digita
  /// no momento do pedido.
  ///
  /// Opcional: cardapio servido por versao anterior do sistema nao traz o
  /// campo, e o app precisa continuar funcionando sem ele.
  final String description;

  factory MenuProduct.fromJson(Map<String, dynamic> json) {
    return MenuProduct(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      category: json['category'] as String? ?? 'Cardapio',
      price: double.tryParse('${json['price'] ?? 0}') ?? 0,
      subcategory: json['subcategory'] as String?,
      imageUrl: json['image_url'] as String?,
      description: (json['description'] as String? ?? '').trim(),
    );
  }
}

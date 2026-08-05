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
    this.optionGroups = const [],
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

  /// Variacoes que o cliente escolhe na hora de pedir ("Caipira de morango"
  /// com vodka ou com cachaca). Vazio na maioria dos produtos.
  final List<ProductOptionGroup> optionGroups;

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
      optionGroups: ((json['option_groups'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ProductOptionGroup.fromJson)
          .where((group) => group.choices.isNotEmpty)
          .toList(),
    );
  }
}

/// Pergunta feita ao cliente sobre um produto. Ex.: nome 'Tipo', opcoes
/// 'Vodka' e 'Cachaca'.
class ProductOptionGroup {
  const ProductOptionGroup({
    required this.id,
    required this.name,
    required this.required,
    required this.choices,
  });

  final int id;
  final String name;
  final bool required;
  final List<ProductOptionChoice> choices;

  factory ProductOptionGroup.fromJson(Map<String, dynamic> json) {
    return ProductOptionGroup(
      id: json['id'] as int,
      name: (json['name'] as String? ?? '').trim(),
      required: json['required'] as bool? ?? true,
      choices: ((json['choices'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ProductOptionChoice.fromJson)
          .toList(),
    );
  }
}

class ProductOptionChoice {
  const ProductOptionChoice({
    required this.id,
    required this.name,
    required this.priceDelta,
  });

  final int id;
  final String name;

  /// Quanto esta opcao soma (ou desconta) no preco do produto. O tablet usa
  /// so para MOSTRAR: quem calcula o valor cobrado e o servidor.
  final double priceDelta;

  factory ProductOptionChoice.fromJson(Map<String, dynamic> json) {
    return ProductOptionChoice(
      id: json['id'] as int,
      name: (json['name'] as String? ?? '').trim(),
      priceDelta: double.tryParse('${json['price_delta'] ?? 0}') ?? 0,
    );
  }
}

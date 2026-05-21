class MenuProduct {
  const MenuProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    this.subcategory,
    this.imageUrl,
  });

  final int id;
  final String name;
  final String brand;
  final String category;
  final double price;
  final String? subcategory;
  final String? imageUrl;

  factory MenuProduct.fromJson(Map<String, dynamic> json) {
    return MenuProduct(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      category: json['category'] as String? ?? 'Cardapio',
      price: double.tryParse('${json['price'] ?? 0}') ?? 0,
      subcategory: json['subcategory'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }
}

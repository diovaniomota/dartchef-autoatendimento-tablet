import 'menu_product.dart';

class TableMenu {
  const TableMenu({
    required this.organizationId,
    required this.organizationName,
    required this.tableCode,
    required this.tableName,
    required this.categories,
    required this.subcategories,
    required this.products,
  });

  final String organizationId;
  final String organizationName;
  final String tableCode;
  final String tableName;
  final List<String> categories;
  final Map<String, List<String>> subcategories; // category name -> list of subcategory names
  final List<MenuProduct> products;

  factory TableMenu.fromJson(Map<String, dynamic> json) {
    final organization = json['organization'] as Map<String, dynamic>? ?? {};
    final table = json['table'] as Map<String, dynamic>? ?? {};
    final categories = (json['categories'] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .toList();
    final products = (json['products'] as List<dynamic>? ?? [])
        .map((item) => MenuProduct.fromJson(item as Map<String, dynamic>))
        .toList();

    // Parse subcategories: { "Lanches": ["Gourmet", "Clássicos"], ... }
    final rawSubs = json['subcategories'] as Map<String, dynamic>? ?? {};
    final subcategories = <String, List<String>>{};
    for (final entry in rawSubs.entries) {
      final list = (entry.value as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      if (list.isNotEmpty) subcategories[entry.key] = list;
    }

    return TableMenu(
      organizationId: organization['id']?.toString() ?? '',
      organizationName: organization['nome_fantasia']?.toString().trim().isNotEmpty == true
          ? organization['nome_fantasia'].toString()
          : organization['razao_social']?.toString() ?? 'Organizacao',
      tableCode: table['code']?.toString() ?? '',
      tableName: table['name']?.toString() ?? '',
      categories: categories,
      subcategories: subcategories,
      products: products,
    );
  }
}

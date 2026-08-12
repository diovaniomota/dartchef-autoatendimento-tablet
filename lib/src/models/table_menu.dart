import '../core/app_language.dart';
import 'home_block.dart';
import 'menu_product.dart';

class TableMenu {
  const TableMenu({
    required this.organizationId,
    required this.organizationName,
    required this.tableCode,
    required this.tableName,
    required this.categories,
    this.categoryImages = const {},
    this.categoryTranslations = const {},
    required this.subcategories,
    required this.products,
    this.logoUrl = '',
    this.backgroundUrl = '',
    this.primaryColor = '',
    this.homeBlocks = const [],
  });

  final String organizationId;
  final String organizationName;
  final String tableCode;
  final String tableName;
  final List<String> categories;

  /// Foto escolhida pelo restaurante para o cartao de cada categoria, por nome.
  /// Categoria ausente aqui cai na foto de um produto dela.
  final Map<String, String> categoryImages;

  /// Traducao do nome de cada categoria, indexada pelo nome ORIGINAL.
  ///
  /// O nome em portugues continua sendo a chave que liga produto e categoria; a
  /// traducao e so rotulo de tela. Trocar a chave quebraria o agrupamento assim
  /// que alguem escolhesse ingles.
  final Map<String, Map<String, String>> categoryTranslations;

  /// Nome da categoria no idioma da tela.
  String labelForCategory(String categoria) {
    final sufixo = switch (appLanguage.value) {
      AppLanguage.pt => null,
      AppLanguage.en => 'en',
      AppLanguage.es => 'es',
    };
    if (sufixo == null) return categoria;
    final valor = (categoryTranslations[categoria]?[sufixo] ?? '').trim();
    return valor.isEmpty ? categoria : valor;
  }
  final Map<String, List<String>> subcategories; // category name -> list of subcategory names
  final List<MenuProduct> products;

  /// Marca do restaurante, exibida na tela de espera. Opcional: servidor em
  /// versao anterior nao manda, e a tela cai num fundo escuro com o nome do
  /// restaurante em texto.
  final String logoUrl;
  final String backgroundUrl;

  /// Cor do botao "toque para comecar", em hex (#ea580c). Vazio = cor do app.
  final String primaryColor;

  /// Tela de inicio montada pelo restaurante. Vazia = arranjo padrao do app.
  final List<HomeBlock> homeBlocks;

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
      categoryImages: ((json['category_images'] as Map<dynamic, dynamic>?) ?? const {})
          .map((chave, valor) => MapEntry('$chave', '$valor'))
        ..removeWhere((_, valor) => valor.trim().isEmpty),
      categoryTranslations: ((json['category_translations'] as Map<dynamic, dynamic>?) ?? const {})
          .map((categoria, traducoes) => MapEntry(
                '$categoria',
                ((traducoes as Map<dynamic, dynamic>?) ?? const {})
                    .map((idioma, texto) => MapEntry('$idioma', '$texto')),
              )),
      subcategories: subcategories,
      products: products,
      logoUrl: organization['logo_url']?.toString() ?? '',
      backgroundUrl: organization['background_url']?.toString() ?? '',
      homeBlocks: HomeBlock.listaFromJson(organization['home_layout']),
      primaryColor: organization['primary_color']?.toString() ?? '',
    );
  }
}

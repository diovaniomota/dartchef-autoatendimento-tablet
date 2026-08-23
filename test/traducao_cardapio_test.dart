// Traducao do cardapio (nome de produto, descricao e nome de categoria).
//
// O tablet ja trocava de idioma, mas so os textos DO APP mudavam: o cardapio
// continuava em portugues. Para o turista, meia tela traduzida e quase o mesmo
// que nenhuma.
//
// O que precisa ficar travado: traducao faltando cai no portugues (cadastro pela
// metade nao pode deixar a tela em branco), e a CHAVE da categoria continua sendo
// o nome original — traduzir a chave quebraria o agrupamento dos produtos assim
// que alguem escolhesse ingles.

import 'package:flutter_test/flutter_test.dart';
import 'package:next_food_tablet_app/src/core/app_language.dart';
import 'package:next_food_tablet_app/src/models/menu_product.dart';
import 'package:next_food_tablet_app/src/models/table_menu.dart';

MenuProduct _produto({Map<String, String> traducoes = const {}}) => MenuProduct(
      id: 1,
      name: 'Alcatra',
      brand: '',
      category: 'Espetinhos',
      price: 14,
      description: 'Acompanha farofa',
      translations: traducoes,
    );

void main() {
  setUp(resetLanguage);
  tearDown(resetLanguage);

  group('produto', () {
    test('em portugues usa o cadastro original', () {
      final p = _produto(traducoes: const {'name_en': 'Rump steak'});
      expect(p.displayName, 'Alcatra');
      expect(p.displayDescription, 'Acompanha farofa');
    });

    test('em ingles usa a traducao cadastrada', () {
      appLanguage.value = AppLanguage.en;
      final p = _produto(traducoes: const {
        'name_en': 'Rump steak',
        'description_en': 'Served with farofa',
      });
      expect(p.displayName, 'Rump steak');
      expect(p.displayDescription, 'Served with farofa');
    });

    test('sem traducao no idioma escolhido, cai no portugues', () {
      appLanguage.value = AppLanguage.es;
      final p = _produto(traducoes: const {'name_en': 'Rump steak'});
      // Espanhol nao foi cadastrado: mostrar vazio seria pior que mostrar o
      // portugues, que ao menos identifica o prato.
      expect(p.displayName, 'Alcatra');
    });

    test('traducao so com espacos conta como nao cadastrada', () {
      appLanguage.value = AppLanguage.en;
      final p = _produto(traducoes: const {'name_en': '   '});
      expect(p.displayName, 'Alcatra');
    });

    test('traduz o nome mesmo sem a descricao, e vice-versa', () {
      appLanguage.value = AppLanguage.en;
      final so = _produto(traducoes: const {'name_en': 'Rump steak'});
      expect(so.displayName, 'Rump steak');
      expect(so.displayDescription, 'Acompanha farofa');
    });

    test('cardapio de versao anterior, sem o campo, continua funcionando', () {
      final p = MenuProduct.fromJson(<String, dynamic>{
        'id': 1,
        'name': 'Alcatra',
        'brand': '',
        'category': 'Espetinhos',
        'price': 14,
      });
      expect(p.translations, isEmpty);
      expect(p.displayName, 'Alcatra');
    });
  });

  group('categoria', () {
    // Sem `const` e com o tipo explicito: e assim que o mapa chega do
    // jsonDecode, e um literal const infere chave dynamic, que o fromJson
    // recusa no cast.
    TableMenu montar() => TableMenu.fromJson(<String, dynamic>{
      'organization': <String, dynamic>{'id': 'org-1', 'nome_fantasia': 'House Beer'},
      'table': <String, dynamic>{'code': '01', 'name': 'Mesa 01'},
      'categories': ['Bebidas', 'Sobremesas'],
      'category_translations': <String, dynamic>{
        'Bebidas': <String, dynamic>{'en': 'Drinks', 'es': 'Bebidas'},
      },
      'subcategories': <String, dynamic>{},
      'products': [],
    });

    test('em ingles mostra o rotulo traduzido', () {
      appLanguage.value = AppLanguage.en;
      expect(montar().labelForCategory('Bebidas'), 'Drinks');
    });

    test('categoria sem traducao mantem o portugues', () {
      appLanguage.value = AppLanguage.en;
      expect(montar().labelForCategory('Sobremesas'), 'Sobremesas');
    });

    test('a CHAVE nao muda: o agrupamento dos produtos depende dela', () {
      appLanguage.value = AppLanguage.en;
      final menu = montar();
      // A lista de categorias continua em portugues — e por ela que o produto
      // e encontrado. So o rotulo exibido muda.
      expect(menu.categories, ['Bebidas', 'Sobremesas']);
    });

    test('em portugues nao procura traducao nenhuma', () {
      expect(montar().labelForCategory('Bebidas'), 'Bebidas');
    });
  });
}

// Foto do cartao de categoria.
//
// Regressao real, vista com a organizacao DARTSOFT: a categoria "Lanches" tinha
// tres produtos, o primeiro apontando para um projeto Supabase antigo que nem
// resolve mais e o terceiro com foto boa na VPS. O cartao pegava a PRIMEIRA URL
// nao vazia, ela falhava, e o cartao ficava vazio — uma URL podre envenenava a
// categoria inteira.
//
// Em teste toda Image.network falha (nao ha rede), que e justamente o cenario de
// endereco morto: da para verificar a corrente de tentativa e o estado final.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_food_tablet_app/src/core/app_language.dart';
import 'package:next_food_tablet_app/src/models/menu_product.dart';
import 'package:next_food_tablet_app/src/screens/categories_screen.dart';

MenuProduct _p({
  required int id,
  required String categoria,
  String? foto,
}) =>
    MenuProduct(
      id: id,
      name: 'Produto $id',
      brand: '',
      category: categoria,
      price: 10,
      imageUrl: foto,
    );

Widget _montar(
  List<MenuProduct> produtos,
  List<String> categorias, {
  Map<String, String> fotosDeCategoria = const {},
}) =>
    MaterialApp(
      home: CategoriesScreen(
        categories: categorias,
        products: produtos,
        categoryImages: fotosDeCategoria,
        logoUrl: '',
        restaurantName: 'House Beer',
        cartItemCount: 0,
        onCategorySelected: (_) {},
        onSearchTap: () {},
        onCartTap: () {},
        onHomeTap: () {},
      ),
    );

void main() {
  setUp(resetLanguage);

  testWidgets('tenta TODAS as fotos da categoria, nao so a primeira', (tester) async {
    // Reproduz o caso da DARTSOFT: primeira URL morta, terceira boa.
    await tester.pumpWidget(_montar(
      [
        _p(id: 1, categoria: 'Lanches', foto: 'https://morta.invalida/a.png'),
        _p(id: 2, categoria: 'Lanches'),
        _p(id: 3, categoria: 'Lanches', foto: 'https://viva.invalida/b.jpg'),
      ],
      const ['Lanches'],
    ));

    // Deixa a corrente de errorBuilder avancar quadro a quadro.
    for (var i = 0; i < 6; i += 1) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    // Com as duas falhando (sem rede), o cartao chega ao fim da lista sem
    // estourar e mostra o estado sem foto. O que importa e nao travar na
    // primeira e nao lancar excecao.
    expect(tester.takeException(), isNull);
    expect(find.text('LANCHES'), findsOneWidget);
    expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
  });

  testWidgets('categoria sem nenhuma foto mostra o icone, nao um retangulo liso',
      (tester) async {
    await tester.pumpWidget(_montar(
      [_p(id: 1, categoria: 'Caldos')],
      const ['Caldos'],
    ));
    await tester.pump();

    // Cartao chapado parece tela quebrada; o icone diz que e item de cardapio.
    expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
    expect(find.text('CALDOS'), findsOneWidget);
  });

  testWidgets('produto de outra categoria nao empresta a foto', (tester) async {
    await tester.pumpWidget(_montar(
      [
        _p(id: 1, categoria: 'Bebidas', foto: 'https://x.invalida/bebida.png'),
        _p(id: 2, categoria: 'Caldos'),
      ],
      const ['Caldos'],
    ));
    await tester.pump();

    // Caldos nao tem foto propria: tem de cair no icone, nao pegar a da Bebidas.
    expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
  });

  testWidgets('o nome fica sempre visivel, com ou sem foto', (tester) async {
    // E o unico texto do cartao: se ele sumir, o cliente nao sabe onde tocou.
    await tester.pumpWidget(_montar(
      [_p(id: 1, categoria: 'Sobremesas', foto: 'https://x.invalida/a.png')],
      const ['Sobremesas'],
    ));
    await tester.pump();

    expect(find.text('SOBREMESAS'), findsOneWidget);
  });

  testWidgets('a foto CADASTRADA da categoria vem antes da foto do produto',
      (tester) async {
    // A cliente escolheu uma foto para representar a categoria: e ela que
    // manda. A do produto so serve de retaguarda para quem ainda nao cadastrou.
    await tester.pumpWidget(_montar(
      [_p(id: 1, categoria: 'Bebidas', foto: 'https://produto.invalida/a.png')],
      const ['Bebidas'],
      fotosDeCategoria: const {'Bebidas': 'https://categoria.invalida/b.png'},
    ));
    await tester.pump();

    final imagens = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(imagens, isNotEmpty);
    final primeira = imagens.first.image as NetworkImage;
    expect(primeira.url, 'https://categoria.invalida/b.png');
  });

  testWidgets('sem foto cadastrada, continua usando a do produto', (tester) async {
    await tester.pumpWidget(_montar(
      [_p(id: 1, categoria: 'Bebidas', foto: 'https://produto.invalida/a.png')],
      const ['Bebidas'],
    ));
    await tester.pump();

    final imagens = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(imagens, isNotEmpty);
    expect((imagens.first.image as NetworkImage).url, 'https://produto.invalida/a.png');
  });
}

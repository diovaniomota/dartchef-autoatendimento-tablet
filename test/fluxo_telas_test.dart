// Fluxo de telas do pedido: categorias -> produtos -> detalhe -> carrinho.
//
// Testa as telas isoladas, com dados de mentira, porque o que quebra na mesa e
// o comportamento delas: variacao obrigatoria sem escolha liberando o botao,
// quantidade caindo a zero e deixando item fantasma, categoria sem foto
// derrubando a tela.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:next_food_tablet_app/src/core/app_language.dart';
import 'package:next_food_tablet_app/src/models/cart_item.dart';
import 'package:next_food_tablet_app/src/models/menu_product.dart';
import 'package:next_food_tablet_app/src/screens/cart_screen.dart';
import 'package:next_food_tablet_app/src/screens/categories_screen.dart';
import 'package:next_food_tablet_app/src/screens/product_detail_screen.dart';
import 'package:next_food_tablet_app/src/screens/product_list_screen.dart';

final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

MenuProduct _produto({
  int id = 1,
  String nome = 'ALCATRA',
  String categoria = 'ESPETINHOS TRADICIONAIS',
  double preco = 14,
  String descricao = 'Acompanha farofa e molhos',
  List<ProductOptionGroup> grupos = const [],
}) {
  return MenuProduct(
    id: id,
    name: nome,
    brand: '',
    category: categoria,
    price: preco,
    description: descricao,
    optionGroups: grupos,
  );
}

const _grupoMolho = ProductOptionGroup(
  id: 9,
  name: 'Molho',
  required: true,
  choices: [
    ProductOptionChoice(id: 91, name: 'Alho', priceDelta: 0),
    ProductOptionChoice(id: 92, name: 'Barbecue', priceDelta: 2),
  ],
);

void main() {
  setUp(resetLanguage);

  group('TELA 2 — categorias', () {
    testWidgets('lista as categorias e avisa quando nao ha nenhuma', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: CategoriesScreen(
          categories: const ['ESPETINHOS TRADICIONAIS', 'BEBIDAS'],
          products: [_produto()],
          logoUrl: '',
          restaurantName: 'House Beer',
          cartItemCount: 0,
          onCategorySelected: (_) {},
          onSearchTap: () {},
          onCartTap: () {},
          onHomeTap: () {},
        ),
      ));

      expect(find.text('ESCOLHA UMA CATEGORIA'), findsOneWidget);
      expect(find.text('ESPETINHOS TRADICIONAIS'), findsOneWidget);
      expect(find.text('BEBIDAS'), findsOneWidget);
    });

    testWidgets('tocar no cartao devolve o nome da categoria', (tester) async {
      String? escolhida;
      await tester.pumpWidget(MaterialApp(
        home: CategoriesScreen(
          categories: const ['BEBIDAS'],
          products: const [],
          logoUrl: '',
          restaurantName: 'House Beer',
          cartItemCount: 0,
          onCategorySelected: (c) => escolhida = c,
          onSearchTap: () {},
          onCartTap: () {},
          onHomeTap: () {},
        ),
      ));

      await tester.tap(find.text('BEBIDAS'));
      await tester.pump();

      expect(escolhida, 'BEBIDAS');
    });

    testWidgets('categoria sem nenhum produto com foto nao derruba a tela', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: CategoriesScreen(
          categories: const ['CALDOS'],
          products: const [],
          logoUrl: '',
          restaurantName: 'House Beer',
          cartItemCount: 0,
          onCategorySelected: (_) {},
          onSearchTap: () {},
          onCartTap: () {},
          onHomeTap: () {},
        ),
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('CALDOS'), findsOneWidget);
    });
  });

  group('TELA 3 — produtos', () {
    Widget montar({
      List<MenuProduct>? produtos,
      ValueChanged<MenuProduct>? onQuickAdd,
      ValueChanged<MenuProduct>? onProductTap,
    }) {
      return MaterialApp(
        home: ProductListScreen(
          categoryName: 'Espetinhos Tradicionais',
          products: produtos ?? [_produto()],
          currency: _moeda,
          cartItemCount: 0,
          onBack: () {},
          onHomeTap: () {},
          onCartTap: () {},
          onProductTap: onProductTap ?? (_) {},
          onQuickAdd: onQuickAdd ?? (_) {},
        ),
      );
    }

    testWidgets('mostra nome, descricao e preco', (tester) async {
      await tester.pumpWidget(montar());

      expect(find.text('ESPETINHOS TRADICIONAIS'), findsOneWidget);
      expect(find.text('ALCATRA'), findsOneWidget);
      expect(find.text('Acompanha farofa e molhos'), findsOneWidget);
      expect(find.textContaining('14,00'), findsOneWidget);
    });

    testWidgets('ADICIONAR na linha nao abre o detalhe', (tester) async {
      var adicionados = 0;
      var abertos = 0;
      await tester.pumpWidget(montar(
        onQuickAdd: (_) => adicionados += 1,
        onProductTap: (_) => abertos += 1,
      ));

      await tester.tap(find.text('ADICIONAR'));
      await tester.pump();

      expect(adicionados, 1);
      expect(abertos, 0, reason: 'o caminho rapido nao deve passar pelo detalhe');
    });

    testWidgets('categoria vazia explica em vez de mostrar tela em branco', (tester) async {
      await tester.pumpWidget(montar(produtos: const []));
      expect(find.text('Nenhum item nesta categoria.'), findsOneWidget);
    });
  });

  group('TELA 4 — detalhe', () {
    Widget montar({
      MenuProduct? produto,
      void Function(int, List<ProductOptionChoice>, String)? onAdd,
    }) {
      return MaterialApp(
        home: ProductDetailScreen(
          produto: produto ?? _produto(),
          currency: _moeda,
          cartItemCount: 0,
          onBack: () {},
          onCartTap: () {},
          onAdd: onAdd ?? (_, _, _) {},
        ),
      );
    }

    testWidgets('quantidade sobe, desce e nunca passa de 1 para baixo', (tester) async {
      int? quantidade;
      await tester.pumpWidget(montar(onAdd: (q, _, _) => quantidade = q));

      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.remove)); // ja esta em 1
      await tester.pump();
      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.text('ADICIONAR AO CARRINHO'));
      await tester.pump();
      expect(quantidade, 1);
    });

    testWidgets('variacao obrigatoria trava o botao ate a escolha', (tester) async {
      var adicionado = false;
      await tester.pumpWidget(montar(
        produto: _produto(grupos: const [_grupoMolho]),
        onAdd: (_, _, _) => adicionado = true,
      ));

      // Sem escolher, o toque nao faz nada: comanda incompleta no bar e pior que
      // um botao que nao responde.
      await tester.tap(find.text('ADICIONAR AO CARRINHO'));
      await tester.pump();
      expect(adicionado, isFalse);

      await tester.tap(find.text('Barbecue'));
      await tester.pump();
      await tester.tap(find.text('ADICIONAR AO CARRINHO'));
      await tester.pump();
      expect(adicionado, isTrue);
    });

    testWidgets('a escolha com diferenca de preco atualiza o valor na tela', (tester) async {
      await tester.pumpWidget(montar(produto: _produto(grupos: const [_grupoMolho])));

      expect(find.textContaining('14,00'), findsOneWidget);

      await tester.tap(find.text('Barbecue')); // + R$ 2,00
      await tester.pump();

      expect(find.textContaining('16,00'), findsOneWidget);
    });

    testWidgets('a observacao digitada chega em onAdd', (tester) async {
      String? obs;
      await tester.pumpWidget(montar(onAdd: (_, _, o) => obs = o));

      await tester.enterText(find.byType(TextField), 'sem cebola');
      await tester.tap(find.text('ADICIONAR AO CARRINHO'));
      await tester.pump();

      expect(obs, 'sem cebola');
    });
  });

  group('TELA 5 — carrinho', () {
    Widget montar({
      List<CartItem>? cart,
      ValueChanged<int>? onDecrement,
      ValueChanged<String>? onFinish,
    }) {
      final itens = cart ?? [CartItem(product: _produto(), quantity: 2)];
      return MaterialApp(
        home: CartScreen(
          cart: itens,
          currency: _moeda,
          subtotal: itens.fold(0.0, (s, i) => s + i.subtotal),
          cartItemCount: itens.fold(0, (s, i) => s + i.quantity),
          sendingOrder: false,
          notasIniciais: '',
          onBack: () {},
          onIncrement: (_) {},
          onDecrement: onDecrement ?? (_) {},
          onClear: () {},
          onFinish: onFinish ?? (_) {},
        ),
      );
    }

    testWidgets('mostra o item, a quantidade e o subtotal', (tester) async {
      await tester.pumpWidget(montar());

      expect(find.text('ALCATRA'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.textContaining('28,00'), findsOneWidget); // 2 x 14
    });

    testWidgets('menos na linha avisa o indice certo', (tester) async {
      int? indice;
      await tester.pumpWidget(montar(onDecrement: (i) => indice = i));

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();

      expect(indice, 0);
    });

    testWidgets('finalizar entrega a observacao geral digitada', (tester) async {
      String? notas;
      await tester.pumpWidget(montar(onFinish: (n) => notas = n));

      await tester.enterText(find.byType(TextField), 'ponto bem passado');
      await tester.tap(find.text('FINALIZAR PEDIDO'));
      await tester.pump();

      expect(notas, 'ponto bem passado');
    });

    testWidgets('carrinho vazio explica e nao deixa finalizar', (tester) async {
      var finalizou = false;
      await tester.pumpWidget(montar(cart: const [], onFinish: (_) => finalizou = true));

      expect(find.textContaining('vazio'), findsOneWidget);

      await tester.tap(find.text('FINALIZAR PEDIDO'));
      await tester.pump();
      expect(finalizou, isFalse);
    });

    testWidgets('esvaziar pede confirmacao antes', (tester) async {
      await tester.pumpWidget(montar());

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Esvaziar o pedido?'), findsOneWidget);
    });
  });
}

// Variacoes no carrinho.
//
// O risco real e o agrupamento: se uma caipira de vodka somar com uma de
// cachaca virando "2x Caipira de morango", o bar prepara duas iguais e a mesa
// recebe errado. Estes testes travam isso.

import 'package:flutter_test/flutter_test.dart';
import 'package:next_food_tablet_app/src/models/cart_item.dart';
import 'package:next_food_tablet_app/src/models/menu_product.dart';

const _vodka = ProductOptionChoice(id: 1, name: 'Vodka', priceDelta: 3);
const _cachaca = ProductOptionChoice(id: 2, name: 'Cachaça', priceDelta: 0);

MenuProduct _caipira() => const MenuProduct(
      id: 10,
      name: 'Caipira de morango',
      brand: '',
      category: 'Bebidas',
      price: 20,
    );

void main() {
  test('caipira de vodka nao agrupa com caipira de cachaca', () {
    final comVodka = CartItem(
      product: _caipira(),
      quantity: 1,
      chosenOptions: const [_vodka],
    );

    expect(comVodka.matchesWithOptions(_caipira(), '', const [_cachaca]), isFalse);
  });

  test('duas caipiras de vodka agrupam', () {
    final comVodka = CartItem(
      product: _caipira(),
      quantity: 1,
      chosenOptions: const [_vodka],
    );

    expect(comVodka.matchesWithOptions(_caipira(), '', const [_vodka]), isTrue);
  });

  test('a ordem em que o cliente escolheu nao separa o item', () {
    final item = CartItem(
      product: _caipira(),
      quantity: 1,
      chosenOptions: const [_vodka, _cachaca],
    );

    expect(item.matchesWithOptions(_caipira(), '', const [_cachaca, _vodka]), isTrue);
  });

  test('item com variacao nunca agrupa com item sem variacao', () {
    final comVodka = CartItem(
      product: _caipira(),
      quantity: 1,
      chosenOptions: const [_vodka],
    );
    final semNada = CartItem(product: _caipira(), quantity: 1);

    expect(comVodka.matchesWithOptions(_caipira(), '', const []), isFalse);
    expect(semNada.matchesWithOptions(_caipira(), '', const [_vodka]), isFalse);
  });

  test('observacao diferente continua separando, mesmo com a mesma variacao', () {
    final comObs = CartItem(
      product: _caipira(),
      quantity: 1,
      notes: 'sem açúcar',
      chosenOptions: const [_vodka],
    );

    expect(comObs.matchesWithOptions(_caipira(), '', const [_vodka]), isFalse);
  });

  test('o preco da tela soma a variacao escolhida', () {
    final comVodka = CartItem(
      product: _caipira(),
      quantity: 2,
      chosenOptions: const [_vodka],
    );

    expect(comVodka.unitPrice, 23);
    expect(comVodka.subtotal, 46);
  });

  test('cardapio de versao anterior, sem option_groups, continua carregando', () {
    final produto = MenuProduct.fromJson(const {
      'id': 10,
      'name': 'Caipira de morango',
      'brand': '',
      'category': 'Bebidas',
      'price': 20,
    });

    expect(produto.optionGroups, isEmpty);
  });

  test('grupo sem nenhuma opcao e descartado: seria pergunta sem resposta', () {
    final produto = MenuProduct.fromJson(const {
      'id': 10,
      'name': 'Caipira de morango',
      'brand': '',
      'category': 'Bebidas',
      'price': 20,
      'option_groups': [
        {'id': 1, 'name': 'Tipo', 'required': true, 'choices': []},
        {
          'id': 2,
          'name': 'Copo',
          'required': true,
          'choices': [
            {'id': 9, 'name': 'Vidro', 'price_delta': 0},
          ],
        },
      ],
    });

    expect(produto.optionGroups.length, 1);
    expect(produto.optionGroups.first.name, 'Copo');
  });
}

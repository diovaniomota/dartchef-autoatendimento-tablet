// O balde "Cardapio" nao vira cartao na tela de escolha.
//
// Produto que ficou sem categoria nenhuma cai, no servidor, num agrupamento
// chamado "Cardápio". No tablet ele aparecia como mais um cartao ao lado de
// CALDOS e CERVEJAS — sem foto e sem sentido para quem esta na mesa: os outros
// nomes dizem o que vem, esse nao diz nada.
//
// O que precisa ficar travado: o balde sai da lista independente de acento ou
// caixa (o nome chega do banco, e cadastro nao e uniforme), e as categorias de
// verdade continuam na ordem em que o servidor mandou.

import 'package:flutter_test/flutter_test.dart';
import 'package:next_food_tablet_app/src/models/table_menu.dart';

TableMenu _menu(List<String> categorias) => TableMenu.fromJson(<String, dynamic>{
      'organization': <String, dynamic>{'id': 'org-1', 'nome_fantasia': 'House Beer'},
      'table': <String, dynamic>{'code': '01', 'name': 'Mesa 01'},
      'categories': categorias,
      'subcategories': <String, dynamic>{},
      'products': <dynamic>[],
    });

void main() {
  test('o balde sem categoria fica de fora da lista', () {
    final menu = _menu(['Caldos', 'Cardápio', 'Cervejas']);
    expect(menu.categories, ['Caldos', 'Cervejas']);
  });

  test('acento e caixa nao deixam o balde escapar do filtro', () {
    // O nome vem do banco: "Cardapio", "CARDÁPIO" e " Cardápio " sao o mesmo
    // agrupamento, e um deles passando ja recolocaria o cartao na tela.
    final menu = _menu(['Cardapio', 'CARDÁPIO', ' Cardápio ', 'Caldos']);
    expect(menu.categories, ['Caldos']);
  });

  test('categoria de verdade com nome parecido continua aparecendo', () {
    // Filtrar por "contem cardapio" tiraria estas do ar. So o nome exato sai.
    final menu = _menu(['Cardápio Infantil', 'Cardápio do Dia']);
    expect(menu.categories, ['Cardápio Infantil', 'Cardápio do Dia']);
  });
}

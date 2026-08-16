// Tela de inicio montada pelo restaurante no DartChef.
//
// Ate aqui a tela de espera era fixa no app: cada "queria a logo maior" virava
// versao nova do aplicativo. Agora ela chega do servidor como blocos
// empilhados.
//
// O que precisa ficar travado: cardapio sem layout continua com a tela de
// sempre (ninguem pode ficar com tela em branco por causa de cadastro), bloco
// de um tipo que este app nao conhece nao derruba a tela, e o texto do bloco
// segue o idioma escolhido como o resto do cardapio.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_food_tablet_app/src/core/app_language.dart';
import 'package:next_food_tablet_app/src/models/home_block.dart';
import 'package:next_food_tablet_app/src/models/table_menu.dart';
import 'package:next_food_tablet_app/src/screens/welcome_screen.dart';

Future<void> _abrir(WidgetTester tester, List<HomeBlock> blocos) async {
  await tester.pumpWidget(MaterialApp(
    home: WelcomeScreen(
      restaurantName: 'House Beer',
      logoUrl: '',
      backgroundUrl: '',
      primaryColor: '#ea580c',
      blocks: blocos,
      onStart: () {},
      onSettings: () {},
    ),
  ));
  await tester.pump();
}

HomeBlock _b(String type, [Map<String, dynamic> props = const {}]) =>
    HomeBlock(type: type, props: props);

void main() {
  setUp(resetLanguage);
  tearDown(resetLanguage);

  group('leitura do que vem do servidor', () {
    test('cardapio sem o campo devolve lista vazia, e a tela cai no padrao', () {
      // Servidor em versao anterior, ou restaurante que nunca abriu o editor.
      final menu = TableMenu.fromJson(<String, dynamic>{
        'organization': <String, dynamic>{'id': 'o1', 'nome_fantasia': 'House Beer'},
        'table': <String, dynamic>{'code': '01', 'name': 'Mesa 01'},
        'categories': <String>[],
        'subcategories': <String, dynamic>{},
        'products': <dynamic>[],
      });
      expect(menu.homeBlocks, isEmpty);
    });

    test('le x y w h para desenhar no ponto em que foi solto', () {
      final bloco = HomeBlock.fromJson({
        'type': 'texto',
        'x': 40,
        'y': 80,
        'w': 300,
        'h': 48,
        'props': {'texto': 'Oi'},
      });
      expect(bloco.temPosicao, isTrue);
      expect(bloco.x, 40);
      expect(bloco.y, 80);
      expect(bloco.w, 300);
      expect(bloco.h, 48);
    });

    test('texto com acao iniciar abre o cardapio, botao antigo tambem', () {
      expect(_b('texto', {'acao': 'iniciar'}).iniciaPedido, isTrue);
      expect(_b('texto', {'acao': 'nenhuma'}).iniciaPedido, isFalse);
      expect(_b('botao').iniciaPedido, isTrue);
      expect(_b('botao', {'acao': 'nenhuma'}).iniciaPedido, isFalse);
    });

    test('capa antiga continua com veu; escurecer false desliga', () {
      expect(_b('painel').desligaVeu, isFalse);
      expect(_b('painel', {'escurecer': true}).desligaVeu, isFalse);
      expect(_b('painel', {'escurecer': false}).desligaVeu, isTrue);
    });

    test('painel e linha sao widgets conhecidos, nao somem da tela', () {
      final blocos = HomeBlock.listaFromJson([
        {'type': 'painel', 'props': {'cor': '#112233'}},
        {'type': 'linha', 'props': {}},
      ]);
      expect(blocos.map((b) => b.type), ['painel', 'linha']);
    });

    test('widgets novos continuam conhecidos', () {
      final blocos = HomeBlock.listaFromJson([
        {'type': 'relogio', 'props': {}},
        {'type': 'promo', 'props': {'texto': 'Combo'}},
        {'type': 'qr', 'props': {}},
        {'type': 'wifi', 'props': {'rede': 'Casa'}},
      ]);
      expect(blocos.map((b) => b.type), ['relogio', 'promo', 'qr', 'wifi']);
    });

    test('bloco de tipo desconhecido e descartado, e o resto continua', () {
      // Layout gravado por uma versao mais nova do DartChef nao pode deixar a
      // mesa sem tela.
      final blocos = HomeBlock.listaFromJson([
        {'type': 'video', 'props': {}},
        {'type': 'texto', 'props': {'texto': 'Oi'}},
      ]);
      expect(blocos.map((b) => b.type), ['texto']);
    });

    test('lixo no lugar da lista nao quebra', () {
      expect(HomeBlock.listaFromJson('nada'), isEmpty);
      expect(HomeBlock.listaFromJson(null), isEmpty);
    });

    test('cor invalida cai no branco, que e legivel sobre o fundo escuro', () {
      expect(_b('texto', {'cor': 'vermelho'}).corTexto, 0xFFFFFFFF);
      expect(_b('texto', {'cor': '#FF0000'}).corTexto, 0xFFFF0000);
    });
  });

  group('texto do bloco segue o idioma', () {
    test('em ingles usa a traducao cadastrada', () {
      appLanguage.value = AppLanguage.en;
      expect(_b('texto', {'texto': 'Bem-vindo', 'texto_en': 'Welcome'}).texto, 'Welcome');
    });

    test('sem traducao cai no portugues, e nao em branco', () {
      appLanguage.value = AppLanguage.es;
      expect(_b('texto', {'texto': 'Bem-vindo', 'texto_en': 'Welcome'}).texto, 'Bem-vindo');
    });

    test('traducao so com espaco conta como nao cadastrada', () {
      appLanguage.value = AppLanguage.en;
      expect(_b('texto', {'texto': 'Bem-vindo', 'texto_en': '  '}).texto, 'Bem-vindo');
    });
  });

  group('tela desenhada', () {
    testWidgets('sem blocos, mostra a tela de sempre', (tester) async {
      await _abrir(tester, const []);
      expect(find.text('HOUSE BEER'), findsOneWidget);
      // As tres opcoes de idioma continuam la. Maiusculas: o botao mostra o
      // nome no proprio idioma, em caixa alta.
      expect(find.text('PORTUGUÊS'), findsOneWidget);
    });

    testWidgets('com blocos, desenha o texto que o restaurante escreveu', (tester) async {
      await _abrir(tester, [
        _b('texto', {'texto': 'PROMOÇÃO DE TERÇA'}),
        _b('idiomas'),
        _b('botao', {'texto': 'PEÇA AQUI'}),
      ]);
      expect(find.text('PROMOÇÃO DE TERÇA'), findsOneWidget);
    });

    testWidgets('o texto do botao vem do bloco', (tester) async {
      await _abrir(tester, [
        _b('texto', {'texto': 'Oi'}),
        _b('idiomas'),
        _b('botao', {'texto': 'PEÇA AQUI'}),
      ]);
      expect(find.text('PEÇA AQUI'), findsOneWidget);
    });

    testWidgets('botao sem texto cadastrado cai no rotulo do app', (tester) async {
      await _abrir(tester, [
        _b('texto', {'texto': 'Oi'}),
        _b('idiomas'),
        _b('botao', {'texto': '   '}),
      ]);
      // Botao sem palavra nenhuma seria pior que o rotulo padrao.
      expect(find.text('TOQUE PARA COMEÇAR'), findsOneWidget);
    });

    testWidgets('a escolha de idioma aparece quando o bloco esta no layout', (tester) async {
      await _abrir(tester, [_b('idiomas'), _b('botao')]);
      expect(find.text('PORTUGUÊS'), findsOneWidget);
      expect(find.text('ENGLISH'), findsOneWidget);
      expect(find.text('ESPAÑOL'), findsOneWidget);
    });

    testWidgets('so o marcador da capa nao recoloca logo nem botao padrao', (tester) async {
      await _abrir(tester, [
        const HomeBlock(
          type: 'painel',
          x: 0,
          y: 0,
          w: 1024,
          h: 600,
          props: {'capa': true, 'opacidade': 0, 'escurecer': false},
        ),
      ]);
      expect(find.text('TOQUE PARA COMEÇAR'), findsNothing);
      expect(find.text('HOUSE BEER'), findsNothing);
    });

    testWidgets('sem o campo, o veu preto da capa continua', (tester) async {
      await _abrir(tester, const []);
      expect(find.byKey(const Key('veu-capa')), findsOneWidget);
    });

    testWidgets('escurecer false tira o veu preto da capa', (tester) async {
      await _abrir(tester, [
        const HomeBlock(
          type: 'painel',
          x: 0,
          y: 0,
          w: 1024,
          h: 600,
          props: {'escurecer': false},
        ),
      ]);
      expect(find.byKey(const Key('veu-capa')), findsNothing);
    });

    testWidgets('imagem quebrada nao deixa quadrado de erro na vitrine', (tester) async {
      await _abrir(tester, [
        _b('imagem', {'url': 'http://127.0.0.1:9/nao-existe.png'}),
        _b('idiomas'),
        _b('botao'),
      ]);
      await tester.pump(const Duration(milliseconds: 100));
      // A tela continua de pe e o botao segue alcancavel.
      expect(find.text('TOQUE PARA COMEÇAR'), findsOneWidget);
    });

    testWidgets('widget com x/y aparece no ponto, nao empilhado', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _abrir(tester, [
        HomeBlock(
          type: 'texto',
          x: 80,
          y: 40,
          w: 360,
          h: 48,
          props: const {'texto': 'CANTO SUPERIOR'},
        ),
        const HomeBlock(type: 'idiomas', x: 50, y: 200, w: 400, h: 200),
        HomeBlock(
          type: 'botao',
          x: 300,
          y: 480,
          w: 380,
          h: 76,
          props: const {'texto': 'PEÇA AQUI'},
        ),
      ]);

      expect(find.text('CANTO SUPERIOR'), findsOneWidget);
      expect(find.text('PEÇA AQUI'), findsOneWidget);
      expect(tester.getTopLeft(find.text('CANTO SUPERIOR')).dy, lessThan(120));
    });

    testWidgets('layout alto nao derruba a tela: ela rola', (tester) async {
      // 600px de altura no aparelho da cliente acabam rapido. Estourar tem de
      // virar rolagem, nao excecao de layout.
      await _abrir(tester, [
        for (var i = 0; i < 8; i++) _b('texto', {'texto': 'Linha $i', 'tamanho': 'titulo'}),
        _b('idiomas'),
        _b('botao'),
      ]);
      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });
  });
}

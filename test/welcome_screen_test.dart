// Tela de espera: renderiza e responde ao toque.
//
// Interessa aqui o que quebraria a mesa na pratica: logo cadastrada que nao
// carrega deixando a tela sem identificacao, e o botao de comecar nao chamando
// nada.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_food_tablet_app/src/core/app_language.dart';
import 'package:next_food_tablet_app/src/screens/welcome_screen.dart';
import 'package:next_food_tablet_app/src/widgets/flag_icon.dart';

Widget _montar({
  String logoUrl = '',
  String backgroundUrl = '',
  String primaryColor = '',
  VoidCallback? onStart,
}) {
  return MaterialApp(
    home: WelcomeScreen(
      restaurantName: 'House Beer Conveniencia',
      logoUrl: logoUrl,
      backgroundUrl: backgroundUrl,
      primaryColor: primaryColor,
      onStart: onStart ?? () {},
    ),
  );
}

void main() {
  setUp(resetLanguage);

  testWidgets('sem logo cadastrada, o nome do restaurante ocupa o lugar', (tester) async {
    await tester.pumpWidget(_montar());

    expect(find.text('HOUSE BEER CONVENIENCIA'), findsOneWidget);
    expect(find.text('TOQUE PARA COMEÇAR'), findsOneWidget);
    expect(find.text('FAÇA SEU PEDIDO'), findsOneWidget);
  });

  testWidgets('a bandeira de cada idioma e desenhada', (tester) async {
    await tester.pumpWidget(_montar());

    // Uma FlagIcon por opcao. Sem isto a linha do idioma vira so texto, e foi
    // exatamente o que a cliente viu na Espanha.
    expect(find.byType(FlagIcon), findsNWidgets(AppLanguage.values.length));
  });

  testWidgets('a bandeira da Espanha tem o vermelho, o amarelo e o brasao', (tester) async {
    await tester.pumpWidget(_montar());

    final espanha = find.descendant(
      of: find.byWidgetPredicate(
        (w) => w is FlagIcon && w.language == AppLanguage.es,
      ),
      matching: find.byType(ColoredBox),
    );

    final cores = tester
        .widgetList<ColoredBox>(espanha)
        .map((box) => box.color)
        .toSet();

    expect(cores, contains(const Color(0xFFAA151B))); // faixas vermelhas
    expect(cores, contains(const Color(0xFFF1BF00))); // faixa amarela
    // Vermelho-amarelo-vermelho puro se confunde com outras bandeiras; os
    // pilares em ouro escuro sao o que identifica a Espanha neste tamanho.
    expect(cores, contains(const Color(0xFFC8930A)));
  });

  testWidgets('as tres opcoes de idioma aparecem no proprio idioma', (tester) async {
    await tester.pumpWidget(_montar());

    // "English" traduzido para "Ingles" nao ajudaria quem nao le portugues.
    expect(find.text('PORTUGUÊS'), findsOneWidget);
    expect(find.text('ENGLISH'), findsOneWidget);
    expect(find.text('ESPAÑOL'), findsOneWidget);
  });

  testWidgets('tocar em ENGLISH troca o idioma da propria tela', (tester) async {
    await tester.pumpWidget(_montar());

    await tester.tap(find.text('ENGLISH'));
    await tester.pump();

    expect(appLanguage.value, AppLanguage.en);
    expect(find.text('TOUCH TO START'), findsOneWidget);
    expect(find.text('PLACE YOUR ORDER'), findsOneWidget);
  });

  testWidgets('o botao de comecar chama onStart', (tester) async {
    var tocado = 0;
    await tester.pumpWidget(_montar(onStart: () => tocado += 1));

    await tester.tap(find.text('TOQUE PARA COMEÇAR'));
    await tester.pump();

    expect(tocado, 1);
  });

  testWidgets('cor invalida no cadastro nao derruba a tela', (tester) async {
    // Campo de cor editavel a mao: '#xyz' precisa cair na cor do app em vez de
    // estourar na conversao.
    await tester.pumpWidget(_montar(primaryColor: '#xyz'));

    expect(tester.takeException(), isNull);
    expect(find.text('TOQUE PARA COMEÇAR'), findsOneWidget);
  });

  testWidgets('logo que nao carrega cai no nome, sem deixar a tela vazia', (tester) async {
    // Em teste toda Image.network falha (sem rede), o que e exatamente o cenario
    // de endereco quebrado no cadastro.
    await tester.pumpWidget(_montar(logoUrl: 'https://exemplo.invalido/logo.png'));
    await tester.pump();

    expect(find.text('HOUSE BEER CONVENIENCIA'), findsOneWidget);
  });
}

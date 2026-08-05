// Acesso as configuracoes e troca de idioma na tela de espera.
//
// Regressao: a engrenagem estava ANTES da area de rolagem no Stack. No Flutter o
// filho declarado depois pinta por cima e fica com o toque, e a rolagem cobre a
// tela inteira — a engrenagem aparecia e nao respondia a nada. Como ela e o
// unico caminho para configurar o tablet, isso deixava o aparelho sem conserto
// pela propria interface.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_food_tablet_app/src/core/app_language.dart';
import 'package:next_food_tablet_app/src/screens/welcome_screen.dart';

Widget _montar({
  bool conectado = true,
  VoidCallback? onSettings,
  VoidCallback? onStart,
}) {
  return MaterialApp(
    home: WelcomeScreen(
      restaurantName: 'House Beer',
      logoUrl: '',
      backgroundUrl: '',
      primaryColor: '',
      conectado: conectado,
      onStart: onStart ?? () {},
      onSettings: onSettings ?? () {},
    ),
  );
}

void main() {
  setUp(resetLanguage);

  testWidgets('a engrenagem recebe o toque, mesmo com a rolagem por cima',
      (tester) async {
    var aberto = 0;
    await tester.pumpWidget(_montar(onSettings: () => aberto += 1));

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump();

    expect(aberto, 1, reason: 'sem isso o tablet fica sem como ser configurado');
  });

  testWidgets('desconectado, oferece CONECTAR em vez do botao de comecar',
      (tester) async {
    var aberto = 0;
    var comecou = 0;
    await tester.pumpWidget(_montar(
      conectado: false,
      onSettings: () => aberto += 1,
      onStart: () => comecou += 1,
    ));

    // Comecar levaria a uma tela de erro: o cliente toca, nada util acontece e
    // ele chama o garcom.
    expect(find.text('TOQUE PARA COMEÇAR'), findsNothing);
    expect(find.text('Tablet não conectado'), findsOneWidget);

    await tester.tap(find.text('CONECTAR TABLET'));
    await tester.pump();

    expect(aberto, 1);
    expect(comecou, 0);
  });

  testWidgets('conectado, mostra o botao de comecar e nao o aviso', (tester) async {
    await tester.pumpWidget(_montar());

    expect(find.text('TOQUE PARA COMEÇAR'), findsOneWidget);
    expect(find.text('Tablet não conectado'), findsNothing);
  });
}

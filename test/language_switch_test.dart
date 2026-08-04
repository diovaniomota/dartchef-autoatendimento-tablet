import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:next_food_tablet_app/src/core/app_language.dart';

/// Regressao do bug relatado pelo cliente: "os idiomas nao funcionaram".
///
/// A causa era `home: const TabletHomeScreen()` na raiz. O ValueListenableBuilder
/// rebuildava o MaterialApp, mas o Flutter tem um atalho em Element.updateChild:
/// quando o widget novo e == ao antigo (instancia const identica), a subarvore
/// NAO e reconstruida. O idioma trocava no notifier e a tela continuava igual.
///
/// Este teste reproduz exatamente esse arranjo, porque nem o flutter analyze nem
/// leitura de codigo pegam esse tipo de falha.
void main() {
  setUp(() => appLanguage.value = AppLanguage.pt);
  tearDown(() => appLanguage.value = AppLanguage.pt);

  testWidgets('trocar o idioma redesenha a tela filha', (tester) async {
    await tester.pumpWidget(
      ValueListenableBuilder<AppLanguage>(
        valueListenable: appLanguage,
        // Filho SEM const: e o que garante o rebuild da subarvore.
        builder: (context, _, _) => MaterialApp(home: _Screen()),
      ),
    );

    expect(find.text('CONFIRMAR PEDIDO'), findsOneWidget);

    appLanguage.value = AppLanguage.en;
    await tester.pumpAndSettle();
    expect(find.text('CONFIRM ORDER'), findsOneWidget,
        reason: 'A tela filha nao foi redesenhada ao trocar para ingles');

    appLanguage.value = AppLanguage.es;
    await tester.pumpAndSettle();
    expect(find.text('CONFIRMAR PEDIDO'), findsOneWidget,
        reason: 'Espanhol usa o mesmo texto do portugues nesta chave');
    expect(find.text('RESUMEN DEL PEDIDO'), findsOneWidget,
        reason: 'A tela filha nao foi redesenhada ao trocar para espanhol');
  });

  testWidgets('const na tela filha impede o rebuild (documenta a causa)', (tester) async {
    await tester.pumpWidget(
      ValueListenableBuilder<AppLanguage>(
        valueListenable: appLanguage,
        // COM const: reproduz o defeito original.
        builder: (context, _, _) => const MaterialApp(home: _Screen()),
      ),
    );

    expect(find.text('CONFIRMAR PEDIDO'), findsOneWidget);

    appLanguage.value = AppLanguage.en;
    await tester.pumpAndSettle();

    // Continua em portugues: e este o comportamento que o cliente viu.
    expect(find.text('CONFIRMAR PEDIDO'), findsOneWidget);
    expect(find.text('CONFIRM ORDER'), findsNothing);
  });

  test('t() cai no portugues quando a chave falta no idioma', () {
    appLanguage.value = AppLanguage.en;
    expect(t('cart.confirm'), 'CONFIRM ORDER');
    // Chave inexistente devolve a propria chave, sem lancar excecao.
    expect(t('chave.que.nao.existe'), 'chave.que.nao.existe');
  });

  test('t2 substitui os marcadores', () {
    appLanguage.value = AppLanguage.es;
    expect(t2('topbar.table', {'code': '07'}), 'MESA 07');
    expect(t2('confirm.items', {'count': '3'}), 'Artículos del Pedido (3)');
  });

  test('resetLanguage volta para portugues', () {
    appLanguage.value = AppLanguage.en;
    resetLanguage();
    expect(appLanguage.value, AppLanguage.pt);
  });
}

class _Screen extends StatelessWidget {
  const _Screen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text(t('cart.confirm')),
          Text(t('cart.summary')),
        ],
      ),
    );
  }
}

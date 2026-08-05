// Presenca do cliente.
//
// Regressao: o toque era registrado por um Listener DENTRO do Scaffold, e
// dialogo e rota separada no Overlay. Quem digitava a senha ou mexia na
// configuracao nao contava como presente; a ociosidade estourava no meio disso,
// encerrava a sessao por baixo da rota aberta e o app quebrava com
// "'_dependents.isEmpty': is not true".
//
// O registro passou para o builder do MaterialApp, acima de TODAS as rotas.
// Estes testes travam as duas metades: o relogio de presenca e o fato de o
// toque dentro de um dialogo chegar ate ele.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_food_tablet_app/src/core/table_session.dart';

void main() {
  test('logo apos um toque ninguem esta ocioso', () {
    userActivity.ping();
    expect(userActivity.isIdle, isFalse);
    expect(userActivity.sinceLastTouch, lessThan(const Duration(seconds: 2)));
  });

  testWidgets('toque DENTRO de um dialogo conta como presenca', (tester) async {
    // Reproduz a montagem real: Listener no builder do MaterialApp, dialogo
    // aberto por cima da tela.
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => userActivity.ping(),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const AlertDialog(
                    content: Text('senha'),
                  ),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('senha'), findsOneWidget);

    // Envelhece o ultimo toque artificialmente e confirma que o toque no
    // dialogo — nao na tela — rejuvenesce.
    userActivity.debugSetLastTouch(DateTime.now().subtract(kIdleLimit * 2));
    expect(userActivity.isIdle, isTrue);

    await tester.tap(find.text('senha'));
    await tester.pump();

    expect(
      userActivity.isIdle,
      isFalse,
      reason: 'toque dentro do dialogo tem de chegar ao Listener do MaterialApp',
    );
  });

  test('sem toque por mais que o limite, esta ocioso', () {
    userActivity.debugSetLastTouch(DateTime.now().subtract(kIdleLimit * 2));
    expect(userActivity.isIdle, isTrue);
    userActivity.ping();
  });
}

// Dialogo do PIN das configuracoes.
//
// Regressao: o TextEditingController era criado na funcao que abre o dialogo e
// descartado logo depois do `await showDialog`. Parecia funcionar, mas quando o
// dialogo era fechado DE FORA — pela ociosidade encerrando a sessao — ele ainda
// estava animando a saida e reconstruia o TextField com o controller ja
// descartado:
//
//   A TextEditingController was used after being disposed.
//
// Agora o controller pertence ao widget e sai no dispose dele. Este teste fecha
// o dialogo por fora, como a ociosidade fazia, e confirma que nada estoura.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Copia do dialogo real. `_PinDialog` e privado da tela, e o que precisa ficar
/// travado aqui e o PADRAO — controller dentro de StatefulWidget —, nao a
/// classe em si.
class PinDialogSpec extends StatefulWidget {
  const PinDialogSpec({super.key});

  @override
  State<PinDialogSpec> createState() => _PinDialogSpecState();
}

class _PinDialogSpecState extends State<PinDialogSpec> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Configurações protegidas'),
        content: TextField(controller: _controller, autofocus: true),
      );
}

void main() {
  testWidgets('fechar o dialogo POR FORA nao usa o controller descartado',
      (tester) async {
    late BuildContext raiz;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            raiz = context;
            return const Scaffold(body: Text('cardapio'));
          },
        ),
      ),
    );

    // ignore: unawaited_futures
    showDialog<bool>(context: raiz, builder: (_) => const PinDialogSpec());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '1707');
    await tester.pump();

    // E aqui que a ociosidade entrava: derruba tudo que esta acima da tela.
    Navigator.of(raiz, rootNavigator: true).popUntil((rota) => rota.isFirst);

    // Avanca a animacao de saida quadro a quadro — e nela que o TextField era
    // reconstruido com o controller descartado.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('cardapio'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });
}

// Regra que encerra a sessao da mesa.
//
// O erro caro aqui nao e deixar o tablet parado no cardapio: e ENCERRAR a
// sessao de quem esta no meio do pedido. Estes testes travam os dois casos em
// que isso aconteceria.

import 'package:flutter_test/flutter_test.dart';
import 'package:next_food_tablet_app/src/core/table_session.dart';

void main() {
  test('mesa paga no PDV encerra a sessao', () {
    // Ja tinha comanda aberta; agora o historico devolve zero.
    expect(
      shouldEndSessionAfterCheck(sawOpenOrder: true, openOrderCount: 0),
      isTrue,
    );
  });

  test('cliente que acabou de sentar e nao pediu nada NAO e expulso', () {
    // Zero comandas, mas nenhuma foi vista antes: e alguem escolhendo.
    expect(
      shouldEndSessionAfterCheck(sawOpenOrder: false, openOrderCount: 0),
      isFalse,
    );
  });

  test('com comanda aberta na tela a sessao continua', () {
    expect(
      shouldEndSessionAfterCheck(sawOpenOrder: true, openOrderCount: 2),
      isFalse,
    );
  });

  test('primeira consulta que ve comanda nao encerra nada', () {
    expect(
      shouldEndSessionAfterCheck(sawOpenOrder: false, openOrderCount: 1),
      isFalse,
    );
  });

  test('o aviso de ociosidade da tempo de responder antes de encerrar', () {
    // Se cair para zero, o cliente perde a tela sem chance de reagir.
    expect(kIdleWarningSeconds, greaterThanOrEqualTo(5));
  });

  test('o limite de ociosidade nao e curto o bastante para atrapalhar a leitura', () {
    // Ler o cardapio nao gera toque. Menos de 2 minutos interromperia quem
    // simplesmente esta decidindo.
    expect(kIdleLimit, greaterThanOrEqualTo(const Duration(minutes: 2)));
  });

  test('a consulta de fechamento nao martela o servidor', () {
    expect(kTableWatchInterval, greaterThanOrEqualTo(const Duration(seconds: 10)));
  });
}

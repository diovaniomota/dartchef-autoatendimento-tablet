// Regras da sessao da mesa.
//
// Ficam separadas da tela porque sao o que decide se o cliente e ou nao tirado
// do cardapio no meio do pedido — a parte que precisa de teste.

/// Sem toque por este tempo, o tablet pergunta se ainda tem alguem na mesa.
const Duration kIdleLimit = Duration(minutes: 3);

/// Quanto tempo o aviso de ociosidade espera resposta antes de encerrar.
const int kIdleWarningSeconds = 10;

/// De quanto em quanto tempo o tablet verifica se a mesa foi fechada.
///
/// 20s basta: quando o caixa fecha a conta o cliente ja levantou, ninguem esta
/// olhando a tela esperando ela mudar.
const Duration kTableWatchInterval = Duration(seconds: 20);

/// Decide se a sessao termina, a partir do que a consulta de comandas devolveu.
///
/// O endereco de historico devolve SO comanda aberta. Logo "ja vi comanda
/// aberta e agora nao vejo nenhuma" e a evidencia de que a mesa foi paga ou
/// cancelada no PDV — sem precisar de rota nova no servidor.
///
/// [sawOpenOrder] tem de vir da CONSULTA, nunca do retorno do envio do pedido:
/// confiar no POST abriria uma janela em que a consulta roda antes de a linha
/// aparecer, ve zero e derrubaria a sessao de quem acabou de pedir.
///
/// Zero comandas sem nunca ter visto uma significa cliente que acabou de sentar
/// e ainda nao pediu: encerrar ai expulsaria quem esta escolhendo.
bool shouldEndSessionAfterCheck({
  required bool sawOpenOrder,
  required int openOrderCount,
}) {
  return sawOpenOrder && openOrderCount == 0;
}

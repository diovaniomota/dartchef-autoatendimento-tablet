import 'package:flutter/material.dart';

import '../core/app_language.dart';
import '../core/app_theme.dart';
import 'flag_icon.dart';

/// Cabecalho e rodape comuns as telas de pedido (categorias, produtos, detalhe,
/// carrinho).
///
/// Ficam num arquivo so porque sao a moldura que o cliente usa para se
/// localizar: se o "VOLTAR" e o "VER CARRINHO" mudarem de lugar ou de tamanho
/// entre telas, ele para para procurar. Copiar em cada tela era garantir que
/// mais cedo ou mais tarde divergiriam.

/// Alvo de toque das telas de pedido. O cliente esta de pe, com o tablet fixo
/// na mesa, e nao mira: 48px e o minimo que se acerta sem tentar duas vezes.
const double kTabletTapTarget = 48;

class TabletTopBar extends StatelessWidget {
  const TabletTopBar({
    super.key,
    required this.titulo,
    required this.cartItemCount,
    required this.onCartTap,
    this.onBack,
    this.logoUrl = '',
    this.onSearchTap,
  });

  final String titulo;
  final int cartItemCount;
  final VoidCallback onCartTap;

  /// Ausente na primeira tela do fluxo, onde nao ha para onde voltar.
  final VoidCallback? onBack;

  /// Quando informado, a logo substitui o titulo (usado na tela de categorias).
  final String logoUrl;
  final VoidCallback? onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          if (onBack != null)
            TabletBarButton(
              icone: Icons.arrow_back,
              texto: t('nav.back'),
              onTap: onBack!,
            )
          else if (logoUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Image.network(
                logoUrl,
                height: 40,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => _titulo(alinhado: true),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _titulo(alinhado: true),
            ),

          // O titulo centralizado tem de sobrar do meio para fora sem empurrar
          // os botoes: Expanded + ellipsis, nunca largura fixa.
          Expanded(
            child: (onBack != null)
                ? Center(child: _titulo())
                : const SizedBox.shrink(),
          ),

          // Troca de idioma em TODAS as telas do pedido, nao so na de espera.
          //
          // Quem tocou em Espanhol sem querer ficava preso: a partir dali o app
          // inteiro estava em outro idioma e nao havia como voltar sem encerrar
          // a mesa. A bandeira atual serve de rotulo — nao precisa saber ler o
          // idioma da tela para achar o botao.
          const LanguageButton(),

          // "Meus pedidos", nao "buscar": este botao sempre abriu a lista do que
          // a mesa ja pediu, e o rotulo de lupa mentia sobre o que ele faz.
          if (onSearchTap != null)
            TabletBarButton(
              icone: Icons.receipt_long_outlined,
              texto: t('nav.myOrders'),
              onTap: onSearchTap!,
            ),
          TabletBarButton(
            icone: Icons.shopping_cart_outlined,
            texto: t('nav.cart'),
            contador: cartItemCount,
            // Sempre visivel, igual ao do rodape: sao o mesmo contador em dois
            // lugares, e um aparecendo com zero e o outro nao confundiria.
            contadorSempre: true,
            onTap: onCartTap,
          ),
        ],
      ),
    );
  }

  Widget _titulo({bool alinhado = false}) => Text(
        titulo,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: alinhado ? TextAlign.left : TextAlign.center,
        style: TextStyle(
          color: alinhado ? Colors.white : AppTheme.accent,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      );
}

class TabletBottomBar extends StatelessWidget {
  const TabletBottomBar({
    super.key,
    required this.cartItemCount,
    required this.onHomeTap,
    required this.onCartTap,
    this.onCallWaiter,
    this.onRequestBill,
  });

  final int cartItemCount;
  final VoidCallback onHomeTap;
  final VoidCallback onCartTap;

  /// Chamar garcom e pedir a conta.
  ///
  /// Ficam no rodape porque sao o socorro do cliente: precisam estar visiveis
  /// em qualquer ponto do cardapio, sem ele ter de procurar. Sairam junto com o
  /// layout antigo e voltaram aqui — o tablet existe justamente para a mesa nao
  /// precisar acenar para ninguem.
  final VoidCallback? onCallWaiter;
  final VoidCallback? onRequestBill;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        // Fio laranja no alto, como na referencia: separa a barra do conteudo
        // sem precisar de sombra, que num fundo preto nao aparece.
        border: Border(top: BorderSide(color: AppTheme.accent, width: 1.5)),
      ),
      child: Row(
        children: [
          TabletBarButton(
            icone: Icons.home_outlined,
            texto: t('nav.home'),
            onTap: onHomeTap,
          ),
          if (onCallWaiter != null)
            TabletBarButton(
              icone: Icons.room_service_outlined,
              texto: t('topbar.waiter'),
              onTap: onCallWaiter!,
            ),
          if (onRequestBill != null)
            TabletBarButton(
              icone: Icons.receipt_long_outlined,
              texto: t('topbar.requestBill'),
              onTap: onRequestBill!,
            ),
          const Spacer(),
          SizedBox(
            height: 52,
            // Vazado, e nao laranja solido.
            //
            // A barra ja tem o fio laranja e o contador laranja; um botao
            // inteiro preenchido puxava toda a atencao para baixo, competindo
            // com a foto dos produtos, que e o que deve vender. O contorno
            // mantem o destaque sem gritar.
            child: OutlinedButton.icon(
              onPressed: onCartTap,
              style: OutlinedButton.styleFrom(
                backgroundColor: AppTheme.surface,
                side: const BorderSide(color: AppTheme.accent, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.shopping_cart, size: 20, color: AppTheme.accent),
              label: Row(
                children: [
                  Text(
                    t('nav.seeCart'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Sempre visivel, mesmo zerado: o cliente aprende onde fica a
                  // conta de itens antes de ter o primeiro. Escondendo, o numero
                  // aparecia do nada e ele nao sabia de onde veio.
                  _Contador(valor: cartItemCount, cor: AppTheme.accent, sempreVisivel: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TabletBarButton extends StatelessWidget {
  const TabletBarButton({
    super.key,
    required this.icone,
    required this.texto,
    required this.onTap,
    this.contador = 0,
    this.contadorSempre = false,
  });

  final IconData icone;
  final String texto;
  final VoidCallback onTap;
  final int contador;
  final bool contadorSempre;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minHeight: kTabletTapTarget),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Icon(icone, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Text(
                texto,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              if (contador > 0 || contadorSempre) ...[
                const SizedBox(width: 6),
                _Contador(valor: contador, cor: AppTheme.accent, sempreVisivel: contadorSempre),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Contador extends StatelessWidget {
  const _Contador({
    required this.valor,
    required this.cor,
    this.sempreVisivel = false,
  });

  final int valor;
  final Color cor;

  /// Mostra o circulo mesmo com zero. Vale no botao grande do rodape, onde o
  /// contador e referencia fixa; nos botoes pequenos do topo um zero constante
  /// so ocuparia espaco.
  final bool sempreVisivel;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
      child: Text(
        '$valor',
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
      ),
    );
  }
}

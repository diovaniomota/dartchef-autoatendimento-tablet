import 'package:flutter/material.dart';

import '../core/app_language.dart';
import '../core/app_theme.dart';

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

          if (onSearchTap != null)
            TabletBarButton(
              icone: Icons.search,
              texto: t('nav.search'),
              onTap: onSearchTap!,
            ),
          TabletBarButton(
            icone: Icons.shopping_cart_outlined,
            texto: t('nav.cart'),
            contador: cartItemCount,
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
  });

  final int cartItemCount;
  final VoidCallback onHomeTap;
  final VoidCallback onCartTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          TabletBarButton(
            icone: Icons.home_outlined,
            texto: t('nav.home'),
            onTap: onHomeTap,
          ),
          const Spacer(),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: onCartTap,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accent,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.shopping_cart, size: 20),
              label: Row(
                children: [
                  Text(
                    t('nav.seeCart'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (cartItemCount > 0) ...[
                    const SizedBox(width: 10),
                    _Contador(valor: cartItemCount, cor: Colors.white24),
                  ],
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
  });

  final IconData icone;
  final String texto;
  final VoidCallback onTap;
  final int contador;

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
              if (contador > 0) ...[
                const SizedBox(width: 6),
                _Contador(valor: contador, cor: AppTheme.accent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Contador extends StatelessWidget {
  const _Contador({required this.valor, required this.cor});

  final int valor;
  final Color cor;

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

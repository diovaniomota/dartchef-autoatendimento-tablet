import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_language.dart';
import '../core/app_theme.dart';
import '../models/cart_item.dart';
import '../widgets/tablet_chrome.dart';

/// Revisao do pedido antes de enviar.
///
/// Quantidade editavel na propria linha: quem quer dois espetinhos nao deveria
/// precisar voltar ao cardapio e adicionar de novo. E o subtotal fica visivel
/// junto, porque mexer na quantidade sem ver o valor mudar deixa o cliente
/// desconfiado da conta.
class CartScreen extends StatefulWidget {
  const CartScreen({
    super.key,
    required this.cart,
    required this.currency,
    required this.subtotal,
    required this.cartItemCount,
    required this.sendingOrder,
    required this.notasIniciais,
    required this.onBack,
    required this.onIncrement,
    required this.onDecrement,
    required this.onClear,
    required this.onFinish,
  });

  final List<CartItem> cart;
  final NumberFormat currency;
  final double subtotal;
  final int cartItemCount;
  final bool sendingOrder;
  final String notasIniciais;
  final VoidCallback onBack;
  final ValueChanged<int> onIncrement;
  final ValueChanged<int> onDecrement;
  final VoidCallback onClear;

  /// Entrega a observacao geral do pedido junto, para nao depender de o
  /// controller viver fora desta tela.
  final ValueChanged<String> onFinish;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final TextEditingController _notas =
      TextEditingController(text: widget.notasIniciais);

  @override
  void dispose() {
    _notas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, _, _) => Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Column(
            children: [
              _cabecalho(),
              Expanded(
                child: widget.cart.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            t('cart.empty'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 16),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: widget.cart.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => _LinhaCarrinho(
                          item: widget.cart[i],
                          currency: widget.currency,
                          onIncrement: () => widget.onIncrement(i),
                          onDecrement: () => widget.onDecrement(i),
                        ),
                      ),
              ),
              _rodape(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cabecalho() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(bottom: BorderSide(color: AppTheme.border)),
        ),
        child: Row(
          children: [
            TabletBarButton(icone: Icons.arrow_back, texto: t('nav.back'), onTap: widget.onBack),
            Expanded(
              child: Align(
                // Titulo colado no VOLTAR, como na referencia: centralizado ele
                // brigava com a lixeira pelo eixo da tela.
                alignment: Alignment.centerLeft,
                child: Text(
                  t('cart.summary'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
            // Esvaziar so aparece com item dentro: um lixo sempre visivel num
            // carrinho vazio e botao que nao faz nada.
            if (widget.cart.isNotEmpty)
              IconButton(
                onPressed: widget.sendingOrder ? null : _confirmarEsvaziar,
                tooltip: t('cart.clear'),
                iconSize: 24,
                constraints: const BoxConstraints(
                  minWidth: kTabletTapTarget,
                  minHeight: kTabletTapTarget,
                ),
                icon: const Icon(Icons.delete_outline, color: AppTheme.textMuted),
              )
            else
              const SizedBox(width: kTabletTapTarget),
          ],
        ),
      );

  Future<void> _confirmarEsvaziar() async {
    // Confirmacao porque o toque e irreversivel e fica ao lado do titulo, onde
    // o dedo passa ao ler.
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          t('cart.clearTitle'),
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
        ),
        content: Text(
          t('cart.clearBody'),
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t('notes.cancel'), style: const TextStyle(color: AppTheme.textMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            child: Text(t('cart.clear')),
          ),
        ],
      ),
    );
    if (ok == true) widget.onClear();
  }

  Widget _rodape() => Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: Column(
          children: [
            // Subtotal e observacoes no MESMO painel, como na referencia: sao a
            // conferencia final, e separados pareciam dois assuntos.
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
              Row(
                children: [
                  Text(
                    t('cart.subtotal').toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    widget.currency.format(widget.subtotal),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const Divider(color: AppTheme.border, height: 22),
              TextField(
              controller: _notas,
              maxLength: 240,
              maxLines: 2,
              minLines: 1,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: t('cart.orderNotes'),
                labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                hintText: t('cart.orderNotesHint'),
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                filled: true,
                fillColor: AppTheme.background,
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.accent, width: 2),
                ),
              ),
              ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: SizedBox(
                    height: 58,
                    child: OutlinedButton.icon(
                      onPressed: widget.sendingOrder ? null : widget.onBack,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                      label: Text(
                        t('cart.keepBrowsing'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 6,
                  child: SizedBox(
                    height: 58,
                    child: FilledButton(
                      onPressed: (widget.cart.isEmpty || widget.sendingOrder)
                          ? null
                          : () => widget.onFinish(_notas.text),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        widget.sendingOrder ? t('cart.sending') : t('cart.finish'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _LinhaCarrinho extends StatelessWidget {
  const _LinhaCarrinho({
    required this.item,
    required this.currency,
    required this.onIncrement,
    required this.onDecrement,
  });

  final CartItem item;
  final NumberFormat currency;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final url = item.product.imageUrl ?? '';
    final opcoes = item.optionsLabel;
    final obs = item.notes.trim();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 104,
              height: 84,
              child: url.isEmpty
                  ? const ColoredBox(
                      color: AppTheme.surfaceHigh,
                      child: Center(child: Icon(Icons.restaurant, color: AppTheme.textMuted, size: 20)),
                    )
                  : Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: AppTheme.surfaceHigh,
                        child: Center(child: Icon(Icons.restaurant, color: AppTheme.textMuted, size: 20)),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.product.name.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                // Variacao em tom neutro e observacao destacada: uma o cliente
                // escolheu de uma lista, a outra ele digitou.
                if (opcoes.isNotEmpty)
                  Text(
                    opcoes,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                if (obs.isNotEmpty)
                  Text(
                    obs,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                const SizedBox(height: 2),
                Text(
                  currency.format(item.unitPrice),
                  style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _Passo(icone: Icons.remove, onTap: onDecrement),
          // Numero tambem em caixa, como na referencia: os tres formam um
          // controle so, em vez de dois botoes com um texto solto no meio.
          Container(
            width: 54,
            height: 46,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Text(
              '${item.quantity}',
              style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900),
            ),
          ),
          _Passo(icone: Icons.add, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _Passo extends StatelessWidget {
  const _Passo({required this.icone, required this.onTap});

  final IconData icone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceHigh,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: Icon(icone, color: AppTheme.accent, size: 22),
        ),
      ),
    );
  }
}

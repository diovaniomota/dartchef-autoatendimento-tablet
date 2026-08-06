import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_language.dart';
import '../core/app_theme.dart';
import '../models/cart_item.dart';
import '../widgets/tablet_chrome.dart';

/// Formas de pagamento oferecidas ao cliente.
///
/// E INTENCAO, nao baixa financeira: o atendente ja chega na mesa sabendo como
/// ela pretende pagar. Quem confirma o recebimento continua sendo o PDV.
enum PaymentMethod { caixa, pix, cartao, dinheiro }

/// Confirmacao final: itens, dados e forma de pagamento.
class OrderConfirmScreen extends StatefulWidget {
  const OrderConfirmScreen({
    super.key,
    required this.cart,
    required this.currency,
    required this.subtotal,
    required this.tableCode,
    required this.cartItemCount,
    required this.sendingOrder,
    required this.nomeInicial,
    required this.onBack,
    required this.onSend,
  });

  final List<CartItem> cart;
  final NumberFormat currency;
  final double subtotal;
  final String tableCode;
  final int cartItemCount;
  final bool sendingOrder;
  final String nomeInicial;
  final VoidCallback onBack;

  /// Entrega nome e forma escolhida. A mesa NAO vai aqui: ela vem do
  /// pareamento do tablet, e deixar o cliente digitar abriria a porta para o
  /// pedido cair na mesa do vizinho.
  final void Function(String nome, PaymentMethod? forma) onSend;

  @override
  State<OrderConfirmScreen> createState() => _OrderConfirmScreenState();
}

class _OrderConfirmScreenState extends State<OrderConfirmScreen> {
  late final TextEditingController _nome =
      TextEditingController(text: widget.nomeInicial);
  PaymentMethod? _forma;

  @override
  void dispose() {
    _nome.dispose();
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
              TabletTopBar(
                titulo: t('confirm.heading'),
                cartItemCount: widget.cartItemCount,
                onBack: widget.onBack,
                onCartTap: widget.onBack,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _resumo(),
                      const SizedBox(height: 12),
                      _painel(child: _dadosDoCliente()),
                      const SizedBox(height: 12),
                      _painel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _secao(t('confirm.payment')),
                            const SizedBox(height: 10),
                            _formasDePagamento(),
                          ],
                        ),
                      ),
                    ],
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

  /// Cada bloco num painel proprio, como na referencia: itens, dados e
  /// pagamento sao tres decisoes distintas, e soltos na tela viravam uma coluna
  /// unica sem hierarquia.
  Widget _painel({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: child,
      );

  Widget _secao(String texto) => Text(
        texto,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
        ),
      );

  Widget _resumo() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            for (final item in widget.cart)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    // Foto na conferencia tambem: e a ultima tela antes de a
                    // cozinha receber, e reconhecer pelo prato e mais rapido que
                    // ler o nome do cadastro, que muitas vezes vem com codigo.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 74,
                        height: 56,
                        child: (item.product.imageUrl ?? '').isEmpty
                            ? const ColoredBox(
                                color: AppTheme.surfaceHigh,
                                child: Icon(Icons.restaurant, color: AppTheme.textMuted, size: 18),
                              )
                            : Image.network(
                                item.product.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const ColoredBox(
                                  color: AppTheme.surfaceHigh,
                                  child: Icon(Icons.restaurant, color: AppTheme.textMuted, size: 18),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 42,
                      child: Text(
                        '${item.quantity}x',
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.displayName.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          // Variacao e observacao ficam visiveis na conferencia:
                          // e a ultima chance de o cliente notar que escolheu
                          // errado antes de o bar preparar.
                          if (item.optionsLabel.isNotEmpty)
                            Text(
                              item.optionsLabel,
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                            ),
                          if (item.notes.trim().isNotEmpty)
                            Text(
                              item.notes.trim(),
                              style: const TextStyle(color: AppTheme.accent, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      widget.currency.format(item.subtotal),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(color: AppTheme.border, height: 14),
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
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _dadosDoCliente() => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _nome,
              maxLength: 60,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                labelText: t('confirm.name'),
                labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                hintText: t('confirm.nameHint'),
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                filled: true,
                fillColor: AppTheme.surface,
                counterText: '',
                border: _borda(AppTheme.border),
                enabledBorder: _borda(AppTheme.border),
                focusedBorder: _borda(AppTheme.accent, largura: 2),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // A mesa e MOSTRADA, nao digitada: ela vem do pareamento do tablet.
          // Campo editavel abriria a porta para o pedido cair na mesa do
          // vizinho, e o cliente nao tem como saber o codigo certo.
          Expanded(
            flex: 2,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.table_restaurant, color: AppTheme.textMuted, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t2('topbar.table', {'code': widget.tableCode}),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  OutlineInputBorder _borda(Color cor, {double largura = 1}) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: cor, width: largura),
      );

  Widget _formasDePagamento() {
    const dados = {
      PaymentMethod.caixa: (Icons.point_of_sale, 'confirm.payCounter'),
      PaymentMethod.pix: (Icons.qr_code_2, 'confirm.payPix'),
      PaymentMethod.cartao: (Icons.credit_card, 'confirm.payCard'),
      PaymentMethod.dinheiro: (Icons.payments_outlined, 'confirm.payCash'),
    };

    return Row(
      children: [
        for (final forma in PaymentMethod.values) ...[
          Expanded(
            child: _CartaoPagamento(
              icone: dados[forma]!.$1,
              rotulo: t(dados[forma]!.$2),
              marcado: _forma == forma,
              onTap: () => setState(() => _forma = forma),
            ),
          ),
          if (forma != PaymentMethod.values.last) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _rodape() => Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 62,
              child: FilledButton(
                // A forma de pagamento NAO bloqueia o envio: e informacao util
                // para o atendente, nao requisito do pedido. Travar aqui faria
                // a mesa desistir por causa de um campo opcional.
                onPressed: widget.sendingOrder
                    ? null
                    : () => widget.onSend(_nome.text, _forma),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  widget.sendingOrder ? t('cart.sending') : t('confirm.send'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: kTabletTapTarget,
              child: TextButton.icon(
                onPressed: widget.sendingOrder ? null : widget.onBack,
                icon: const Icon(Icons.chevron_left, color: AppTheme.textMuted, size: 20),
                label: Text(
                  t('nav.back'),
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _CartaoPagamento extends StatelessWidget {
  const _CartaoPagamento({
    required this.icone,
    required this.rotulo,
    required this.marcado,
    required this.onTap,
  });

  final IconData icone;
  final String rotulo;
  final bool marcado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: marcado ? AppTheme.accent.withValues(alpha: 0.18) : AppTheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 84,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: marcado ? AppTheme.accent : AppTheme.border,
              width: marcado ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, color: marcado ? AppTheme.accent : Colors.white, size: 26),
              const SizedBox(height: 6),
              Text(
                rotulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: marcado ? AppTheme.accent : Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

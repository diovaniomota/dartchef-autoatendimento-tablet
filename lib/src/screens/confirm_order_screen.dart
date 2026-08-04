import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_language.dart';
import '../core/app_theme.dart';
import '../models/cart_item.dart';

/// Tela de confirmacao do pedido.
///
/// O tablet fica FIXO em uma mesa: a mesa vem da configuracao do aparelho
/// (TabletSettings.tableCode) e nao muda de pedido para pedido. Por isso nao
/// existe mais leitura de QR Code aqui — antes o codigo escaneado substituia
/// a mesa configurada, o que so fazia sentido no cenario de comanda por
/// pessoa, que nao e como o salao opera.
class ConfirmOrderScreen extends StatefulWidget {
  const ConfirmOrderScreen({
    super.key,
    required this.cart,
    required this.tableCode,
    required this.onConfirm,
  });

  final List<CartItem> cart;
  final String tableCode;
  final VoidCallback onConfirm;

  @override
  State<ConfirmOrderScreen> createState() => _ConfirmOrderScreenState();
}

class _ConfirmOrderScreenState extends State<ConfirmOrderScreen> {
  // Trava local de reenvio.
  //
  // Antes a tela era StatelessWidget e recebia um "sending" vindo do pai, mas
  // como ela e empurrada com Navigator.push esse valor era uma FOTOGRAFIA do
  // momento da abertura e nunca era atualizado — ou seja, a guarda nunca
  // bloqueava nada. Com DOIS botoes de confirmar (barra superior e rodape),
  // dois toques rapidos enviavam o pedido DUAS VEZES e davam dois pop(),
  // removendo tambem a tela do cardapio da pilha.
  bool _confirmed = false;

  List<CartItem> get cart => widget.cart;
  String get tableCode => widget.tableCode;

  double get _subtotal => cart.fold(0.0, (s, i) => s + i.subtotal);
  double get _serviceTax => _subtotal * 0.1;
  double get _total => _subtotal + _serviceTax;
  int get _itemCount => cart.fold(0, (s, i) => s + i.quantity);

  static final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

  void _confirm(BuildContext context) {
    if (_confirmed) return;
    setState(() => _confirmed = true);

    // Fecha a tela de confirmacao ANTES de disparar o envio: quem mostra o
    // retorno ("Pedido enviado") e a tela do cardapio.
    Navigator.of(context).pop();
    widget.onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(bottom: BorderSide(color: AppTheme.border)),
                boxShadow: [BoxShadow(color: Color(0x1AFF7E5F), blurRadius: 8, offset: Offset(0, 4))],
              ),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, size: 22, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t('confirm.title'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(t('confirm.subtitle'), style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Botao de confirmar (barra superior)
                  GestureDetector(
                    onTap: _confirmed ? null : () => _confirm(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: _confirmed ? AppTheme.accent.withValues(alpha: 0.5) : AppTheme.accent,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: _confirmed
                            ? null
                            : [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_confirmed ? Icons.hourglass_top_rounded : Icons.check_circle_rounded, size: 16, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            _confirmed ? t('cart.sending') : t('confirm.action'),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body: two columns ──
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: order items
                  Expanded(
                    flex: 3,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: cart.length + 1, // +1 for header
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                const Icon(Icons.restaurant_rounded, size: 20, color: AppTheme.accent),
                                const SizedBox(width: 10),
                                Text(t2('confirm.items', {'count': '$_itemCount'}), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                              ],
                            ),
                          );
                        }
                        final item = cart[index - 1];
                        return _OrderItemCard(item: item, currency: _currency);
                      },
                    ),
                  ),

                  // Right: summary
                  Container(
                    width: 340,
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.receipt_long_rounded, size: 20, color: AppTheme.accent),
                            SizedBox(width: 10),
                            Text('Resumo do Pedido', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Item list summary
                        ...cart.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 24, height: 24,
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.center,
                                child: Text('${item.quantity}x', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.accent)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(item.product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Colors.white)),
                              ),
                              Text(_currency.format(item.subtotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                            ],
                          ),
                        )),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(color: AppTheme.border, height: 1),
                        ),

                        // Subtotal
                        _SummaryLine(label: 'Subtotal', value: _currency.format(_subtotal)),
                        const SizedBox(height: 8),
                        _SummaryLine(label: 'Taxa de Serviço (10%)', value: _currency.format(_serviceTax)),
                        const SizedBox(height: 16),

                        // Total
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.accent.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('TOTAL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                              Text(_currency.format(_total), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.accent)),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // Instruction
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.border),
                          ),
                          // Mostra para QUAL mesa o pedido vai. Antes esta area
                          // instruia a escanear a comanda; agora que a mesa vem
                          // fixa do tablet, confirmar o destino e o que evita
                          // pedido lancado na mesa errada.
                          child: Row(
                            children: [
                              const Icon(Icons.table_restaurant_rounded, size: 28, color: AppTheme.accent),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  t2('confirm.destination', {'code': tableCode}),
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Botao principal de confirmacao
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _confirmed ? null : () => _confirm(context),
                            icon: Icon(_confirmed ? Icons.hourglass_top_rounded : Icons.check_circle_rounded, size: 18),
                            label: Text(
                              _confirmed ? 'ENVIANDO...' : 'CONFIRMAR E ENVIAR',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Order item card with image ──
class _OrderItemCard extends StatelessWidget {
  const _OrderItemCard({required this.item, required this.currency});
  final CartItem item;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 80, height: 80,
              child: item.product.imageUrl != null && item.product.imageUrl!.isNotEmpty
                  ? Image.network(item.product.imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder())
                  : _placeholder(),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                if (item.product.brand.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(item.product.brand, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${item.quantity}x unidade', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.accent)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(currency.format(item.subtotal),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 2),
              Text('${currency.format(item.product.price)} / un',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    color: AppTheme.surfaceHigh,
    alignment: Alignment.center,
    child: const Icon(Icons.restaurant_rounded, size: 28, color: AppTheme.textMuted),
  );
}

// ── Summary line ──
class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
      ],
    );
  }
}

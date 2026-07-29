import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../models/cart_item.dart';
import '../models/menu_product.dart';

class CartPanelWidget extends StatelessWidget {
  const CartPanelWidget({
    super.key,
    required this.cart,
    required this.currency,
    required this.cartTotal,
    required this.sendingOrder,
    required this.suggestions,
    required this.onAddSuggestion,
    required this.onChangeQuantity,
    required this.onRemoveItem,
    required this.onSubmitOrder,
  });

  final List<CartItem> cart;
  final NumberFormat currency;
  final double cartTotal;
  final bool sendingOrder;
  final List<MenuProduct> suggestions;
  final void Function(MenuProduct) onAddSuggestion;
  final void Function(MenuProduct product, int delta) onChangeQuantity;
  final void Function(MenuProduct product, int quantity) onRemoveItem;
  final VoidCallback onSubmitOrder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(left: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Sugestões (esconde quando tem itens no carrinho para dar espaço) ──
          if (suggestions.isNotEmpty && cart.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('SUGESTÕES DO CHEF', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.6)),
                      Icon(Icons.auto_awesome_rounded, size: 18, color: AppTheme.badgeYellow),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...suggestions.take(3).map((p) => _SuggestionItem(product: p, currency: currency, onTap: () => onAddSuggestion(p))),
                ],
              ),
            ),

          // ── Carrinho ──
          if (cart.isNotEmpty) ...[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('RESUMO DO PEDIDO', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.6)),
                      const Icon(Icons.receipt_long_rounded, size: 18, color: AppTheme.textMuted),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...cart.map((item) => _CartItemRow(item: item, currency: currency, onRemove: () => onRemoveItem(item.product, item.quantity))),
                ],
              ),
            ),

            // ── Rodapé: totais + botão ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: const Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: Column(
                children: [
                  _SummaryRow(label: 'Subtotal', value: currency.format(cartTotal)),
                  const SizedBox(height: 6),
                  _SummaryRow(label: 'Taxa de Serviço (10%)', value: currency.format(cartTotal * 0.1)),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(color: AppTheme.border, height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                      Text(currency.format(cartTotal * 1.1), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.accent)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: sendingOrder ? null : onSubmitOrder,
                      icon: Icon(sendingOrder ? Icons.hourglass_top_rounded : Icons.check_circle_rounded, size: 20),
                      label: Text(sendingOrder ? 'ENVIANDO...' : 'CONFIRMAR PEDIDO', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
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
          ] else
            const Spacer(),
        ],
      ),
    );
  }
}

// ── Suggestion item ──
class _SuggestionItem extends StatelessWidget {
  const _SuggestionItem({required this.product, required this.currency, required this.onTap});
  final MenuProduct product;
  final NumberFormat currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 50, height: 50,
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? Image.network(product.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => _ph())
                    : _ph(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(currency.format(product.price), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.accent)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ph() => Container(color: AppTheme.surfaceHigh, alignment: Alignment.center, child: const Icon(Icons.restaurant_rounded, size: 20, color: AppTheme.textMuted));
}

// ── Cart item row ──
class _CartItemRow extends StatelessWidget {
  const _CartItemRow({required this.item, required this.currency, required this.onRemove});
  final CartItem item;
  final NumberFormat currency;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 2),
                Text('${item.quantity}x Unidade', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Text(currency.format(item.subtotal), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Text('Remover', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.accent)),
          ),
        ],
      ),
    );
  }
}

// ── Summary row ──
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textMuted)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
      ],
    );
  }
}

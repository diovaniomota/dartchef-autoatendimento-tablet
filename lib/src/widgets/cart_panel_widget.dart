import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_language.dart';
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
    required this.onRemoveItem,
    required this.onEditNotes,
    required this.onSubmitOrder,
  });

  final List<CartItem> cart;
  final NumberFormat currency;
  final double cartTotal;
  final bool sendingOrder;
  final List<MenuProduct> suggestions;
  final void Function(MenuProduct) onAddSuggestion;

  // Identificam a LINHA do carrinho, nao o produto: com observacao por item, o
  // mesmo produto pode ocupar duas linhas (um sem salada, outro normal), e
  // buscar por product.id removeria/alteraria a linha errada.
  final void Function(int index) onRemoveItem;
  final void Function(int index) onEditNotes;
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
                      Text(t('cart.chefSuggestions'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.6)),
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
                      Text(t('cart.summary'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.6)),
                      const Icon(Icons.receipt_long_rounded, size: 18, color: AppTheme.textMuted),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // asMap para ter o indice: e ele que identifica a linha.
                  ...cart.asMap().entries.map((entry) => _CartItemRow(
                        item: entry.value,
                        currency: currency,
                        onRemove: () => onRemoveItem(entry.key),
                        onEditNotes: () => onEditNotes(entry.key),
                      )),
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
                  _SummaryRow(label: t('cart.subtotal'), value: currency.format(cartTotal)),
                  const SizedBox(height: 6),
                  _SummaryRow(label: t('cart.serviceFee'), value: currency.format(cartTotal * 0.1)),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(color: AppTheme.border, height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t('cart.total'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
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
                      label: Text(sendingOrder ? t('cart.sending') : t('cart.confirm'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
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
  const _CartItemRow({
    required this.item,
    required this.currency,
    required this.onRemove,
    required this.onEditNotes,
  });
  final CartItem item;
  final NumberFormat currency;
  final VoidCallback onRemove;
  final VoidCallback onEditNotes;

  @override
  Widget build(BuildContext context) {
    final notes = item.notes.trim();
    final options = item.optionsLabel;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
          ),

          // Variacao escolhida ("Vodka") logo abaixo do nome, em tom neutro:
          // e parte da identidade do item, nao um pedido especial. A
          // observacao, essa sim, fica destacada em seguida.
          if (options.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              options,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
            ),
          ],

          // Observacao aparece logo abaixo do nome: e o que o cliente precisa
          // conferir antes de confirmar o pedido.
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
              ),
              child: Text(
                notes,
                style: const TextStyle(fontSize: 12, color: AppTheme.accent, fontWeight: FontWeight.w600),
              ),
            ),
          ],

          const SizedBox(height: 6),

          // Botao de observacao com alvo de 48 de altura, mesmo criterio do
          // botao Remover.
          Material(
            color: AppTheme.surfaceHigh,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onEditNotes,
              borderRadius: BorderRadius.circular(10),
              splashColor: AppTheme.accent.withValues(alpha: 0.28),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(notes.isEmpty ? Icons.edit_note_rounded : Icons.check_circle_rounded,
                        size: 17, color: AppTheme.accent),
                    const SizedBox(width: 6),
                    Text(
                      notes.isEmpty ? t('cart.addNote') : t('cart.editNote'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.accent),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),
          Row(
            children: [
              Text('${item.quantity}x', style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  currency.format(item.subtotal),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
              const SizedBox(width: 4),
              // Antes era um GestureDetector direto no Text('Remover') em
              // fonte 12: a area sensivel ao toque era o retangulo das letras
              // (~52x14), bem abaixo dos 48x48 que o Android recomenda, e sem
              // nenhum retorno visual. Num tablet de digitalizador simples o
              // toque errava quase sempre e o cliente achava que travou.
              // Material + InkWell dao a area minima E o efeito de toque.
              Material(
                color: AppTheme.surfaceHigh,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(10),
                  splashColor: AppTheme.accent.withValues(alpha: 0.28),
                  highlightColor: AppTheme.accent.withValues(alpha: 0.14),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.delete_outline_rounded, size: 17, color: AppTheme.accent),
                        const SizedBox(width: 5),
                        Text(t('cart.remove'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.accent)),
                      ],
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

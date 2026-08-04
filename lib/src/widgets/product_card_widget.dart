import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_language.dart';
import '../core/app_theme.dart';
import '../models/menu_product.dart';

class ProductCardWidget extends StatelessWidget {
  const ProductCardWidget({
    super.key,
    required this.product,
    required this.currency,
    required this.onAdd,
    this.showBadge = false,
  });

  final MenuProduct product;
  final NumberFormat currency;
  final VoidCallback onAdd;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onAdd,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Imagem
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 140,
                      height: 100,
                      child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                          ? Image.network(product.imageUrl!, fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _placeholder())
                          : _placeholder(),
                    ),
                  ),
                  if (showBadge)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(t('product.featured'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3)),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 16),

              // Nome + descrição + preço
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white, height: 1.3),
                    ),
                    if (product.brand.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        product.brand,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.5),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(t('product.unitPrice'), style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    Text(
                      currency.format(product.price),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.accent),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Botão + Adicionar
              _AddButton(onTap: onAdd),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    final color = _catColor(product.category);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        product.name.isNotEmpty ? product.name[0].toUpperCase() : '?',
        style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: color.withValues(alpha: 0.6)),
      ),
    );
  }

  Color _catColor(String c) {
    final l = c.toLowerCase();
    if (l.contains('hambur') || l.contains('burger') || l.contains('lanch')) return const Color(0xFFFF8C00);
    if (l.contains('pizza')) return const Color(0xFFE53935);
    if (l.contains('bebida') || l.contains('drink')) return const Color(0xFF26A69A);
    if (l.contains('sobremesa') || l.contains('doce')) return const Color(0xFFAB47BC);
    if (l.contains('salada')) return const Color(0xFF66BB6A);
    if (l.contains('entrada')) return const Color(0xFF42A5F5);
    return AppTheme.accent;
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.accent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 16, color: Colors.white),
            const SizedBox(width: 5),
            Text(t('product.add'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

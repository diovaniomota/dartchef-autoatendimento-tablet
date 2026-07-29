import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../models/menu_product.dart';
import 'product_card_widget.dart';

class HomeHighlightsWidget extends StatelessWidget {
  const HomeHighlightsWidget({
    super.key,
    required this.products,
    required this.currency,
    required this.onAdd,
    required this.organizationName,
  });

  final List<MenuProduct> products;
  final NumberFormat currency;
  final void Function(MenuProduct) onAdd;
  final String organizationName;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(child: Text('Nenhum produto disponível.', style: TextStyle(color: AppTheme.textMuted)));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: products.length + 2, // +2: hero + section header
      itemBuilder: (context, index) {
        if (index == 0) {
          return _HeroCarousel(
            products: products.take(5).toList(),
            onAdd: onAdd,
          );
        }
        if (index == 1) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Destaques da Semana', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                      SizedBox(height: 3),
                      Text('As melhores escolhas preparadas por nossos chefs', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                const Text('Ver tudo >', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.accent)),
              ],
            ),
          );
        }
        final product = products[index - 2];
        return ProductCardWidget(product: product, currency: currency, onAdd: () => onAdd(product), showBadge: true);
      },
    );
  }
}

// ──────────────────── Hero Carousel ────────────────────

class _HeroCarousel extends StatefulWidget {
  const _HeroCarousel({required this.products, required this.onAdd});
  final List<MenuProduct> products;
  final void Function(MenuProduct) onAdd;

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  late final PageController _ctrl;
  int _current = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || widget.products.isEmpty) return;
      final next = (_current + 1) % widget.products.length;
      _ctrl.animateToPage(next, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 264,
      child: Stack(
        children: [
          PageView.builder(
            controller: _ctrl,
            itemCount: widget.products.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => _HeroSlide(
              product: widget.products[i],
              onAdd: () => widget.onAdd(widget.products[i]),
            ),
          ),
          // Dots
          Positioned(
            bottom: 16,
            right: 20,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.products.length, (i) {
                final active = i == _current;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSlide extends StatelessWidget {
  const _HeroSlide({required this.product, required this.onAdd});
  final MenuProduct product;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Imagem de fundo
        product.imageUrl != null && product.imageUrl!.isNotEmpty
            ? Image.network(product.imageUrl!, fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback())
            : _fallback(),

        // Gradiente de baixo para cima
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xF0000000), Color(0x88000000), Color(0x00000000)],
              stops: [0.0, 0.5, 1.0],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ),

        // Conteúdo no rodapé
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: AppTheme.badgeYellow, borderRadius: BorderRadius.circular(20)),
                      child: const Text('O MAIS PEDIDO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black, letterSpacing: 0.5)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1),
                    ),
                    if (product.brand.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        product.brand,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.75)),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('A partir de', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
                            Text(
                              _fmt(product.price),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        GestureDetector(
                          onTap: onAdd,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(8)),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_shopping_cart_rounded, size: 16, color: Colors.white),
                                SizedBox(width: 6),
                                Text('ADICIONAR', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.4)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _fmt(double price) {
    final f = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return f.format(price);
  }

  Widget _fallback() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xFF1A1B2E), Color(0xFF0F1B3E)]),
    ),
  );
}

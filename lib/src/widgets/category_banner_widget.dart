import 'package:flutter/material.dart';

class CategoryBannerWidget extends StatelessWidget {
  const CategoryBannerWidget({super.key, required this.categoryName});

  final String categoryName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 76,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: _getGradient(categoryName),
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Icon(
              _getCategoryIcon(categoryName),
              size: 70,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 100, 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _getDescription(categoryName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDescription(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('hambur') || lower.contains('burger')) return 'Carnes suculentas, molhos especiais e acompanhamentos irresistíveis';
    if (lower.contains('pizza')) return 'Pizzas artesanais com ingredientes selecionados e massa crocante';
    if (lower.contains('entrada')) return 'Entradas perfeitas para começar sua refeição com muito sabor';
    if (lower.contains('bebida') || lower.contains('drink')) return 'Drinks, sucos naturais e bebidas especiais';
    if (lower.contains('sobremesa') || lower.contains('doce')) return 'Sobremesas deliciosas para um final perfeito';
    if (lower.contains('salada')) return 'Saladas frescas e saudáveis com ingredientes selecionados';
    if (lower.contains('acompanhamento')) return 'Acompanhamentos que complementam seu prato principal';
    return 'Confira as opções disponíveis nesta categoria';
  }

  List<Color> _getGradient(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('hambur') || lower.contains('burger')) return [const Color(0xFF1A1B2E), const Color(0xFF0F1B3E)];
    if (lower.contains('pizza')) return [const Color(0xFF2B1515), const Color(0xFF1A0D2E)];
    if (lower.contains('bebida') || lower.contains('drink')) return [const Color(0xFF0D2137), const Color(0xFF122E1A)];
    if (lower.contains('sobremesa') || lower.contains('doce')) return [const Color(0xFF2E1A2E), const Color(0xFF1A1A2E)];
    return [const Color(0xFF151525), const Color(0xFF0D1830)];
  }

  IconData _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('hambur') || lower.contains('burger')) return Icons.lunch_dining_rounded;
    if (lower.contains('pizza')) return Icons.local_pizza_rounded;
    if (lower.contains('bebida') || lower.contains('drink')) return Icons.local_bar_rounded;
    if (lower.contains('sobremesa') || lower.contains('doce')) return Icons.cake_rounded;
    if (lower.contains('salada')) return Icons.eco_rounded;
    if (lower.contains('entrada')) return Icons.tapas_rounded;
    return Icons.restaurant_menu_rounded;
  }
}

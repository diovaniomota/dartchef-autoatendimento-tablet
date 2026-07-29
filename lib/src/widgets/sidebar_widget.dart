import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class SidebarWidget extends StatelessWidget {
  const SidebarWidget({
    super.key,
    required this.categories,
    required this.activeCategory,
    required this.onCategorySelected,
    required this.onSettingsTap,
    required this.onAboutTap,
  });

  final List<String> categories;
  final String activeCategory;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onSettingsTap;
  final VoidCallback onAboutTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      color: const Color(0xFF111111),
      child: Column(
        children: [
          // Logo — orange rounded square with icon
          GestureDetector(
            onLongPress: onSettingsTap,
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 16, 0, 12),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: AppTheme.accent.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 8)),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.restaurant_menu_rounded, size: 30, color: Colors.white),
            ),
          ),

          const SizedBox(height: 4),

          // DESTAQUES
          _SidebarItem(
            icon: Icons.star_rounded,
            label: 'DESTAQUES',
            isActive: activeCategory == 'Todos',
            onTap: () => onCategorySelected('Todos'),
          ),

          // Divisor
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(height: 1, color: const Color(0xFF2A2A2A)),
          ),

          // Categorias dinâmicas
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: categories.length,
              itemBuilder: (_, i) => _SidebarItem(
                icon: _icon(categories[i]),
                label: _shortLabel(categories[i]),
                isActive: categories[i] == activeCategory,
                onTap: () => onCategorySelected(categories[i]),
              ),
            ),
          ),

          // Rodapé
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(height: 1, color: const Color(0xFF2A2A2A)),
          ),
          IconButton(
            onPressed: onSettingsTap,
            icon: const Icon(Icons.settings_rounded, size: 22, color: Color(0xFF555555)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _shortLabel(String cat) {
    if (cat.length <= 8) return cat.toUpperCase();
    final words = cat.trim().split(' ');
    return words.first.toUpperCase();
  }

  IconData _icon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('hambur') || lower.contains('burger') || lower.contains('lanch')) return Icons.lunch_dining_rounded;
    if (lower.contains('pizza')) return Icons.local_pizza_rounded;
    if (lower.contains('bebida') || lower.contains('drink') || lower.contains('bar')) return Icons.local_bar_rounded;
    if (lower.contains('sobremesa') || lower.contains('doce')) return Icons.icecream_rounded;
    if (lower.contains('salada') || lower.contains('veggie') || lower.contains('vegeta')) return Icons.eco_rounded;
    if (lower.contains('entrada') || lower.contains('porcao') || lower.contains('porção')) return Icons.tapas_rounded;
    if (lower.contains('acompanhamento') || lower.contains('acomp')) return Icons.restaurant_rounded;
    if (lower.contains('prato') || lower.contains('cozinha') || lower.contains('principal')) return Icons.set_meal_rounded;
    if (lower.contains('cafe') || lower.contains('café') || lower.contains('breakfast')) return Icons.coffee_rounded;
    if (lower.contains('suco') || lower.contains('fruta')) return Icons.local_drink_rounded;
    return Icons.restaurant_menu_rounded;
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({required this.icon, required this.label, required this.isActive, required this.onTap});

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: isActive ? AppTheme.accent : const Color(0xFF888888)),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: isActive ? AppTheme.accent : const Color(0xFF888888),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

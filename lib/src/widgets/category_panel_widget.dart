import 'package:flutter/material.dart';

/// Painel lateral de categorias — aparece quando CARDÁPIO está ativo
class CategoryPanelWidget extends StatelessWidget {
  const CategoryPanelWidget({
    super.key,
    required this.categories,
    required this.activeCategory,
    required this.onCategorySelected,
  });

  final List<String> categories;
  final String activeCategory;
  final ValueChanged<String> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 186,
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D0D),
        border: Border(
          left: BorderSide(color: Color(0xFF1E1E1E), width: 1),
          right: BorderSide(color: Color(0xFF1E1E1E), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do painel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1A1A1A))),
            ),
            child: const Text(
              'CATEGORIAS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: Color(0xFF777777)),
            ),
          ),

          // Lista de categorias
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isActive = cat == activeCategory;
                return _CategoryItem(
                  label: cat,
                  isActive: isActive,
                  onTap: () => onCategorySelected(cat),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({required this.label, required this.isActive, required this.onTap});

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            if (isActive)
              Container(
                width: 3, height: 14,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(2)),
              ),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? Colors.white : const Color(0xFFAAAAAA),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

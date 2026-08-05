import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_language.dart';
import '../core/app_theme.dart';
import '../models/menu_product.dart';
import '../widgets/tablet_chrome.dart';

/// Itens da categoria escolhida.
///
/// Uma linha por produto, com foto grande a esquerda: o cliente reconhece o
/// prato pela imagem antes de ler o nome. O botao de adicionar fica na propria
/// linha para o caso comum — quem so quer "um espetinho de frango" nao precisa
/// abrir o detalhe.
class ProductListScreen extends StatelessWidget {
  const ProductListScreen({
    super.key,
    required this.categoryName,
    required this.products,
    required this.currency,
    required this.cartItemCount,
    required this.onBack,
    required this.onHomeTap,
    required this.onCartTap,
    required this.onProductTap,
    required this.onQuickAdd,
  });

  final String categoryName;
  final List<MenuProduct> products;
  final NumberFormat currency;
  final int cartItemCount;
  final VoidCallback onBack;
  final VoidCallback onHomeTap;
  final VoidCallback onCartTap;
  final ValueChanged<MenuProduct> onProductTap;

  /// Adiciona uma unidade sem abrir o detalhe. Recebe o produto porque quem
  /// decide se ainda ha pergunta a fazer (variacao obrigatoria) e a tela de
  /// cima, nao esta lista.
  final ValueChanged<MenuProduct> onQuickAdd;

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
                titulo: categoryName.toUpperCase(),
                cartItemCount: cartItemCount,
                onBack: onBack,
                onCartTap: onCartTap,
              ),
              Expanded(
                child: products.isEmpty
                    ? Center(
                        child: Text(
                          t('list.empty'),
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 16),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: products.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _LinhaProduto(
                          produto: products[i],
                          currency: currency,
                          onTap: () => onProductTap(products[i]),
                          onAdd: () => onQuickAdd(products[i]),
                        ),
                      ),
              ),
              TabletBottomBar(
                cartItemCount: cartItemCount,
                onHomeTap: onHomeTap,
                onCartTap: onCartTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinhaProduto extends StatelessWidget {
  const _LinhaProduto({
    required this.produto,
    required this.currency,
    required this.onTap,
    required this.onAdd,
  });

  final MenuProduct produto;
  final NumberFormat currency;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 116,
                  height: 96,
                  child: produto.imageUrl?.isNotEmpty == true
                      ? Image.network(
                          produto.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const _SemFoto(),
                        )
                      : const _SemFoto(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      produto.name.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    if (produto.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        produto.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12.5, height: 1.25),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            currency.format(produto.price),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 46,
                          child: FilledButton.icon(
                            onPressed: onAdd,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.accent,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.add, size: 20),
                            label: Text(
                              t('product.addUpper'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
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
      ),
    );
  }
}

class _SemFoto extends StatelessWidget {
  const _SemFoto();

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: AppTheme.surfaceHigh,
        child: Center(
          child: Icon(Icons.restaurant, color: AppTheme.textMuted, size: 28),
        ),
      );
}

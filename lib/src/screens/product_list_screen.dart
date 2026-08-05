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
        child: AspectRatio(
          // Proporcao e nao altura fixa: a linha precisa manter a mesma cara no
          // tablet de 7" e no de 10".
          aspectRatio: 3.2,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Foto encostada na borda e ocupando a altura toda, como na
                  // referencia. Com moldura e cantos arredondados dos quatro
                  // lados ela virava miniatura, e a comida e o que vende.
                  Expanded(
                    flex: 44,
                    child: produto.imageUrl?.isNotEmpty == true
                        ? Image.network(
                            produto.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const _SemFoto(),
                          )
                        : const _SemFoto(),
                  ),
                  Expanded(
                    flex: 56,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            produto.name.toUpperCase(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                          if (produto.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              produto.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 13.5,
                                height: 1.25,
                              ),
                            ),
                          ],
                          const Spacer(),
                          // Preco e botao na mesma linha, o preco a esquerda:
                          // o cliente le o valor e o dedo ja esta sobre o
                          // ADICIONAR, sem atravessar o cartao.
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Text(
                                  currency.format(produto.price),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 52,
                                child: FilledButton.icon(
                                  onPressed: onAdd,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppTheme.accent,
                                    padding: const EdgeInsets.symmetric(horizontal: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add, size: 22),
                                  label: Text(
                                    t('product.addUpper'),
                                    style: const TextStyle(
                                      fontSize: 14.5,
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
                  ),
                ],
              ),
            ),
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

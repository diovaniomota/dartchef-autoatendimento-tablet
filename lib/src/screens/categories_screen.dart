import 'package:flutter/material.dart';

import '../core/app_language.dart';
import '../core/app_theme.dart';
import '../models/menu_product.dart';
import '../widgets/tablet_chrome.dart';

/// Escolha da categoria, primeira tela depois de "toque para comecar".
///
/// Cartoes grandes com foto em vez de uma lista de texto: o cliente esta de pe
/// na mesa, decidindo pelo que ve. Foto de espetinho vende espetinho; a palavra
/// "ESPETINHOS TRADICIONAIS" nao.
///
/// A foto de cada cartao vem de um PRODUTO daquela categoria — nao existe campo
/// de imagem por categoria no cadastro, e obrigar a cliente a subir sete fotos
/// novas para ver esta tela funcionando seria trocar uma tela bonita por
/// trabalho. Categoria sem nenhuma foto cai num fundo escuro com o nome, que
/// continua legivel.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({
    super.key,
    required this.categories,
    required this.products,
    required this.logoUrl,
    required this.restaurantName,
    required this.cartItemCount,
    required this.onCategorySelected,
    required this.onSearchTap,
    required this.onCartTap,
    required this.onHomeTap,
  });

  final List<String> categories;
  final List<MenuProduct> products;
  final String logoUrl;
  final String restaurantName;
  final int cartItemCount;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onSearchTap;
  final VoidCallback onCartTap;
  final VoidCallback onHomeTap;

  /// Foto que representa a categoria: a primeira, na ordem do cardapio, entre os
  /// produtos dela que tenham imagem.
  ///
  /// Ordem fixa de proposito. Sorteio deixaria o cartao mudando de foto a cada
  /// pedido, e o cliente que volta perde a referencia visual do que era o quê.
  String _fotoDaCategoria(String categoria) {
    for (final produto in products) {
      if (produto.category != categoria) continue;
      final url = produto.imageUrl ?? '';
      if (url.isNotEmpty) return url;
    }
    return '';
  }

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
                titulo: restaurantName,
                logoUrl: logoUrl,
                cartItemCount: cartItemCount,
                onSearchTap: onSearchTap,
                onCartTap: onCartTap,
              ),
              Expanded(
                child: categories.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            t('categories.empty'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 16),
                          ),
                        ),
                      )
                    : _grade(),
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

  Widget _grade() {
    return LayoutBuilder(
      builder: (context, restricoes) {
        // Duas colunas no tablet; uma so quando a largura nao dá para o cartao
        // manter a foto reconhecivel.
        final colunas = restricoes.maxWidth < 560 ? 1 : 2;
        final sobra = categories.length % colunas;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                t('categories.title'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            for (var i = 0; i < categories.length; i += colunas)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    for (var j = i; j < i + colunas && j < categories.length; j += 1) ...[
                      Expanded(
                        child: _CartaoCategoria(
                          nome: categories[j],
                          imagemUrl: _fotoDaCategoria(categories[j]),
                          // A ultima sozinha na fileira ocupa a largura toda,
                          // como no desenho aprovado — e assim ela nao fica
                          // metade da tela com um vazio do lado.
                          alturaMenor: colunas == 2 && sobra == 1 && j == categories.length - 1,
                          onTap: () => onCategorySelected(categories[j]),
                        ),
                      ),
                      if (j + 1 < i + colunas && j + 1 < categories.length)
                        const SizedBox(width: 12),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CartaoCategoria extends StatelessWidget {
  const _CartaoCategoria({
    required this.nome,
    required this.imagemUrl,
    required this.alturaMenor,
    required this.onTap,
  });

  final String nome;
  final String imagemUrl;
  final bool alturaMenor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: alturaMenor ? 118 : 148,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imagemUrl.isNotEmpty)
                  Image.network(
                    imagemUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const ColoredBox(color: AppTheme.surfaceHigh),
                  )
                else
                  const ColoredBox(color: AppTheme.surfaceHigh),

                // Veu escuro: foto de comida tem muito ponto claro e o nome
                // branco desaparecia justamente sobre a parte apetitosa.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xF2000000), Color(0x66000000)],
                    ),
                  ),
                  child: SizedBox.expand(),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      nome.toUpperCase(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                        letterSpacing: 0.4,
                        shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

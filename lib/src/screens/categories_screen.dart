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
    this.categoryImages = const {},
    required this.logoUrl,
    required this.restaurantName,
    required this.cartItemCount,
    required this.onCategorySelected,
    required this.onSearchTap,
    required this.onCartTap,
    required this.onHomeTap,
    this.onCallWaiter,
    this.onRequestBill,
  });

  final List<String> categories;
  final List<MenuProduct> products;

  /// Foto escolhida pelo restaurante para cada categoria.
  final Map<String, String> categoryImages;
  final String logoUrl;
  final String restaurantName;
  final int cartItemCount;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onSearchTap;
  final VoidCallback onCartTap;
  final VoidCallback onHomeTap;
  final VoidCallback? onCallWaiter;
  final VoidCallback? onRequestBill;

  /// TODAS as fotos da categoria, na ordem do cardapio.
  ///
  /// Lista e nao uma foto so porque endereco podre e comum: o catalogo tem
  /// produtos apontando para um projeto Supabase antigo que nem existe mais.
  /// Devolvendo apenas a primeira, uma unica URL morta deixava o cartao vazio
  /// mesmo havendo foto boa no terceiro produto da mesma categoria — foi
  /// exatamente o que aconteceu com "Lanches".
  ///
  /// Ordem fixa de proposito. Sorteio deixaria o cartao mudando de foto a cada
  /// pedido, e o cliente que volta perde a referencia visual do que era o quê.
  List<String> _fotosDaCategoria(String categoria) {
    final urls = <String>[];

    // A foto CADASTRADA vem primeiro: quando a cliente escolheu uma, e ela que
    // representa a categoria. A do produto continua atras, como retaguarda para
    // quem ainda nao cadastrou — sem isso a tela ficaria vazia ate alguem subir
    // sete fotos.
    final escolhida = (categoryImages[categoria] ?? '').trim();
    if (escolhida.isNotEmpty) urls.add(escolhida);

    for (final produto in products) {
      if (produto.category != categoria) continue;
      final url = (produto.imageUrl ?? '').trim();
      if (url.isNotEmpty && !urls.contains(url)) urls.add(url);
    }
    return urls;
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
                onCallWaiter: onCallWaiter,
                onRequestBill: onRequestBill,
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
        // Duas colunas sempre que couber. O limite era 560 e estava alto
        // demais: o tablet de 7" EM PE tem cerca de 500 de largura e caia para
        // uma coluna so, diferente da referencia. Abaixo de 380 o cartao ficaria
        // estreito demais para a foto valer alguma coisa.
        final colunas = restricoes.maxWidth < 380 ? 1 : 2;
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
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
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
                          imagens: _fotosDaCategoria(categories[j]),
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

/// Cartao de uma categoria.
///
/// Stateful por causa das fotos: recebe TODAS as fotos da categoria e tenta uma
/// a uma. Endereco podre e comum no catalogo — ha produtos apontando para um
/// projeto Supabase antigo que nem existe mais — e sem essa troca uma unica URL
/// morta deixava o cartao vazio mesmo havendo foto boa logo em seguida.
class _CartaoCategoria extends StatefulWidget {
  const _CartaoCategoria({
    required this.nome,
    required this.imagens,
    required this.alturaMenor,
    required this.onTap,
  });

  final String nome;
  final List<String> imagens;
  final bool alturaMenor;
  final VoidCallback onTap;

  @override
  State<_CartaoCategoria> createState() => _CartaoCategoriaState();
}

class _CartaoCategoriaState extends State<_CartaoCategoria> {
  int _indice = 0;

  String? get _urlAtual =>
      _indice < widget.imagens.length ? widget.imagens[_indice] : null;

  void _proximaFoto() {
    if (_indice >= widget.imagens.length) return;
    // setState dentro do errorBuilder precisa esperar o frame terminar: o
    // callback roda DURANTE o build, e mexer no estado ali dispara
    // "setState() called during build".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _indice += 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final url = _urlAtual;

    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          // Proporcao e nao altura fixa: com altura em pixels o cartao ficava
          // quadrado no tablet pequeno e achatado no grande. A referencia tem
          // cerca de 2:1 nos cartoes de meia largura; o que ocupa a linha
          // inteira fica mais alongado para nao dominar a tela.
          aspectRatio: widget.alturaMenor ? 3.3 : 2.0,
          child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            // Contorno claro, como na referencia: sem ele o cartao se dissolve
            // no fundo preto quando a foto e escura nas bordas.
            border: Border.all(color: Colors.white24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (url != null)
                  Image.network(
                    url,
                    // key pela URL: sem ela o Flutter reusa o elemento anterior
                    // e nao refaz a requisicao ao trocar de foto.
                    key: ValueKey(url),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) {
                      _proximaFoto();
                      return const _SemFotoCategoria();
                    },
                  )
                else
                  const _SemFotoCategoria(),

                // Veu SO na parte de baixo, e de cima para baixo.
                //
                // A primeira versao escurecia da esquerda para a direita com 95%
                // de preto: o nome ficava legivel e a foto sumia — o oposto do
                // objetivo, que e o cliente escolher pela imagem. Aqui os dois
                // tercos de cima ficam limpos e o escuro entra so onde o texto
                // pousa.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0x33000000), Color(0xE6000000)],
                      stops: [0.35, 0.55, 1.0],
                    ),
                  ),
                  child: SizedBox.expand(),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                  child: Align(
                    // Embaixo e centralizado, como na referencia: e onde o olho
                    // chega depois de ver a foto.
                    alignment: Alignment.bottomCenter,
                    child: Text(
                      widget.nome.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                        letterSpacing: 0.4,
                        shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                      ),
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

/// Fundo de categoria sem nenhuma foto que carregue.
///
/// Icone e nao um retangulo liso: cartao chapado parece tela quebrada, e o
/// cliente fica sem saber se e para tocar. Com o icone fica claro que e um item
/// do cardapio esperando foto.
class _SemFotoCategoria extends StatelessWidget {
  const _SemFotoCategoria();

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: AppTheme.surfaceHigh,
        child: Center(
          child: Icon(Icons.restaurant_menu, color: Colors.white24, size: 40),
        ),
      );
}

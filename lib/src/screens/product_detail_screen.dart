import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_language.dart';
import '../core/app_theme.dart';
import '../models/menu_product.dart';
import '../widgets/tablet_chrome.dart';

/// Detalhe do item: quantidade, variacao e observacao numa tela so.
///
/// Antes cada uma dessas tres coisas era um dialogo separado, empilhado sobre o
/// cardapio. Num tablet de 7" em pe, dialogo sobre dialogo empurra o campo de
/// digitar para fora da tela — foi exatamente o que aconteceu com a observacao.
/// Aqui tudo cabe de uma vez e o cliente ve o que esta pedindo.
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.produto,
    required this.currency,
    required this.cartItemCount,
    required this.onBack,
    required this.onCartTap,
    required this.onAdd,
    this.quantidadeInicial = 1,
    this.escolhasIniciais = const [],
    this.observacaoInicial = '',
    this.editando = false,
  });

  final MenuProduct produto;
  final NumberFormat currency;
  final int cartItemCount;
  final VoidCallback onBack;
  final VoidCallback onCartTap;

  /// Estado atual do item quando se esta EDITANDO uma linha do carrinho.
  ///
  /// Sem isto, corrigir "sem cebola" obrigava a remover a linha e montar tudo de
  /// novo — inclusive a variacao, que o cliente ja tinha escolhido.
  final int quantidadeInicial;
  final List<ProductOptionChoice> escolhasIniciais;
  final String observacaoInicial;
  final bool editando;

  /// Entrega o pedido montado: quantidade, escolhas e observacao.
  final void Function(
    int quantidade,
    List<ProductOptionChoice> escolhas,
    String observacao,
  ) onAdd;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final TextEditingController _observacao =
      TextEditingController(text: widget.observacaoInicial);
  final Map<int, ProductOptionChoice> _escolhas = {};
  late int _quantidade = widget.quantidadeInicial;

  @override
  void initState() {
    super.initState();

    // Editando: retoma o que ja estava escolhido. Os grupos sao percorridos para
    // casar a escolha pelo ID, e nao confiar na ordem — opcao desativada no
    // cadastro depois some sozinha em vez de virar item fantasma.
    for (final grupo in widget.produto.optionGroups) {
      for (final escolhida in widget.escolhasIniciais) {
        if (grupo.choices.any((opcao) => opcao.id == escolhida.id)) {
          _escolhas[grupo.id] = escolhida;
        }
      }
      // Grupo opcional com uma unica opcao ja vem marcado: nao ha decisao a tomar.
      if (!_escolhas.containsKey(grupo.id) &&
          !grupo.required &&
          grupo.choices.length == 1) {
        _escolhas[grupo.id] = grupo.choices.first;
      }
    }
  }

  @override
  void dispose() {
    _observacao.dispose();
    super.dispose();
  }

  bool get _completo => widget.produto.optionGroups
      .where((grupo) => grupo.required)
      .every((grupo) => _escolhas.containsKey(grupo.id));

  double get _unitario =>
      widget.produto.price +
      _escolhas.values.fold(0.0, (soma, escolha) => soma + escolha.priceDelta);

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
                titulo: t('detail.title'),
                cartItemCount: widget.cartItemCount,
                onBack: widget.onBack,
                onCartTap: widget.onCartTap,
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, restricoes) {
                    // Foto ao lado ja no tablet EM PE, que e como a referencia
                    // mostra. O limite era 700 e caia no empilhado justamente no
                    // tamanho mais comum (cerca de 680), deixando a foto pequena
                    // e o resto solto embaixo.
                    final lado = restricoes.maxWidth >= 560;
                    return lado ? _duasColunas() : _empilhado();
                  },
                ),
              ),
              _rodape(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _duasColunas() => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Metade da tela, encostada na borda e sem moldura: e a foto que faz
          // o cliente decidir, e recuo com cantos arredondados a transformava
          // num cartaozinho no meio da tela.
          Expanded(flex: 5, child: _foto()),
          Expanded(
            flex: 5,
            child: ColoredBox(
              color: AppTheme.surface,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: _dados(),
              ),
            ),
          ),
        ],
      );

  Widget _empilhado() => SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Largura explicita: sem ela a foto encolhe ate a proporcao dela
            // propria e vira miniatura no canto.
            SizedBox(width: double.infinity, height: 240, child: _foto(raio: 14)),
            const SizedBox(height: 14),
            _dados(),
          ],
        ),
      );

  Widget _foto({double raio = 0}) {
    final url = widget.produto.imageUrl ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(raio),
      child: url.isEmpty
          ? const ColoredBox(
              color: AppTheme.surfaceHigh,
              child: Center(child: Icon(Icons.restaurant, color: AppTheme.textMuted, size: 48)),
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(
                color: AppTheme.surfaceHigh,
                child: Center(child: Icon(Icons.restaurant, color: AppTheme.textMuted, size: 48)),
              ),
            ),
    );
  }

  Widget _dados() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.produto.name.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          if (widget.produto.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              widget.produto.description,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14, height: 1.35),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            widget.currency.format(_unitario),
            style: const TextStyle(
              color: AppTheme.accent,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          _divisor(),
          _secao(t('detail.quantity')),
          const SizedBox(height: 8),
          _seletorQuantidade(),
          for (final grupo in widget.produto.optionGroups) ...[
            _divisor(),
            _secao(grupo.required
                ? grupo.name.toUpperCase()
                : '${grupo.name.toUpperCase()} (${t('options.optional')})'),
            const SizedBox(height: 4),
            for (final opcao in grupo.choices)
              _OpcaoRadio(
                nome: opcao.name,
                extra: opcao.priceDelta == 0
                    ? ''
                    : (opcao.priceDelta > 0
                        ? '+ ${widget.currency.format(opcao.priceDelta)}'
                        : '- ${widget.currency.format(opcao.priceDelta.abs())}'),
                marcado: _escolhas[grupo.id]?.id == opcao.id,
                onTap: () => setState(() => _escolhas[grupo.id] = opcao),
              ),
          ],
          _divisor(),
          _secao(t('detail.notes')),
          const SizedBox(height: 8),
          TextField(
            controller: _observacao,
            maxLength: 200,
            maxLines: 2,
            minLines: 1,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: t('notes.hint'),
              hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
              filled: true,
              fillColor: AppTheme.background,
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.accent, width: 2),
              ),
            ),
          ),
        ],
      );

  /// Fio fino entre as secoes, como na referencia: separa quantidade, molho e
  /// observacao sem precisar de espaco em branco, que num painel estreito
  /// empurraria o botao para fora da tela.
  Widget _divisor() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Divider(color: AppTheme.border, height: 1),
      );

  Widget _secao(String texto) => Text(
        texto,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
        ),
      );

  Widget _seletorQuantidade() => Row(
        children: [
          _BotaoQuantidade(
            icone: Icons.remove,
            // Uma unidade e o minimo: zerar aqui seria o mesmo que cancelar, e
            // para isso existe o VOLTAR.
            ativo: _quantidade > 1,
            onTap: () => setState(() => _quantidade -= 1),
          ),
          // O numero tambem numa caixa, como na referencia: os tres elementos
          // formam um controle so, em vez de dois botoes com um texto solto no
          // meio.
          Container(
            width: 86,
            height: kTabletTapTarget,
            alignment: Alignment.center,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Text(
              '$_quantidade',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
          _BotaoQuantidade(
            icone: Icons.add,
            ativo: _quantidade < 99,
            onTap: () => setState(() => _quantidade += 1),
          ),
        ],
      );

  Widget _rodape() => Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 62,
          child: FilledButton(
            // Desabilitado enquanto falta escolher variacao obrigatoria: melhor
            // o botao nao responder do que a comanda chegar incompleta no bar.
            onPressed: _completo
                ? () => widget.onAdd(
                      _quantidade,
                      _escolhas.values.toList(),
                      _observacao.text,
                    )
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              widget.editando ? t('detail.saveChanges') : t('detail.addToCart'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.6),
            ),
          ),
        ),
      );
}

class _BotaoQuantidade extends StatelessWidget {
  const _BotaoQuantidade({required this.icone, required this.ativo, required this.onTap});

  final IconData icone;
  final bool ativo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ativo ? AppTheme.surfaceHigh : AppTheme.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: ativo ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: kTabletTapTarget,
          height: kTabletTapTarget,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ativo ? AppTheme.accent : AppTheme.border),
          ),
          child: Icon(icone, color: ativo ? AppTheme.accent : AppTheme.border, size: 22),
        ),
      ),
    );
  }
}

class _OpcaoRadio extends StatelessWidget {
  const _OpcaoRadio({
    required this.nome,
    required this.extra,
    required this.marcado,
    required this.onTap,
  });

  final String nome;
  final String extra;
  final bool marcado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          // A linha inteira e o alvo, nao so a bolinha: mirar num circulo de
          // 20px com o dedo, de pe, e pedir erro.
          constraints: const BoxConstraints(minHeight: kTabletTapTarget),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Icon(
                marcado ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: marcado ? AppTheme.accent : AppTheme.textMuted,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  nome,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: marcado ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
              if (extra.isNotEmpty)
                Text(
                  extra,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

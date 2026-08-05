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
  });

  final MenuProduct produto;
  final NumberFormat currency;
  final int cartItemCount;
  final VoidCallback onBack;
  final VoidCallback onCartTap;

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
  final TextEditingController _observacao = TextEditingController();
  final Map<int, ProductOptionChoice> _escolhas = {};
  int _quantidade = 1;

  @override
  void initState() {
    super.initState();
    // Grupo opcional com uma unica opcao ja vem marcado: nao ha decisao a tomar.
    for (final grupo in widget.produto.optionGroups) {
      if (!grupo.required && grupo.choices.length == 1) {
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
                    // Foto ao lado no tablet deitado; empilhada quando a
                    // largura nao dá para as duas colunas respirarem.
                    final lado = restricoes.maxWidth >= 700;
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
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
              child: _foto(),
            ),
          ),
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(6, 12, 12, 12),
              child: _dados(),
            ),
          ),
        ],
      );

  Widget _empilhado() => SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 220, child: _foto()),
            const SizedBox(height: 14),
            _dados(),
          ],
        ),
      );

  Widget _foto() {
    final url = widget.produto.imageUrl ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
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
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          _secao(t('detail.quantity')),
          const SizedBox(height: 8),
          _seletorQuantidade(),
          for (final grupo in widget.produto.optionGroups) ...[
            const SizedBox(height: 18),
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
          const SizedBox(height: 18),
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
          Container(
            width: 74,
            height: kTabletTapTarget,
            alignment: Alignment.center,
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
              t('detail.addToCart'),
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

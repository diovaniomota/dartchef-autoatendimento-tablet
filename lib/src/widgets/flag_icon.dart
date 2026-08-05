import 'package:flutter/material.dart';

import '../core/app_language.dart';

/// Bandeira desenhada com widgets, nao com emoji.
///
/// Emoji de bandeira depende de fonte com suporte a regional indicators; em
/// tablets Android mais antigos aparece como as letras "US"/"ES" em vez da
/// bandeira. Desenhar garante o mesmo resultado em qualquer aparelho, sem
/// adicionar dependencia nem arquivo de imagem.
class FlagIcon extends StatelessWidget {
  const FlagIcon({super.key, required this.language, this.width = 26});

  final AppLanguage language;
  final double width;

  @override
  Widget build(BuildContext context) {
    final height = width * 2 / 3;

    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        width: width,
        height: height,
        child: switch (language) {
          AppLanguage.pt => _brazil(width, height),
          AppLanguage.en => _usa(width, height),
          AppLanguage.es => _spain(width, height),
        },
      ),
    );
  }

  // Verde, losango amarelo e circulo azul.
  static Widget _brazil(double w, double h) => Container(
        color: const Color(0xFF009B3A),
        child: Center(
          child: Transform.rotate(
            angle: 0.785398, // 45 graus: quadrado girado = losango
            child: Container(
              width: h * 0.52,
              height: h * 0.52,
              color: const Color(0xFFFEDF00),
              child: Center(
                child: Container(
                  width: h * 0.26,
                  height: h * 0.26,
                  decoration: const BoxDecoration(
                    color: Color(0xFF002776),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  // Listras vermelhas/brancas com o canto azul. Sem estrelas: nesse tamanho
  // elas viram ruido, e a leitura da bandeira nao depende delas.
  static Widget _usa(double w, double h) => Stack(
        children: [
          Column(
            children: List.generate(
              7,
              (i) => Expanded(
                child: Container(color: i.isEven ? const Color(0xFFB22234) : Colors.white),
              ),
            ),
          ),
          Container(
            width: w * 0.42,
            height: h * 0.54,
            color: const Color(0xFF3C3B6E),
          ),
        ],
      );

  // Vermelho, amarelo (faixa do meio, mais larga) e vermelho, com o brasao
  // sugerido a esquerda.
  //
  // So as tres faixas nao bastava: vermelho-amarelo-vermelho e a mesma leitura
  // do Catar, de Aragao e de varias bandeiras regionais, e sem nenhum detalhe a
  // cliente olhou a tela e disse que a bandeira da Espanha nao estava la. O
  // escudo e os dois pilares resolvem sem virar borrao neste tamanho.
  static Widget _spain(double w, double h) => Stack(
        fit: StackFit.expand,
        children: [
          // stretch e obrigatorio aqui, nao enfeite.
          //
          // ColoredBox sem filho encolhe para largura ZERO quando a restricao
          // de largura e solta, e Column passa restricao solta por padrao
          // (crossAxisAlignment.center). O resultado era a bandeira da Espanha
          // simplesmente nao aparecer — a faixa existia na arvore, com a cor
          // certa, e pintava nada. A dos EUA escapa porque usa
          // Container(color:), que sem filho expande em vez de encolher.
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              Expanded(flex: 1, child: ColoredBox(color: Color(0xFFAA151B))),
              Expanded(flex: 2, child: ColoredBox(color: Color(0xFFF1BF00))),
              Expanded(flex: 1, child: ColoredBox(color: Color(0xFFAA151B))),
            ],
          ),

          // Pilares de Hercules: ouro mais escuro para aparecer sobre o
          // amarelo da faixa.
          Positioned(
            left: w * 0.14,
            top: h * 0.30,
            width: w * 0.04,
            height: h * 0.40,
            child: const ColoredBox(color: Color(0xFFC8930A)),
          ),
          Positioned(
            left: w * 0.36,
            top: h * 0.30,
            width: w * 0.04,
            height: h * 0.40,
            child: const ColoredBox(color: Color(0xFFC8930A)),
          ),

          // Escudo.
          Positioned(
            left: w * 0.21,
            top: h * 0.29,
            width: w * 0.13,
            height: h * 0.42,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF9B1B1E),
                borderRadius: BorderRadius.circular(w * 0.02),
                border: Border.all(color: const Color(0xFFC8930A), width: 0.6),
              ),
            ),
          ),
        ],
      );
}

const Map<AppLanguage, String> languageNames = {
  AppLanguage.pt: 'Português',
  AppLanguage.en: 'English',
  AppLanguage.es: 'Español',
};

/// Botao unico com a bandeira atual, que abre a escolha de idioma.
///
/// Tres bandeiras lado a lado nao cabem: a barra superior tem 64px de altura e
/// ja carrega busca, mesa, quatro botoes e o CTA do pedido — num tablet de 7"
/// isso transbordaria. Um botao (44px, igual aos outros) resolve.
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  Future<void> _choose(BuildContext context) async {
    final picked = await showDialog<AppLanguage>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF252525),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(t('lang.label'), style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLanguage.values.map((lang) {
            final selected = lang == appLanguage.value;
            return Material(
              color: selected ? Colors.white12 : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => Navigator.of(ctx).pop(lang),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 300,
                  constraints: const BoxConstraints(minHeight: 60),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      FlagIcon(language: lang, width: 34),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          languageNames[lang] ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (selected)
                        const Icon(Icons.check_circle_rounded, color: Color(0xFFFF6B35), size: 22),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );

    if (picked != null) appLanguage.value = picked;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, current, _) => InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _choose(context),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF252525),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF333333)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FlagIcon(language: current),
              const SizedBox(width: 6),
              const Icon(Icons.expand_more_rounded, size: 16, color: Color(0xFFA8A8A8)),
            ],
          ),
        ),
      ),
    );
  }
}

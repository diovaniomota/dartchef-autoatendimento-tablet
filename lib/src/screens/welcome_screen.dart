import 'package:flutter/material.dart';

import '../core/app_language.dart';
import '../models/home_block.dart';
import '../core/app_theme.dart';
import '../widgets/flag_icon.dart';

/// Tela de espera do tablet.
///
/// E o que a mesa mostra quando ninguem esta sentado: marca do restaurante,
/// escolha de idioma e um botao grande para comecar. O tablet volta para ca
/// sozinho quando a mesa e paga ou cancelada no PDV, e tambem depois de um
/// tempo sem ninguem tocar.
///
/// Por que a escolha de idioma fica AQUI e nao so na barra de cima: o turista
/// precisa entender a tela antes de saber onde procurar o seletor. Trocando
/// antes de entrar, o cardapio inteiro ja abre no idioma dele.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.restaurantName,
    required this.logoUrl,
    required this.backgroundUrl,
    required this.primaryColor,
    required this.onStart,
    required this.onSettings,
    this.conectado = true,
    this.blocks = const [],
  });

  final String restaurantName;
  final String logoUrl;
  final String backgroundUrl;

  /// Cor do botao vinda do cadastro, em hex. Vazia ou invalida cai no laranja
  /// do app.
  final String primaryColor;

  final VoidCallback onStart;

  /// Tela montada pelo restaurante no DartChef, em blocos empilhados.
  ///
  /// Vazia = arranjo padrao do app. Restaurante que nunca abriu o editor, ou
  /// servidor em versao anterior, continua vendo exatamente a tela de sempre.
  final List<HomeBlock> blocks;

  /// Acesso as configuracoes do tablet, protegido por PIN.
  ///
  /// Precisa estar AQUI: esta tela cobre o app inteiro enquanto a mesa esta
  /// livre, e sem a engrenagem nao haveria como parear o tablet ou trocar a
  /// mesa — o unico caminho ficava atras de um cardapio que ainda nao carregou.
  final VoidCallback onSettings;

  /// Tablet pareado e com cardapio carregado.
  ///
  /// Desconectado, o botao de comecar leva a uma tela de erro — o cliente toca,
  /// nao acontece nada de util e ele chama o garcom. Melhor a tela dizer o que
  /// falta e oferecer o caminho, ainda que seja o funcionario quem resolve.
  final bool conectado;

  Color get _accent {
    final hex = primaryColor.replaceAll('#', '').trim();
    if (hex.length != 6) return AppTheme.accent;
    final valor = int.tryParse(hex, radix: 16);
    if (valor == null) return AppTheme.accent;
    return Color(0xFF000000 | valor);
  }

  @override
  Widget build(BuildContext context) {
    // Escuta o idioma para as tres opcoes redesenharem a marcacao na hora do
    // toque, sem depender de rebuild da raiz.
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, idioma, _) => Scaffold(
        backgroundColor: AppTheme.background,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (backgroundUrl.isNotEmpty)
              Image.network(
                backgroundUrl,
                fit: BoxFit.cover,
                // Foto cadastrada que nao carregue nao pode deixar a tela
                // branca: cai no fundo escuro, que continua legivel.
                errorBuilder: (_, _, _) => const ColoredBox(color: AppTheme.background),
              ),

            // Veu escuro: sem ele o texto branco desaparece nas partes claras
            // da foto, e foto de comida tem muito ponto claro.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xCC000000), Color(0xE6000000)],
                ),
              ),
              child: SizedBox.expand(),
            ),

            SafeArea(
              child: LayoutBuilder(
                builder: (context, restricoes) {
                  // Tablet de 7" em pe sobra pouca altura: rolagem evita que o
                  // botao de comecar fique fora da tela.
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: restricoes.maxHeight - 40),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: blocks.isEmpty
                                ? _colunaPadrao(idioma)
                                : _colunaDeBlocos(idioma),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // POR ULTIMO no Stack, de proposito.
            //
            // Antes vinha antes da area de rolagem, e no Flutter o filho
            // declarado depois pinta por cima e fica com o toque: a rolagem
            // cobre a tela inteira, entao a engrenagem aparecia mas nao
            // respondia a nada.
            Positioned(
              left: 4,
              bottom: 4,
              child: SafeArea(
                child: IconButton(
                  onPressed: onSettings,
                  tooltip: t('settings.tooltip'),
                  iconSize: 22,
                  constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
                  icon: const Icon(Icons.settings, color: Colors.white38),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Arranjo de sempre, para quem nunca montou a tela.
  List<Widget> _colunaPadrao(AppLanguage idioma) => [
        _marca(),
        const SizedBox(height: 28),
        Text(
          t('welcome.headline'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 16),
        _escolhaDeIdioma(idioma),
        const SizedBox(height: 22),
        if (conectado) _botaoComecar() else _avisoDesconectado(),
      ];

  /// Arranjo montado no DartChef.
  ///
  /// As alturas seguem a mesma tabela que o editor usa para avisar "nao cabe":
  /// se divergirem, a cliente aprova uma tela que corta no aparelho.
  List<Widget> _colunaDeBlocos(AppLanguage idioma) {
    final widgets = <Widget>[];
    for (final bloco in blocks) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 12));
      widgets.add(switch (bloco.type) {
        'logo' => _marca(
            altura: switch (bloco.tamanho) {
              'pequeno' => 60.0,
              'grande' => 130.0,
              _ => 90.0,
            },
          ),
        'texto' => Text(
            bloco.texto,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(bloco.corTexto),
              fontSize: switch (bloco.tamanho) {
                'pequeno' => 18.0,
                'grande' => 32.0,
                'titulo' => 44.0,
                _ => 24.0,
              },
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        'imagem' => ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              bloco.url,
              height: switch (bloco.tamanho) {
                'pequeno' => 90.0,
                'grande' => 200.0,
                _ => 140.0,
              },
              fit: BoxFit.contain,
              // Imagem que nao carrega vira nada, e nao um icone de erro: a
              // tela de espera e vitrine, e um quadrado quebrado no meio dela e
              // pior que um espaco vazio.
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        'idiomas' => _escolhaDeIdioma(idioma),
        'botao' => conectado ? _botaoComecar(rotulo: bloco.texto) : _avisoDesconectado(),
        'espaco' => SizedBox(
            height: switch (bloco.tamanho) {
              'pequeno' => 12.0,
              'grande' => 56.0,
              _ => 28.0,
            },
          ),
        _ => const SizedBox.shrink(),
      });
    }
    return widgets;
  }

  Widget _escolhaDeIdioma(AppLanguage idioma) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final opcao in AppLanguage.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _BotaoIdioma(
                language: opcao,
                selecionado: opcao == idioma,
                accent: _accent,
                onTap: () => appLanguage.value = opcao,
              ),
            ),
        ],
      );

  Widget _marca({double altura = 150}) {
    if (logoUrl.isNotEmpty) {
      return Image.network(
        logoUrl,
        height: altura,
        fit: BoxFit.contain,
        // Sem logo cadastrada, ou com endereco quebrado, o nome do restaurante
        // ocupa o lugar — a tela nunca fica sem identificacao.
        errorBuilder: (_, _, _) => _nomeEmTexto(),
      );
    }
    return _nomeEmTexto();
  }

  Widget _nomeEmTexto() => Text(
        restaurantName.toUpperCase(),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          height: 1.15,
        ),
      );

  Widget _avisoDesconectado() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.danger),
        ),
        child: Column(
          children: [
            const Icon(Icons.wifi_off, color: AppTheme.danger, size: 34),
            const SizedBox(height: 10),
            Text(
              t('welcome.offline'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t('welcome.offlineHelp'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13.5, height: 1.35),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 62,
              child: FilledButton.icon(
                onPressed: onSettings,
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.settings, size: 22),
                label: Text(
                  t('welcome.connect'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                ),
              ),
            ),
          ],
        ),
      );

  /// [rotulo] vem do bloco quando o restaurante escreveu o proprio texto.
  /// Vazio cai na traducao do app, para nao existir botao sem palavra nenhuma.
  Widget _botaoComecar({String rotulo = ''}) => SizedBox(
        width: double.infinity,
        // 76 de altura: e o alvo que o cliente acerta de pe, sem mirar.
        height: 76,
        child: FilledButton(
          onPressed: onStart,
          style: FilledButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  rotulo.trim().isEmpty ? t('welcome.start') : rotulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.touch_app, size: 26),
            ],
          ),
        ),
      );
}

class _BotaoIdioma extends StatelessWidget {
  const _BotaoIdioma({
    required this.language,
    required this.selecionado,
    required this.accent,
    required this.onTap,
  });

  final AppLanguage language;
  final bool selecionado;
  final Color accent;
  final VoidCallback onTap;

  /// Nome no PROPRIO idioma, sempre. "English" traduzido para "Inglês" nao
  /// ajuda quem nao le portugues — que e justamente quem usa este botao.
  String get _nome => switch (language) {
        AppLanguage.pt => 'PORTUGUÊS',
        AppLanguage.en => 'ENGLISH',
        AppLanguage.es => 'ESPAÑOL',
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selecionado ? accent.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selecionado ? accent : Colors.white.withValues(alpha: 0.18),
              width: selecionado ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              FlagIcon(language: language, width: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _nome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              if (selecionado) Icon(Icons.check_circle, color: accent, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/app_language.dart';
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
  });

  final String restaurantName;
  final String logoUrl;
  final String backgroundUrl;

  /// Cor do botao vinda do cadastro, em hex. Vazia ou invalida cai no laranja
  /// do app.
  final String primaryColor;

  final VoidCallback onStart;

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
                            children: [
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
                              const SizedBox(height: 22),
                              _botaoComecar(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _marca() {
    if (logoUrl.isNotEmpty) {
      return Image.network(
        logoUrl,
        height: 150,
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

  Widget _botaoComecar() => SizedBox(
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
                  t('welcome.start'),
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

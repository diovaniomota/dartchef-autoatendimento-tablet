import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
    this.tableCode = '',
    this.tableName = '',
  });

  final String restaurantName;
  final String logoUrl;
  final String backgroundUrl;
  final String tableCode;
  final String tableName;

  /// Cor do botao vinda do cadastro, em hex. Vazia ou invalida cai no laranja
  /// do app.
  final String primaryColor;

  final VoidCallback onStart;

  /// Tela montada pelo restaurante no DartChef.
  ///
  /// Vazia = arranjo padrao do app. Com x/y/w/h = desenha cada widget no ponto
  /// em que foi solto no editor. Sem posicao (cadastro antigo) = empilha.
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

            if (blocks.any((bloco) => bloco.temPosicao))
              // Canvas 1024x600, o mesmo do editor. FittedBox cobre aparelho
              // com DPI diferente sem deslocar o que a cliente posicionou.
              Center(child: _canvasLivre(idioma))
            else
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

  /// Arranjo livre: cada widget no ponto em que foi solto no DartChef.
  Widget _canvasLivre(AppLanguage idioma) {
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 1024,
        height: 600,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            for (final bloco in blocks)
              if (bloco.temPosicao)
                Positioned(
                  left: bloco.x,
                  top: bloco.y,
                  width: bloco.w,
                  height: bloco.h,
                  child: _widgetDoBloco(bloco, idioma, preencher: true),
                ),
          ],
        ),
      ),
    );
  }

  /// Arranjo montado no DartChef, cadastro antigo sem x/y.
  List<Widget> _colunaDeBlocos(AppLanguage idioma) {
    final widgets = <Widget>[];
    for (final bloco in blocks) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 12));
      widgets.add(_widgetDoBloco(bloco, idioma));
    }
    return widgets;
  }

  Widget _widgetDoBloco(HomeBlock bloco, AppLanguage idioma, {bool preencher = false}) {
    return switch (bloco.type) {
      'logo' => () {
          final marca = _marca(
            altura: bloco.h ??
                switch (bloco.tamanho) {
                  'pequeno' => 60.0,
                  'grande' => 130.0,
                  _ => 90.0,
                },
          );
          if (!preencher) return marca;
          return FittedBox(fit: BoxFit.contain, child: marca);
        }(),
      'texto' => Align(
          alignment: switch (bloco.alinhamento) {
            'esquerda' => Alignment.centerLeft,
            'direita' => Alignment.centerRight,
            _ => Alignment.center,
          },
          child: Text(
            bloco.texto,
            textAlign: switch (bloco.alinhamento) {
              'esquerda' => TextAlign.left,
              'direita' => TextAlign.right,
              _ => TextAlign.center,
            },
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
        ),
      'imagem' => bloco.url.isEmpty
          ? const SizedBox.shrink()
          : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                bloco.url,
                width: preencher ? double.infinity : null,
                height: preencher
                    ? double.infinity
                    : switch (bloco.tamanho) {
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
      'idiomas' => preencher
          ? FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(width: 400, height: 194, child: _escolhaDeIdioma(idioma)),
            )
          : _escolhaDeIdioma(idioma),
      'botao' => conectado
          ? _botaoComecar(
              rotulo: bloco.texto,
              preencher: preencher,
              cor: bloco.corOpicional == null ? null : Color(bloco.corOpicional!),
            )
          : (preencher
              ? FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(width: 380, height: 180, child: _avisoDesconectado()),
                )
              : _avisoDesconectado()),
      'espaco' => SizedBox(
          height: bloco.h ??
              switch (bloco.tamanho) {
                'pequeno' => 12.0,
                'grande' => 56.0,
                _ => 28.0,
              },
        ),
      'painel' => DecoratedBox(
          decoration: BoxDecoration(
            color: Color(bloco.corOpicional ?? 0xFF111827).withValues(alpha: bloco.opacidade),
            borderRadius: BorderRadius.circular(bloco.raio),
          ),
          child: const SizedBox.expand(),
        ),
      'linha' => DecoratedBox(
          decoration: BoxDecoration(
            color: Color(bloco.corOpicional ?? 0xFFFFFFFF),
            borderRadius: BorderRadius.circular(99),
          ),
          child: const SizedBox.expand(),
        ),
      'relogio' => _RelogioVivo(
          formato: bloco.formato,
          cor: Color(bloco.corTexto),
          tamanho: bloco.tamanho,
        ),
      'data' => _textoCaixa(
          _dataDeHoje(bloco.formato),
          cor: Color(bloco.corTexto),
          tamanho: 16,
          weight: FontWeight.w700,
        ),
      'mesa' => _textoCaixa(
          '${bloco.prefixo} ${_rotuloMesa()}',
          cor: Color(bloco.corTexto),
          tamanho: switch (bloco.tamanho) {
            'pequeno' => 18.0,
            'grande' => 32.0,
            'titulo' => 44.0,
            _ => 24.0,
          },
        ),
      'qr' => _qrDaMesa(bloco),
      'promo' => _cardPromo(bloco),
      'selo' => _selo(bloco),
      'icone' => Icon(
          _iconeDe(bloco.icone),
          color: Color(bloco.corTexto),
          size: 48,
        ),
      'wifi' => _wifi(bloco),
      'social' => _social(bloco),
      'nome' => _textoCaixa(
          restaurantName.toUpperCase(),
          cor: Color(bloco.corTexto),
          tamanho: switch (bloco.tamanho) {
            'pequeno' => 18.0,
            'grande' => 32.0,
            'titulo' => 44.0,
            _ => 24.0,
          },
          align: switch (bloco.alinhamento) {
            'esquerda' => TextAlign.left,
            'direita' => TextAlign.right,
            _ => TextAlign.center,
          },
        ),
      _ => const SizedBox.shrink(),
    };
  }

  String _rotuloMesa() {
    final nome = tableName.trim();
    if (nome.isNotEmpty) return nome.replaceFirst(RegExp(r'^mesa\s+', caseSensitive: false), '');
    final codigo = tableCode.trim();
    return codigo.isEmpty ? '—' : codigo;
  }

  String _dataDeHoje(String formato) {
    final agora = DateTime.now();
    if (formato == 'longo') {
      const dias = ['segunda-feira', 'terça-feira', 'quarta-feira', 'quinta-feira', 'sexta-feira', 'sábado', 'domingo'];
      const meses = ['janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'];
      final dia = dias[(agora.weekday + 6) % 7];
      return '$dia, ${agora.day} de ${meses[agora.month - 1]}';
    }
    final d = agora.day.toString().padLeft(2, '0');
    final m = agora.month.toString().padLeft(2, '0');
    return '$d/$m/${agora.year}';
  }

  Widget _textoCaixa(String texto, {required Color cor, required double tamanho, FontWeight weight = FontWeight.w900, TextAlign align = TextAlign.center}) {
    return Align(
      alignment: switch (align) {
        TextAlign.left => Alignment.centerLeft,
        TextAlign.right => Alignment.centerRight,
        _ => Alignment.center,
      },
      child: Text(
        texto,
        textAlign: align,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: cor, fontSize: tamanho, fontWeight: weight, height: 1.15),
      ),
    );
  }

  Widget _qrDaMesa(HomeBlock bloco) {
    final valor = bloco.alvo == 'url' && bloco.url.trim().isNotEmpty
        ? bloco.url.trim()
        : 'MESA ${_rotuloMesa()}';
    final fg = Color(bloco.corOpicional ?? 0xFF111827);
    final bg = Color(bloco.props['fundo'] == null ? 0xFFFFFFFF : bloco.corFundo);
    return DecoratedBox(
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: QrImageView(
                data: valor,
                backgroundColor: bg,
                eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: fg),
                dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: fg),
              ),
            ),
            if (bloco.mostrarRotulo)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Mesa ${_rotuloMesa()}',
                  style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cardPromo(HomeBlock bloco) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color(bloco.corFundo),
        borderRadius: BorderRadius.circular(bloco.raio),
        border: Border(left: BorderSide(color: Color(bloco.corOpicional ?? 0xFFEA580C), width: 5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              bloco.texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(bloco.corOpicional ?? 0xFFEA580C),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            if (bloco.subtitulo.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  bloco.subtitulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, height: 1.2),
                ),
              ),
            if (bloco.preco.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  bloco.preco,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _selo(HomeBlock bloco) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color(bloco.corOpicional ?? 0xFFEA580C),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Center(
        child: Text(
          bloco.texto,
          style: TextStyle(
            color: Color(bloco.corSeloTexto),
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _wifi(HomeBlock bloco) {
    final cor = Color(bloco.corTexto);
    return Row(
      children: [
        Icon(Icons.wifi, color: cor, size: 26),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bloco.rede.trim().isEmpty ? 'Wi-Fi' : bloco.rede,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: cor, fontSize: 16, fontWeight: FontWeight.w800),
              ),
              if (bloco.senha.trim().isNotEmpty)
                Text('Senha: ${bloco.senha}', style: TextStyle(color: cor.withValues(alpha: 0.85), fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _social(HomeBlock bloco) {
    final cor = Color(bloco.corTexto);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(_iconeSocial(bloco.rede), color: cor, size: 22),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            bloco.texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: cor, fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  IconData _iconeDe(String id) => switch (id) {
        'coracao' => Icons.favorite,
        'talheres' => Icons.restaurant,
        'vinho' => Icons.wine_bar,
        'cafe' => Icons.local_cafe,
        'chef' => Icons.soup_kitchen,
        'fogo' => Icons.local_fire_department,
        'musica' => Icons.music_note,
        _ => Icons.star,
      };

  IconData _iconeSocial(String rede) => switch (rede) {
        'facebook' => Icons.facebook,
        'whatsapp' => Icons.chat,
        'tiktok' => Icons.music_note,
        _ => Icons.camera_alt,
      };

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
  /// [preencher] = ocupa o retangulo do editor; senao usa o tamanho fixo da
  /// tela padrao (alvo grande o bastante para acertar de pe).
  Widget _botaoComecar({String rotulo = '', bool preencher = false, Color? cor}) {
    final botao = FilledButton(
      onPressed: onStart,
      style: FilledButton.styleFrom(
        backgroundColor: cor ?? _accent,
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
    );
    if (preencher) return SizedBox.expand(child: botao);
    return SizedBox(width: double.infinity, height: 76, child: botao);
  }
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

/// Relogio ao vivo. Sem isto a hora ficaria congelada na abertura da tela.
class _RelogioVivo extends StatefulWidget {
  const _RelogioVivo({
    required this.formato,
    required this.cor,
    required this.tamanho,
  });

  final String formato;
  final Color cor;
  final String tamanho;

  @override
  State<_RelogioVivo> createState() => _RelogioVivoState();
}

class _RelogioVivoState extends State<_RelogioVivo> {
  late DateTime _agora;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _agora = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _agora = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _agora.hour;
    final m = _agora.minute.toString().padLeft(2, '0');
    final texto = widget.formato == '12h'
        ? '${h % 12 == 0 ? 12 : h % 12}:$m ${h < 12 ? 'AM' : 'PM'}'
        : '${h.toString().padLeft(2, '0')}:$m';
    final fonte = switch (widget.tamanho) {
      'pequeno' => 18.0,
      'grande' => 36.0,
      'titulo' => 48.0,
      _ => 28.0,
    };
    return Center(
      child: Text(
        texto,
        style: TextStyle(
          color: widget.cor,
          fontSize: fonte,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

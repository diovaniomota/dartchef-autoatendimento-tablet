import '../core/app_language.dart';

/// Um bloco da tela de inicio, montado pelo restaurante no DartChef.
///
/// A tela de espera vem do servidor como widgets com posicao livre
/// (`x`, `y`, `w`, `h` em pixels de 1024x600). Layout antigo, so a ordem,
/// chega sem essas chaves — a tela cai no empilhado de sempre.
///
/// Cardapio sem `home_layout` (servidor antigo, ou restaurante que nunca abriu
/// o editor) devolve lista vazia, e a tela cai no arranjo padrao. Nenhuma mesa
/// pode ficar com a tela em branco por causa de cadastro.
class HomeBlock {
  const HomeBlock({
    required this.type,
    this.props = const {},
    this.x,
    this.y,
    this.w,
    this.h,
  });

  final String type;
  final Map<String, dynamic> props;
  final double? x;
  final double? y;
  final double? w;
  final double? h;

  static const tiposConhecidos = {
    'logo',
    'texto',
    'imagem',
    'idiomas',
    'botao',
    'espaco',
    'painel',
    'linha',
    'relogio',
    'data',
    'mesa',
    'qr',
    'promo',
    'selo',
    'icone',
    'wifi',
    'social',
    'nome',
  };

  static double? _num(dynamic valor) {
    if (valor is num) return valor.toDouble();
    return num.tryParse('$valor')?.toDouble();
  }

  factory HomeBlock.fromJson(Map<String, dynamic> json) => HomeBlock(
        type: '${json['type'] ?? ''}',
        props: (json['props'] as Map?)?.map((k, v) => MapEntry('$k', v)) ?? const {},
        x: _num(json['x']),
        y: _num(json['y']),
        w: _num(json['w']),
        h: _num(json['h']),
      );

  /// Le a lista inteira, descartando o que este app nao sabe desenhar.
  ///
  /// Bloco de um tipo que so existe em versao mais nova do DartChef nao pode
  /// derrubar a tela: some da tela e o resto continua.
  static List<HomeBlock> listaFromJson(dynamic bruto) {
    if (bruto is! List) return const [];
    return bruto
        .whereType<Map>()
        .map((item) => HomeBlock.fromJson(item.map((k, v) => MapEntry('$k', v))))
        .where((bloco) => tiposConhecidos.contains(bloco.type))
        .toList();
  }

  /// Tem retangulo proprio: o tablet desenha neste ponto, nao na pilha.
  bool get temPosicao => x != null && y != null && w != null && h != null;

  String get tamanho => '${props['tamanho'] ?? 'medio'}';
  String get url => '${props['url'] ?? ''}';
  String get alinhamento => '${props['alinhamento'] ?? 'centro'}';
  String get formato => '${props['formato'] ?? ''}';
  String get alvo => '${props['alvo'] ?? 'mesa'}';
  String get icone => '${props['icone'] ?? 'estrela'}';
  String get rede => '${props['rede'] ?? ''}';
  String get senha => '${props['senha'] ?? ''}';
  String get preco => '${props['preco'] ?? ''}';
  bool get mostrarRotulo => props['rotulo'] != false;

  /// Texto no idioma da tela, caindo no portugues quando falta a traducao —
  /// mesma regra do cardapio. Cadastro pela metade nunca deixa texto vazio.
  String campo(String chave) {
    final padrao = '${props[chave] ?? ''}';
    final sufixo = switch (appLanguage.value) {
      AppLanguage.pt => null,
      AppLanguage.en => 'en',
      AppLanguage.es => 'es',
    };
    if (sufixo == null) return padrao;
    final traduzido = '${props['${chave}_$sufixo'] ?? ''}'.trim();
    return traduzido.isEmpty ? padrao : traduzido;
  }

  String get texto => campo('texto');
  String get subtitulo => campo('subtitulo');
  String get prefixo {
    final valor = campo('prefixo').trim();
    return valor.isEmpty ? 'Mesa' : valor;
  }

  /// Cor do texto em `0xAARRGGBB`. Valor invalido cai no branco, que e legivel
  /// sobre a vela escura do fundo.
  int get corTexto {
    final hex = '${props['cor'] ?? ''}'.replaceAll('#', '').trim();
    if (hex.length != 6) return 0xFFFFFFFF;
    final valor = int.tryParse(hex, radix: 16);
    return valor == null ? 0xFFFFFFFF : 0xFF000000 | valor;
  }

  int? _corDe(String chave) {
    final hex = '${props[chave] ?? ''}'.replaceAll('#', '').trim();
    if (hex.length != 6) return null;
    final valor = int.tryParse(hex, radix: 16);
    return valor == null ? null : 0xFF000000 | valor;
  }

  /// Cor propria do botao/painel/linha. Null = usa a cor da marca.
  int? get corOpicional => _corDe('cor');

  int get corFundo => _corDe('corFundo') ?? _corDe('fundo') ?? 0xFF111827;

  int get corSeloTexto => _corDe('corTexto') ?? 0xFFFFFFFF;

  double get opacidade {
    final valor = _num(props['opacidade']) ?? 55;
    return (valor.clamp(0, 100)) / 100;
  }

  double get raio => _num(props['raio']) ?? 0;

  double get padding => _num(props['padding']) ?? 0;
  double get sombra => _num(props['sombra']) ?? 0;
  double get opacidadeWidget => ((_num(props['opacidadeWidget']) ?? 100).clamp(0, 100)) / 100;
  double get espessuraBorda => _num(props['espessuraBorda']) ?? 0;
  double get opacidadeFundo => ((_num(props['opacidadeFundo']) ?? 0).clamp(0, 100)) / 100;
  double get espacoLetras => _num(props['espacoLetras']) ?? 0;
  double? get fontePx => _num(props['fontePx']);

  int? get corBorda => _corDe('corBorda');
  int? get corFundoCaixa => _corDe('corFundoCaixa');

  String get fonte => '${props['fonte'] ?? 'sans'}';
  String get peso => '${props['peso'] ?? 'preto'}';
  String get alinhamentoV => '${props['alinhamentoV'] ?? 'centro'}';
  String get ajuste => '${props['ajuste'] ?? 'conter'}';
  String get formatoBotao => '${props['formatoBotao'] ?? 'pilula'}';
  String get direcao => '${props['direcao'] ?? 'vertical'}';

  bool get italico => props['italico'] == true;
  bool get maiusculas => props['maiusculas'] == true;
  bool get sombraTexto => props['sombraTexto'] == true;
  bool get segundos => props['segundos'] == true;
  bool get mostrarIcone => props['mostrarIcone'] != false;
  bool get fundoCirculo => props['fundoCirculo'] == true;

  double fonteResolvida(double fallback) => fontePx ?? fallback;
}

import '../core/app_language.dart';

/// Um bloco da tela de inicio, montado pelo restaurante no DartChef.
///
/// A tela de espera era fixa no app. Agora ela vem do servidor como uma lista
/// de blocos empilhados — logo, texto, imagem, idiomas, botao, espaco.
///
/// Cardapio sem `home_layout` (servidor antigo, ou restaurante que nunca abriu
/// o editor) devolve lista vazia, e a tela cai no arranjo padrao. Nenhuma mesa
/// pode ficar com a tela em branco por causa de cadastro.
class HomeBlock {
  const HomeBlock({required this.type, this.props = const {}});

  final String type;
  final Map<String, dynamic> props;

  static const tiposConhecidos = {'logo', 'texto', 'imagem', 'idiomas', 'botao', 'espaco'};

  factory HomeBlock.fromJson(Map<String, dynamic> json) => HomeBlock(
        type: '${json['type'] ?? ''}',
        props: (json['props'] as Map?)?.map((k, v) => MapEntry('$k', v)) ?? const {},
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

  String get tamanho => '${props['tamanho'] ?? 'medio'}';
  String get url => '${props['url'] ?? ''}';

  /// Texto no idioma da tela, caindo no portugues quando falta a traducao —
  /// mesma regra do cardapio. Cadastro pela metade nunca deixa texto vazio.
  String get texto {
    final padrao = '${props['texto'] ?? ''}';
    final sufixo = switch (appLanguage.value) {
      AppLanguage.pt => null,
      AppLanguage.en => 'en',
      AppLanguage.es => 'es',
    };
    if (sufixo == null) return padrao;
    final traduzido = '${props['texto_$sufixo'] ?? ''}'.trim();
    return traduzido.isEmpty ? padrao : traduzido;
  }

  /// Cor do texto em `0xAARRGGBB`. Valor invalido cai no branco, que e legivel
  /// sobre a vela escura do fundo.
  int get corTexto {
    final hex = '${props['cor'] ?? ''}'.replaceAll('#', '').trim();
    if (hex.length != 6) return 0xFFFFFFFF;
    final valor = int.tryParse(hex, radix: 16);
    return valor == null ? 0xFFFFFFFF : 0xFF000000 | valor;
  }
}

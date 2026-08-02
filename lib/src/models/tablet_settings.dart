class TabletSettings {
  const TabletSettings({
    required this.apiBaseUrl,
    required this.organizationId,
    required this.tableCode,
    this.organizationName = '',
  });

  final String apiBaseUrl;
  final String organizationId;
  final String tableCode;

  /// Nome da empresa, so para exibicao. Chega no QR de pareamento e serve para
  /// o operador identificar a QUAL estabelecimento o tablet esta vinculado —
  /// um tablet configurado numa empresa e entregue em outra apenas "nao
  /// conectava", sem nada indicando o motivo.
  ///
  /// Opcional de proposito: tablets pareados antes desta versao nao tem o
  /// campo salvo e precisam continuar funcionando sem reparear.
  final String organizationName;

  /// organizationName NAO entra aqui: e apenas informativo, e exigi-lo
  /// invalidaria o pareamento de todos os tablets ja configurados.
  bool get isComplete =>
      apiBaseUrl.trim().isNotEmpty &&
      organizationId.trim().isNotEmpty &&
      tableCode.trim().isNotEmpty;

  TabletSettings copyWith({
    String? apiBaseUrl,
    String? organizationId,
    String? tableCode,
    String? organizationName,
  }) {
    return TabletSettings(
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      organizationId: organizationId ?? this.organizationId,
      tableCode: tableCode ?? this.tableCode,
      organizationName: organizationName ?? this.organizationName,
    );
  }
}

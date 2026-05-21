class TabletSettings {
  const TabletSettings({
    required this.apiBaseUrl,
    required this.organizationId,
    required this.tableCode,
  });

  final String apiBaseUrl;
  final String organizationId;
  final String tableCode;

  bool get isComplete =>
      apiBaseUrl.trim().isNotEmpty &&
      organizationId.trim().isNotEmpty &&
      tableCode.trim().isNotEmpty;

  TabletSettings copyWith({
    String? apiBaseUrl,
    String? organizationId,
    String? tableCode,
  }) {
    return TabletSettings(
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      organizationId: organizationId ?? this.organizationId,
      tableCode: tableCode ?? this.tableCode,
    );
  }
}

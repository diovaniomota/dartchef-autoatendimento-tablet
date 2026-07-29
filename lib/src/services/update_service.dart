import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class UpdateInfo {
  const UpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    this.downloadUrl,
    this.releaseNotes,
  });

  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String? downloadUrl;
  final String? releaseNotes;
}

class UpdateException implements Exception {
  const UpdateException(this.message);
  final String message;
  @override
  String toString() => message;
}

// Atualizacao dentro do proprio app, publicada como GitHub Release (mesmo
// esquema do dartchef/dartwork, so que aqui o "instalador" e' o proprio
// APK - o Android exige confirmacao manual do usuario pra instalar fora da
// Play Store, entao nao da pra ser 100% silencioso como no desktop.
class UpdateService {
  static const _releasesApiUrl =
      'https://api.github.com/repos/diovaniomota/dartchef-autoatendimento-tablet-releases/releases/latest';

  Future<UpdateInfo> checkForUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    final response = await http
        .get(Uri.parse(_releasesApiUrl), headers: {'Accept': 'application/vnd.github+json'})
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 404) {
      // Nenhum release publicado ainda no repo.
      return UpdateInfo(hasUpdate: false, currentVersion: currentVersion, latestVersion: currentVersion);
    }
    if (response.statusCode >= 400) {
      throw UpdateException('Não foi possível verificar atualizações (código ${response.statusCode}).');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final tagName = (payload['tag_name'] as String? ?? '').trim();
    final latestVersion = tagName.replaceFirst(RegExp(r'^v'), '');
    final assets = (payload['assets'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final apkAsset = assets.where((asset) => (asset['name'] as String? ?? '').toLowerCase().endsWith('.apk')).firstOrNull;
    final downloadUrl = apkAsset?['browser_download_url'] as String?;

    if (latestVersion.isEmpty || downloadUrl == null) {
      return UpdateInfo(hasUpdate: false, currentVersion: currentVersion, latestVersion: currentVersion);
    }

    return UpdateInfo(
      hasUpdate: _isNewer(latestVersion, currentVersion),
      currentVersion: currentVersion,
      latestVersion: latestVersion,
      downloadUrl: downloadUrl,
      releaseNotes: (payload['body'] as String?)?.trim(),
    );
  }

  bool _isNewer(String latest, String current) {
    List<int> parts(String v) =>
        v.split('.').map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0).toList();
    final a = parts(latest);
    final b = parts(current);
    final len = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < len; i++) {
      final av = i < a.length ? a[i] : 0;
      final bv = i < b.length ? b[i] : 0;
      if (av != bv) return av > bv;
    }
    return false;
  }

  // Baixa o APK em streaming (arquivo pode ter ~200MB, nao da pra bufferizar
  // tudo na memoria de um tablet de entrada) e abre o instalador do sistema.
  //
  // beforeOpenInstaller roda depois do download e ANTES de abrir o
  // instalador: e' onde o app sai do modo quiosque. Com o Screen Pinning
  // ativo o Android bloqueia outras telas de virem pra frente, entao o
  // instalador nao apareceria.
  Future<void> downloadAndInstall(
    String downloadUrl, {
    void Function(double progress)? onProgress,
    Future<void> Function()? beforeOpenInstaller,
  }) async {
    final client = http.Client();
    try {
      final response = await client.send(http.Request('GET', Uri.parse(downloadUrl)));

      if (response.statusCode >= 400) {
        throw UpdateException('Falha ao baixar a atualização (código ${response.statusCode}).');
      }

      final totalBytes = response.contentLength ?? 0;
      var receivedBytes = 0;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/dartfood-mesa-update.apk');
      final sink = file.openWrite();

      try {
        await for (final chunk in response.stream) {
          receivedBytes += chunk.length;
          sink.add(chunk);
          if (totalBytes > 0) onProgress?.call(receivedBytes / totalBytes);
        }
      } finally {
        await sink.close();
      }

      if (beforeOpenInstaller != null) {
        await beforeOpenInstaller();
      }

      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        throw UpdateException(
          result.message.isNotEmpty ? result.message : 'Não foi possível abrir o instalador do Android.',
        );
      }
    } finally {
      client.close();
    }
  }
}

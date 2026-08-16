import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
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

/// ZIP/APK comeca com "PK". HTML do GitHub (login, 404) comeca com "<".
bool arquivoPareceApk(Uint8List bytes) {
  return bytes.length >= 4 && bytes[0] == 0x50 && bytes[1] == 0x4b;
}

bool versaoEhMaisNova(String latest, String current) {
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

// Atualizacao dentro do proprio app, publicada como GitHub Release.
// O Android exige confirmacao no instalador; nao da pra ser silencioso.
class UpdateService {
  static const _releasesApiUrl =
      'https://api.github.com/repos/diovaniomota/dartchef-autoatendimento-tablet-releases/releases/latest';
  static const _channel = MethodChannel('br.com.dartsoft.dartchef/kiosk');
  static const _githubHeaders = {
    'Accept': 'application/vnd.github+json',
    'User-Agent': 'DartFood-Mesa',
  };

  Future<UpdateInfo> checkForUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    final response = await http
        .get(Uri.parse(_releasesApiUrl), headers: _githubHeaders)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 404) {
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
      hasUpdate: versaoEhMaisNova(latestVersion, currentVersion),
      currentVersion: currentVersion,
      latestVersion: latestVersion,
      downloadUrl: downloadUrl,
      releaseNotes: (payload['body'] as String?)?.trim(),
    );
  }

  Future<bool> canInstallApks() async {
    if (kIsWeb) return false;
    try {
      return await _channel.invokeMethod<bool>('canInstallApks') ?? false;
    } catch (_) {
      return true;
    }
  }

  Future<void> requestInstallPermission() async {
    if (kIsWeb) return;
    await _channel.invokeMethod('requestInstallPermission');
  }

  // Baixa o APK em streaming e abre o instalador nativo.
  //
  // NAO fecha o app depois: nas versoes 0.2.14–0.2.19 o SystemNavigator.pop
  // matava o instalador junto, e a cliente ficava na versao antiga.
  Future<void> downloadAndInstall(
    String downloadUrl, {
    void Function(double progress)? onProgress,
    Future<void> Function()? beforeOpenInstaller,
  }) async {
    if (kIsWeb) {
      throw const UpdateException(
        'Atualizar o app só funciona no tablet. No navegador o app roda apenas para teste.',
      );
    }

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(downloadUrl));
      request.headers.addAll({
        'User-Agent': 'DartFood-Mesa',
        'Accept': 'application/octet-stream',
      });
      final response = await client.send(request);

      if (response.statusCode >= 400) {
        throw UpdateException('Falha ao baixar a atualização (código ${response.statusCode}).');
      }

      final totalBytes = response.contentLength ?? 0;
      var receivedBytes = 0;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/dartfood-mesa-update.apk');
      if (await file.exists()) await file.delete();
      final sink = file.openWrite();
      final header = <int>[];

      try {
        await for (final chunk in response.stream) {
          if (header.length < 4) {
            header.addAll(chunk);
          }
          receivedBytes += chunk.length;
          sink.add(chunk);
          if (totalBytes > 0) onProgress?.call(receivedBytes / totalBytes);
        }
      } finally {
        await sink.close();
      }

      if (receivedBytes < 1024 * 1024 || !arquivoPareceApk(Uint8List.fromList(header.take(4).toList()))) {
        await file.delete();
        throw const UpdateException(
          'O arquivo baixado não é o instalador. Confira a internet e tente de novo.',
        );
      }

      if (beforeOpenInstaller != null) {
        await beforeOpenInstaller();
      }

      try {
        await _channel.invokeMethod('installApk', {'path': file.path});
      } on PlatformException catch (e) {
        throw UpdateException(e.message?.trim().isNotEmpty == true
            ? e.message!
            : 'Não foi possível abrir o instalador do Android.');
      }
    } finally {
      client.close();
    }
  }
}

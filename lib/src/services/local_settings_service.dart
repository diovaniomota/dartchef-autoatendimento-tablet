import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/tablet_settings.dart';

class LocalSettingsService {
  static const _apiBaseUrlKey = 'tablet.api_base_url';
  static const _organizationIdKey = 'tablet.organization_id';
  static const _tableCodeKey = 'tablet.table_code';
  static const _organizationNameKey = 'tablet.organization_name';

  Future<TabletSettings> load() async {
    final preferences = await SharedPreferences.getInstance();

    return TabletSettings(
      apiBaseUrl: preferences.getString(_apiBaseUrlKey) ??
          dotenv.env['API_BASE_URL'] ??
          'http://localhost:3002',
      organizationId: preferences.getString(_organizationIdKey) ??
          dotenv.env['DEFAULT_ORGANIZATION_ID'] ??
          '',
      tableCode: preferences.getString(_tableCodeKey) ??
          dotenv.env['DEFAULT_TABLE_CODE'] ??
          '01',
      // Tablets pareados antes desta versao nao tem a chave salva; string
      // vazia e tratada como "nao informado" e nao impede o funcionamento.
      organizationName: preferences.getString(_organizationNameKey) ?? '',
    );
  }

  Future<void> save(TabletSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_apiBaseUrlKey, settings.apiBaseUrl.trim());
    await preferences.setString(
      _organizationIdKey,
      settings.organizationId.trim(),
    );
    await preferences.setString(_tableCodeKey, settings.tableCode.trim());
    await preferences.setString(
      _organizationNameKey,
      settings.organizationName.trim(),
    );
  }
}

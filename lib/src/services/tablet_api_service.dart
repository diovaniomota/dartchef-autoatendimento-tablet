import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/cart_item.dart';
import '../models/table_menu.dart';
import '../models/tablet_settings.dart';

class TabletApiException implements Exception {
  const TabletApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TabletApiService {
  TabletApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // Sem timeout, um IP inalcancavel (ex: pareamento com um endereco de VPN
  // que nao responde) deixava a tela presa em "carregando" para sempre -
  // nem sucesso nem erro. Com o timeout, o usuario ve uma mensagem clara
  // em poucos segundos e pode tentar de novo ou reparear.
  static const _timeout = Duration(seconds: 10);

  Future<http.Response> _withTimeout(Future<http.Response> future) {
    return future.timeout(
      _timeout,
      onTimeout: () => throw const TabletApiException(
        'Não foi possível conectar ao PDV. Verifique se o computador está ligado, '
        'na mesma rede Wi-Fi, e repareie o tablet se o endereço tiver mudado.',
      ),
    );
  }

  String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  Future<TableMenu> fetchMenu(TabletSettings settings) async {
    final baseUrl = _normalizeBaseUrl(settings.apiBaseUrl);
    final uri = Uri.parse(
      '$baseUrl/api/public/menu?orgId=${Uri.encodeQueryComponent(settings.organizationId)}&tableCode=${Uri.encodeQueryComponent(settings.tableCode)}',
    );

    final response = await _withTimeout(_client.get(uri));
    final payload = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 400) {
      throw TabletApiException(
        payload['error']?.toString() ?? 'Nao foi possivel carregar o cardapio.',
      );
    }

    return TableMenu.fromJson(payload);
  }

  Future<int> submitOrder({
    required TabletSettings settings,
    required List<CartItem> items,
    required String customerName,
    required String notes,
  }) async {
    final baseUrl = _normalizeBaseUrl(settings.apiBaseUrl);
    final uri = Uri.parse('$baseUrl/api/public/orders');

    final response = await _withTimeout(_client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'orgId': settings.organizationId,
        'tableCode': settings.tableCode,
        'customerName': customerName.trim(),
        'notes': notes.trim(),
        'items': items
            .map((item) => {
                  'productId': item.product.id,
                  'quantity': item.quantity,
                })
            .toList(),
      }),
    ));

    final payload = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 400) {
      throw TabletApiException(
        payload['error']?.toString() ?? 'Nao foi possivel enviar o pedido.',
      );
    }

    final order = payload['order'] as Map<String, dynamic>? ?? {};
    return int.tryParse('${order['id'] ?? 0}') ?? 0;
  }

  /// Chama garçom, vallet ou pede a conta
  Future<void> callService({
    required TabletSettings settings,
    required String callType,
  }) async {
    final baseUrl = _normalizeBaseUrl(settings.apiBaseUrl);
    final uri = Uri.parse('$baseUrl/api/public/service-call');

    final response = await _withTimeout(_client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'orgId': settings.organizationId,
        'tableCode': settings.tableCode,
        'callType': callType,
      }),
    ));

    if (response.statusCode >= 400) {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      throw TabletApiException(
        payload['error']?.toString() ?? 'Nao foi possivel enviar a solicitacao.',
      );
    }
  }

  /// Busca histórico de pedidos da mesa
  Future<List<Map<String, dynamic>>> fetchOrderHistory(TabletSettings settings) async {
    final baseUrl = _normalizeBaseUrl(settings.apiBaseUrl);
    final uri = Uri.parse(
      '$baseUrl/api/public/orders/history?orgId=${Uri.encodeQueryComponent(settings.organizationId)}&tableCode=${Uri.encodeQueryComponent(settings.tableCode)}',
    );

    final response = await _withTimeout(_client.get(uri));
    final payload = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 400) {
      throw TabletApiException(
        payload['error']?.toString() ?? 'Nao foi possivel carregar os pedidos.',
      );
    }

    final orders = payload['orders'] as List<dynamic>? ?? [];
    return orders.cast<Map<String, dynamic>>();
  }
}

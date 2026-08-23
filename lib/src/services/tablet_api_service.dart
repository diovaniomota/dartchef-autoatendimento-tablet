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

  /// Resultado do envio: o que a tela de "pedido enviado" precisa mostrar.
  Future<SubmittedOrder> submitOrder({
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
        // Sem paymentMethod: o tablet nao pergunta mais como a mesa pretende
        // pagar. O campo continua opcional no servidor, que grava null quando
        // ele nao vem — quem registra o recebimento e o PDV.
        'items': items
            .map((item) => {
                  'productId': item.product.id,
                  'quantity': item.quantity,
                  // A API grava isto em restaurant_order_items.notes, que o PDV
                  // e a conferencia de conta ja exibem como "Obs:".
                  'notes': item.notes.trim(),
                  // So os IDs: nome e preco da variacao vem do banco no
                  // servidor. Mandar o preco daqui deixaria o tablet definir
                  // quanto a mesa paga.
                  'optionChoiceIds':
                      item.chosenOptions.map((o) => o.id).toList(),
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
    return SubmittedOrder.fromJson(order);
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

/// Pedido aceito pelo servidor.
class SubmittedOrder {
  const SubmittedOrder({
    required this.id,
    required this.numero,
  });

  final int id;

  /// Numero curto, o que o cliente le na tela e diz em voz alta. Vem do
  /// servidor para bater com o que a cozinha ve — nao e calculado aqui.
  final int numero;

  factory SubmittedOrder.fromJson(Map<String, dynamic> json) {
    final id = int.tryParse('${json['id'] ?? 0}') ?? 0;
    return SubmittedOrder(
      id: id,
      // Servidor em versao anterior nao manda numero: cai no id, que e o que
      // existia antes, em vez de mostrar zero na tela.
      numero: int.tryParse('${json['numero'] ?? ''}') ?? id,
    );
  }
}

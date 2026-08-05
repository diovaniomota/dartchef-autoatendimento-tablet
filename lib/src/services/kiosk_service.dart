import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Modo quiosque via Screen Pinning nativo do Android (Activity.startLockTask/
// stopLockTask). Sem isso, qualquer cliente podia apertar Voltar/Recentes e
// sair pra mexer no tablet livremente. Sem o dispositivo estar provisionado
// como Device Owner, o Android ainda permite "desafixar" segurando
// Voltar+Recentes ao mesmo tempo (gesto pouco conhecido do publico geral) -
// pra bloquear isso de vez, teria que configurar o tablet como Device Owner
// (passo manual, uma vez, direto no aparelho).
class KioskService {
  static const _channel = MethodChannel('br.com.dartsoft.dartchef/kiosk');

  Future<void> enterKiosk() async {
    // No navegador nao existe canal nativo, e chamar so gera excecao a cada
    // partida. Quiosque de verdade e no tablet; em Chrome o app roda para teste.
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('enterKiosk');
    } catch (_) {
      // Screen Pinning pode nao estar disponivel em todo aparelho/versao do
      // Android - o app continua funcionando normalmente sem o bloqueio.
    }
  }

  Future<void> exitKiosk() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('exitKiosk');
    } catch (_) {
      // Se falhar, o SystemNavigator.pop() logo em seguida ainda tenta fechar.
    }
  }
}

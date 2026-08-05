import 'package:flutter/material.dart';

import '../core/app_language.dart';
import '../core/app_theme.dart';

/// Confirmacao visual de que o pedido chegou na cozinha.
///
/// Existe porque a versao anterior avisava com um aviso flutuante de 2 segundos
/// e voltava ao cardapio. O cliente que olhou para o lado nao via nada e ficava
/// sem saber se o pedido foi ou nao — e chamava o garcom para perguntar, que era
/// justamente o que o tablet devia evitar.
///
/// O numero grande e o que ele diz em voz alta quando o garcom chega com a
/// bandeja: vem do servidor, o mesmo que a cozinha ve na tela dela.
class OrderSentScreen extends StatelessWidget {
  const OrderSentScreen({
    super.key,
    required this.numero,
    required this.minutosEstimados,
    required this.onFollow,
  });

  final int numero;
  final int minutosEstimados;

  /// Abre a lista de pedidos da mesa. Nao encerra a sessao: quem acabou de pedir
  /// costuma pedir mais.
  final VoidCallback onFollow;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, _, _) => Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.success, width: 4),
                      ),
                      child: const Icon(Icons.check, color: AppTheme.success, size: 60),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      t('sent.title'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      t('sent.yourNumber'),
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 15),
                    ),
                    Text(
                      '#$numero',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    if (minutosEstimados > 0) ...[
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.schedule, color: AppTheme.textMuted, size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              // "Aproximado" no texto de proposito: nao ha tempo
                              // por produto no cadastro, a estimativa e uma
                              // conta simples. Prometer minuto exato geraria
                              // reclamacao a cada pedido que atrasasse.
                              t2('sent.estimate', {'minutes': '$minutosEstimados'}),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 18),
                    Text(
                      t('sent.thanks'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 15),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: OutlinedButton.icon(
                        onPressed: onFollow,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
                        label: Text(
                          t('sent.follow'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

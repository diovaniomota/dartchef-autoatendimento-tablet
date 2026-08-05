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
    required this.onFollow,
    required this.onKeepOrdering,
  });

  final int numero;

  /// Abre a lista de pedidos da mesa. Nao encerra a sessao: quem acabou de pedir
  /// costuma pedir mais.
  final VoidCallback onFollow;

  /// Volta ao cardapio.
  ///
  /// Sem isto a tela era um beco sem saida: so dava para acompanhar o pedido, e
  /// quem queria pedir a sobremesa ficava preso e chamava o garcom — o oposto
  /// do que o tablet existe para fazer.
  final VoidCallback onKeepOrdering;

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
                    const SizedBox(height: 18),
                    Text(
                      t('sent.thanks'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 15),
                    ),
                    const SizedBox(height: 28),
                    // Continuar pedindo em destaque, acompanhar em segundo
                    // plano: a mesa que acabou de pedir a entrada quase sempre
                    // vai pedir bebida e sobremesa depois.
                    SizedBox(
                      width: double.infinity,
                      height: 66,
                      child: FilledButton.icon(
                        onPressed: onKeepOrdering,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.restaurant_menu, size: 22),
                        label: Text(
                          t('sent.keepOrdering'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
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

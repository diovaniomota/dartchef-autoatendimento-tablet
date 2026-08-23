import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'app.dart';

/// Executa um ajuste de plataforma sem deixar a falha derrubar a partida.
///
/// Tudo aqui e "seria bom ter", nao "sem isso nao funciona": orientacao, modo
/// imersivo e manter a tela ligada. No navegador varias dessas chamadas nao
/// existem, e uma excecao antes do runApp deixava a pagina EM BRANCO, sem
/// nenhuma pista do motivo — foi o que impediu de testar o app em Chrome.
Future<void> _tentar(String etapa, Future<void> Function() acao) async {
  try {
    await acao();
  } catch (erro) {
    debugPrint('[partida] $etapa indisponivel nesta plataforma: $erro');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Força landscape
  await _tentar('orientacao', () => SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]));

  // Modo imersivo — esconde barra de status e navegação do Android
  await _tentar(
    'modo imersivo',
    () => SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
  );

  // Mantém tela ligada indefinidamente
  await _tentar('tela sempre ligada', WakelockPlus.enable);

  // O .env traz os padroes de pareamento. Ausente ou ilegivel, o app abre na
  // tela de configuracao e os dados sao digitados a mao — melhor que nao abrir.
  await _tentar('.env', () => dotenv.load(fileName: '.env'));

  await initializeDateFormatting('pt_BR', null);
  Intl.defaultLocale = 'pt_BR';
  runApp(const DartFoodMesaApp());
}

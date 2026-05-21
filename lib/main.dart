import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Força landscape
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Modo imersivo — esconde barra de status e navegação do Android
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Mantém tela ligada indefinidamente
  await WakelockPlus.enable();

  await dotenv.load(fileName: '.env');
  await initializeDateFormatting('pt_BR', null);
  Intl.defaultLocale = 'pt_BR';
  runApp(const DartFoodMesaApp());
}

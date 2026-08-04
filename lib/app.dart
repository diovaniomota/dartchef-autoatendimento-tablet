import 'package:flutter/material.dart';

import 'src/core/app_language.dart';
import 'src/core/app_theme.dart';
import 'src/screens/tablet_home_screen.dart';

class DartFoodMesaApp extends StatelessWidget {
  const DartFoodMesaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuta o idioma AQUI, na raiz: qualquer troca redesenha a arvore inteira
    // de uma vez. Sem isso, cada widget precisaria escutar por conta propria e
    // partes da tela ficariam no idioma anterior.
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, _, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'DartFood Mesa',
        theme: AppTheme.build(),
        home: const TabletHomeScreen(),
      ),
    );
  }
}

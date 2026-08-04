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
        // SEM const aqui, de proposito.
        //
        // Com `const TabletHomeScreen()` o Flutter reutiliza a MESMA instancia
        // em todo rebuild, e Element.updateChild tem um atalho: quando o widget
        // novo e == ao antigo, a subarvore NAO e reconstruida. Resultado: o
        // idioma mudava no notifier, o MaterialApp rebuildava, e a tela
        // continuava em portugues — foi exatamente o que o cliente relatou.
        //
        // Tambem NAO se usa key aqui: uma key nova recriaria o State e o
        // carrinho do cliente seria perdido ao trocar de idioma. Instancia nova
        // sem key preserva o State e ainda assim forca o rebuild.
        home: TabletHomeScreen(),
      ),
    );
  }
}

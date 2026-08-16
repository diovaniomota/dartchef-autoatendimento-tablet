import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core/app_language.dart';
import '../core/app_theme.dart';
import '../core/table_session.dart';
import '../models/cart_item.dart';
import '../models/menu_product.dart';
import '../models/table_menu.dart';
import '../models/tablet_settings.dart';
import '../services/kiosk_service.dart';
import '../services/local_settings_service.dart';
import '../services/tablet_api_service.dart';
import '../services/update_service.dart';
import 'qr_scanner_screen.dart';
import 'cart_screen.dart';
import 'categories_screen.dart';
import 'order_confirm_screen.dart';
import 'order_sent_screen.dart';
import 'product_detail_screen.dart';
import 'product_list_screen.dart';
import 'welcome_screen.dart';

/// Etapas do fluxo de pedido, na ordem em que o cliente as ve.
enum _Estagio { categorias, produtos, detalhe, carrinho, confirmacao, enviado }

class TabletHomeScreen extends StatefulWidget {
  const TabletHomeScreen({super.key});

  @override
  State<TabletHomeScreen> createState() => _TabletHomeScreenState();
}

class _TabletHomeScreenState extends State<TabletHomeScreen> with WidgetsBindingObserver {
  final LocalSettingsService _settingsService = LocalSettingsService();
  final TabletApiService _apiService = TabletApiService();
  final UpdateService _updateService = UpdateService();
  final KioskService _kioskService = KioskService();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final NumberFormat _currency = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

  TabletSettings? _settings;
  TableMenu? _menu;
  List<CartItem> _cart = [];
  bool _loadingConfig = true;
  bool _sendingOrder = false;
  String _errorMessage = '';

  // ─── Sessao da mesa ───
  //
  // O tablet fica de pe na mesa o dia inteiro. Sem sessao, o proximo cliente
  // sentava e encontrava o carrinho e o idioma de quem saiu.
  //
  // false = tela de espera. Vira true quando alguem toca em "comecar", e volta
  // para false quando a mesa e paga/cancelada no PDV ou apos um tempo sem toque.
  bool _sessionActive = false;

  /// Onde o cliente esta dentro do fluxo.
  ///
  /// Estagio e nao rota do Navigator de proposito: a sessao da mesa e encerrada
  /// por ociosidade e por pagamento, e para isso o codigo precisa distinguir
  /// "cliente navegando" de "operador dentro de um dialogo". Se cada tela fosse
  /// uma rota, `_temRotaAcima()` daria verdadeiro o tempo todo e a mesa nunca
  /// seria liberada.
  _Estagio _estagio = _Estagio.categorias;

  /// Categoria aberta na TELA 3.
  String _categoriaAberta = '';

  /// Produto aberto na TELA 4.
  MenuProduct? _produtoAberto;

  /// Linha do carrinho sendo corrigida, quando o detalhe foi aberto pelo
  /// carrinho. Null = o detalhe vai ACRESCENTAR um item novo.
  int? _itemEmEdicao;

  /// Pedido aceito pelo servidor, exibido na tela de "pedido enviado".
  SubmittedOrder? _pedidoEnviado;

  /// Alguma consulta JA viu comanda aberta nesta sessao.
  ///
  /// Marcado pela CONSULTA, nunca pelo envio do pedido: o endereco de historico
  /// so devolve comanda aberta, e confiar no retorno do POST abriria uma janela
  /// em que a consulta roda antes da linha aparecer, ve zero e derrubaria a
  /// sessao do cliente no meio do pedido.
  bool _sawOpenOrder = false;

  Timer? _tableWatchTimer;
  Timer? _idleTimer;
  Timer? _homeRefreshTimer;
  bool _idleWarningOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _kioskService.enterKiosk();
    _bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tableWatchTimer?.cancel();
    _idleTimer?.cancel();
    _homeRefreshTimer?.cancel();
    _customerNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Reaplica modo imersivo toda vez que o app volta ao foco
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      // Voltou do segundo plano: puxa a tela de inicio de novo, sem exigir
      // fechar o aplicativo.
      if (!_sessionActive) unawaited(_loadMenu());
    }
  }

  // ──────────────────── Sessao da mesa ────────────────────

  void _startSession() {
    setState(() {
      _sessionActive = true;
      _estagio = _Estagio.categorias;
      _categoriaAberta = '';
      _produtoAberto = null;
    });
    _sawOpenOrder = false;
    userActivity.ping();
    _startIdleWatch();
    _startTableWatch();
    // Recarrega o cardapio ao abrir a mesa: preco ou item alterado durante o
    // dia chega sem ninguem reiniciar o tablet.
    _stopHomeRefresh();
    unawaited(_loadMenu());
  }

  /// Encerra a sessao e volta para a tela de espera.
  void _endSession() {
    // Guarda de reentrada: o fechamento da mesa e o fim da ociosidade podem
    // chegar quase juntos, e sem isto o segundo faria um pop a mais e levaria
    // a tela de espera embora.
    if (!_sessionActive) return;

    _tableWatchTimer?.cancel();
    _idleTimer?.cancel();
    _idleWarningOpen = false;

    // Derruba TUDO que estiver aberto por cima: aviso de ociosidade, senha,
    // configuracao, confirmacao de pedido.
    //
    // Nao basta fechar o aviso de ociosidade. Trocar a arvore por baixo de uma
    // rota que continua montada deixa essa rota dependendo de widgets que
    // deixaram de existir, e o app quebra com
    // "'_dependents.isEmpty': is not true" — foi assim que apareceu, com a tela
    // de configuracao aberta quando a ociosidade estourou.
    if (mounted) {
      final navegador = Navigator.of(context, rootNavigator: true);
      if (navegador.canPop()) {
        navegador.popUntil((rota) => rota.isFirst);
      }
    }

    if (!mounted) return;
    setState(() {
      _sessionActive = false;
      _estagio = _Estagio.categorias;
      _categoriaAberta = '';
      _produtoAberto = null;
      _pedidoEnviado = null;
      _cart = [];
    });
    _customerNameController.clear();
    _notesController.clear();
    _sawOpenOrder = false;
    // Turista escolhe ingles e vai embora; o proximo cliente encontraria a tela
    // em outro idioma.
    resetLanguage();
    // Volta pra espera com o layout que o restaurante salvou agora, nao o
    // de quando o app abriu de manha.
    unawaited(_loadMenu());
    _startHomeRefresh();
  }

  /// Na tela de espera, relê o cardapio de vez em quando.
  ///
  /// Sem isto, quem monta a tela no DartChef so via o resultado ao fechar o
  /// aplicativo. Trinta segundos e curto o bastante pra ela conferir na mesa
  /// e longo o bastante pra nao martelar a API o dia inteiro.
  void _startHomeRefresh() {
    _homeRefreshTimer?.cancel();
    _homeRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_sessionActive) unawaited(_loadMenu());
    });
  }

  void _stopHomeRefresh() {
    _homeRefreshTimer?.cancel();
    _homeRefreshTimer = null;
  }

  void _startTableWatch() {
    _tableWatchTimer?.cancel();
    _tableWatchTimer = Timer.periodic(kTableWatchInterval, (_) => _checkTableClosed());
  }

  /// Detecta que a mesa foi paga ou cancelada no PDV.
  ///
  /// O endereco de historico devolve SO comanda aberta. Entao "ja vi comanda
  /// aberta e agora nao vejo nenhuma" significa que ela foi fechada ou
  /// cancelada — sem precisar de rota nova no servidor.
  Future<void> _checkTableClosed() async {
    final settings = _settings;
    if (settings == null || !settings.isComplete || !_sessionActive) return;

    List<Map<String, dynamic>> orders;
    try {
      orders = await _apiService.fetchOrderHistory(settings);
    } catch (_) {
      // Falha de rede NAO encerra a sessao. Wi-Fi oscilando no salao e comum, e
      // derrubar o cliente no meio do pedido por causa disso seria pior que
      // demorar para voltar a tela de espera.
      return;
    }

    if (!mounted || !_sessionActive) return;

    if (orders.isNotEmpty) _sawOpenOrder = true;

    if (!shouldEndSessionAfterCheck(
      sawOpenOrder: _sawOpenOrder,
      openOrderCount: orders.length,
    )) {
      return;
    }

    // Mesa fechada, mas alguem esta dentro de uma rota (configurando, por
    // exemplo). Espera a proxima verificacao em vez de arrancar a tela por
    // baixo — a mesa continua fechada, nao ha pressa.
    if (_temRotaAcima()) return;

    _endSession();
  }

  // ──────────────────── Ociosidade ────────────────────

  /// Verifica periodicamente quanto tempo passou desde o ultimo toque.
  ///
  /// Substitui o cronometro que era reiniciado pela tela. O toque agora e
  /// registrado no builder do MaterialApp, acima de todas as rotas, entao
  /// digitar a senha ou mexer na configuracao tambem conta como presenca.
  void _startIdleWatch() {
    _idleTimer?.cancel();
    _idleTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!_sessionActive || _idleWarningOpen) return;
      // Alguem esta com PIN, configuracao ou confirmacao de pedido aberto. A
      // ociosidade existe para liberar a mesa para o proximo cliente, nao para
      // interromper quem esta configurando o tablet.
      if (_temRotaAcima()) return;

      // Mesa que JA PEDIU nao e liberada por ociosidade. O cliente esta ali
      // comendo, e ficar sem tocar no tablet por tres minutos e o normal — quem
      // libera a mesa e o pagamento no PDV ou o cancelamento. A ociosidade
      // continua valendo para quem so mexeu no tablet e foi embora sem pedir.
      if (_sawOpenOrder) return;

      if (userActivity.isIdle) _askIfStillThere();
    });
  }

  /// Alguma rota (dialogo, tela cheia) esta sobre a tela do cardapio.
  ///
  /// Encerrar a sessao com uma rota aberta arrancava a arvore por baixo dela e
  /// quebrava o app de duas formas: "TextEditingController used after being
  /// disposed" e "'_dependents.isEmpty': is not true".
  bool _temRotaAcima() {
    if (!mounted) return false;
    final rota = ModalRoute.of(context);
    return rota != null && !rota.isCurrent;
  }

  /// Pergunta antes de encerrar por ociosidade.
  ///
  /// Encerrar direto no tempo limite tiraria da tela quem esta lendo o cardapio
  /// com calma — o toque e a unica evidencia de presenca que o tablet tem, e
  /// ler nao gera toque.
  Future<void> _askIfStillThere() async {
    if (!mounted || !_sessionActive || _idleWarningOpen) return;

    _idleWarningOpen = true;

    // A contagem vive DENTRO do dialogo e e ele quem se encerra no zero. Dois
    // cronometros contando o mesmo tempo — um para mostrar, outro para fechar —
    // sairiam de sincronia e o numero na tela mentiria.
    final continuar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _IdleWarningDialog(),
    );

    _idleWarningOpen = false;

    if (continuar == true) {
      // O toque no botao ja passou pelo builder do MaterialApp e atualizou o
      // ultimo toque; nao ha cronometro para reiniciar aqui.
      return;
    }
    _endSession();
  }

  // ──────────────────── Bootstrap ────────────────────

  Future<void> _bootstrap() async {
    final loaded = await _settingsService.load();
    if (!mounted) return;
    setState(() {
      _settings = loaded;
      _loadingConfig = false;
    });
    if (loaded.isComplete) {
      await _loadMenu();
      _startHomeRefresh();
    }
  }

  Future<void> _loadMenu() async {
    final settings = _settings;
    if (settings == null || !settings.isComplete) return;
    setState(() => _errorMessage = '');
    try {
      final menu = await _apiService.fetchMenu(settings);
      if (!mounted) return;
      setState(() {
        _menu = menu;
      });
    } on TabletApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = '${e.message}\n\n${_pairingSummary(settings)}');
    } catch (_) {
      if (!mounted) return;
      // A mensagem generica anterior nao dizia PARA ONDE o tablet estava
      // tentando falar. Um tablet pareado numa empresa e levado para outra
      // apenas "nao carregava", sem nada indicando que o endereco era de outro
      // computador/rede. Mostrar o destino torna o erro auto-explicativo.
      setState(() => _errorMessage =
          'Não foi possível falar com o servidor.\n\n${_pairingSummary(settings)}\n'
          'Se este tablet foi configurado em outro estabelecimento, gere um novo '
          'QR em Configurações > Tablet / Mesas e pareie novamente.');
    }
  }

  /// Resumo do pareamento atual, usado nas mensagens de erro.
  String _pairingSummary(TabletSettings settings) {
    final org = settings.organizationName.trim();
    return [
      'Servidor: ${settings.apiBaseUrl}',
      if (org.isNotEmpty) 'Empresa: $org',
      'Mesa: ${settings.tableCode}',
    ].join('\n');
  }

  // ──────────────────── Settings dialog ────────────────────

  // Aplica um pareamento (por QR ou manual), salva e recarrega o cardápio.
  Future<void> _applySettings(TabletSettings next) async {
    await _settingsService.save(next);
    if (!mounted) return;
    setState(() {
      _settings = next;
      _menu = null;
      _cart = [];
      _estagio = _Estagio.categorias;
    });
    await _loadMenu();
  }

  // Escaneia o QR gerado em Configurações > Mesas do dartchef (payload
  // {apiBaseUrl, organizationId, tableCode}) e aplica direto, sem precisar
  // digitar IP/organização/mesa manualmente na tela do tablet.
  //
  // Importante: NÃO fecha o diálogo "Configurar" antes de empilhar o
  // scanner. Fazer pop() do diálogo e, na mesma chamada síncrona (sem
  // esperar um frame), dar push() de outra rota corrompe a árvore do
  // Navigator — mesma falha "'_dependents.isEmpty' is not true" do crash do
  // scanner de comanda. O diálogo fica empilhado por baixo do scanner (fica
  // coberto, sem problema) e só é fechado depois que o scanner já retornou.
  Future<void> _scanPairingQr({BuildContext? dialogContext}) async {
    final raw = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );

    if (dialogContext != null && dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }
    if (raw == null || raw.isEmpty || !mounted) return;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final next = TabletSettings(
        apiBaseUrl: (decoded['apiBaseUrl'] ?? '').toString().trim(),
        organizationId: (decoded['organizationId'] ?? '').toString().trim(),
        tableCode: (decoded['tableCode'] ?? '').toString().trim(),
        // Ausente em QRs gerados por versoes antigas do dartchef — cai em
        // string vazia e o pareamento segue normalmente.
        organizationName: (decoded['organizationName'] ?? '').toString().trim(),
      );
      if (!next.isComplete) {
        _showMsg('QR Code incompleto. Gere um novo em Configurações > Mesas.', isError: true);
        return;
      }
      await _applySettings(next);
      final org = next.organizationName;
      _showMsg(org.isEmpty
          ? 'Mesa ${next.tableCode} pareada com sucesso!'
          : 'Mesa ${next.tableCode} pareada com $org!');
    } catch (_) {
      _showMsg('QR Code inválido. Escaneie o QR de pareamento do dartchef.', isError: true);
    }
  }

  // PIN pra impedir que qualquer cliente mexa nas configuracoes so tocando
  // no icone de engrenagem. Verifica antes de abrir _openSettingsDialog em
  // TODOS os pontos de entrada (icone de engrenagem, toque longo no logo,
  // e o botao "Configurar agora" da tela inicial sem pareamento).
  static const _settingsPin = '1707';

  Future<void> _requestSettingsAccess() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => const _PinDialog(pinEsperado: _settingsPin),
    );

    if (ok == true) {
      if (!mounted) return;
      // Espera o frame em que o dialogo do PIN termina de ser removido da
      // arvore antes de abrir o proximo. Future.delayed(Duration.zero) so
      // cede o event loop e podia cair no meio do mesmo frame de teardown;
      // endOfFrame garante que o desmonte terminou.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      await _openSettingsDialog();
    }
  }

  Future<void> _openSettingsDialog() async {
    final current = _settings ?? await _settingsService.load();
    final apiCtrl = TextEditingController(text: current.apiBaseUrl);
    final orgCtrl = TextEditingController(text: current.organizationId);
    final tableCtrl = TextEditingController(text: current.tableCode);
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Configurar tablet'),
        content: SizedBox(
          // Largura acompanha a tela: 460 fixo estourava no tablet de 7".
          width: MediaQuery.of(context).size.width * 0.7,
          // Rolagem no conteudo: a altura do dialogo e limitada pela tela e a
          // soma dos campos passava dela por poucos pixels — o bastante para a
          // faixa listrada de estouro aparecer no lugar dos botoes. Com o
          // teclado aberto a sobra e ainda menor.
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _scanPairingQr(dialogContext: ctx),
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                  label: const Text('Escanear QR de pareamento', style: TextStyle(fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: AppTheme.border)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('ou preencha manualmente', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    ),
                    Expanded(child: Divider(color: AppTheme.border)),
                  ],
                ),
              ),
              TextField(controller: apiCtrl, decoration: const InputDecoration(labelText: 'Base da API', hintText: 'http://192.168.0.x:3001')),
              const SizedBox(height: 12),
              TextField(controller: orgCtrl, decoration: const InputDecoration(labelText: 'Organization ID')),
              const SizedBox(height: 12),
              TextField(controller: tableCtrl, decoration: const InputDecoration(labelText: 'Código da mesa', hintText: '01')),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: AppTheme.border),
              ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _checkForUpdates,
                  icon: const Icon(Icons.system_update_rounded, size: 18),
                  label: const Text('Verificar atualização'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppTheme.textMuted, side: const BorderSide(color: AppTheme.border)),
                ),
              ),
              ],
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _kioskService.exitKiosk();
              SystemNavigator.pop();
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: const Text('Sair do app'),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
              FilledButton(
                onPressed: () async {
                  final next = TabletSettings(
                    apiBaseUrl: apiCtrl.text.trim(),
                    organizationId: orgCtrl.text.trim(),
                    tableCode: tableCtrl.text.trim(),
                  );
                  if (!next.isComplete) {
                    _showMsg('Preencha API, organização e mesa.', isError: true);
                    return;
                  }
                  final nav = Navigator.of(ctx);
                  await _applySettings(next);
                  if (!mounted) return;
                  nav.pop();
                },
                child: Text(t('notes.save')),
              ),
            ],
          ),
        ],
      ),
    );
    apiCtrl.dispose(); orgCtrl.dispose(); tableCtrl.dispose();
  }

  // ──────────────────── Atualização (GitHub Releases) ────────────────────

  Future<void> _checkForUpdates() async {
    _showMsg('Verificando atualizações...');
    try {
      final info = await _updateService.checkForUpdate();
      if (!mounted) return;

      if (!info.hasUpdate) {
        _showMsg('Você já está na versão mais recente (${info.currentVersion}).');
        return;
      }

      final shouldUpdate = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Nova versão disponível'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Versão atual: ${info.currentVersion}', style: const TextStyle(color: AppTheme.textMuted)),
                const SizedBox(height: 4),
                Text('Nova versão: ${info.latestVersion}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                if ((info.releaseNotes ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(info.releaseNotes!.trim(), style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Depois')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Atualizar agora')),
          ],
        ),
      );

      if (shouldUpdate == true && info.downloadUrl != null) {
        // Mesmo cuidado do PIN: espera o dialogo anterior terminar de sair
        // da arvore antes de abrir o de progresso.
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
        await _downloadAndInstallUpdate(info.downloadUrl!);
      }
    } on UpdateException catch (e) {
      if (mounted) _showMsg(e.message, isError: true);
    } catch (_) {
      if (mounted) _showMsg('Não foi possível verificar atualizações. Confira a internet.', isError: true);
    }
  }

  Future<void> _downloadAndInstallUpdate(String downloadUrl) async {
    final progress = ValueNotifier<double>(0);
    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Baixando atualização...'),
        content: ValueListenableBuilder<double>(
          valueListenable: progress,
          builder: (_, value, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: value > 0 ? value : null, color: AppTheme.accent, backgroundColor: AppTheme.surfaceHigh),
              const SizedBox(height: 12),
              Text('${(value * 100).toStringAsFixed(0)}%', style: const TextStyle(color: AppTheme.textMuted)),
            ],
          ),
        ),
      ),
    );

    try {
      await _updateService.downloadAndInstall(
        downloadUrl,
        onProgress: (p) => progress.value = p,
        // Sai do modo quiosque antes de abrir o instalador: com o Screen
        // Pinning ativo o Android impede o instalador de vir pra frente.
        beforeOpenInstaller: () => _kioskService.exitKiosk(),
      );

      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      // Fecha o app pra liberar a instalacao. Sem isso o instalador abre mas
      // o app continua aberto por tras, e o Android nao substitui o pacote
      // enquanto ele estiver rodando. O delay dá tempo do instalador
      // aparecer antes da nossa Activity ser finalizada.
      await Future.delayed(const Duration(seconds: 2));
      await SystemNavigator.pop();
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      // Falhou: volta pro modo quiosque, senao o tablet fica destravado.
      await _kioskService.enterKiosk();
      if (mounted) {
        _showMsg(e is UpdateException ? e.message : 'Falha ao baixar/instalar a atualização.', isError: true);
      }
    }
  }

  // ──────────────────── SOBRE dialog ────────────────────

  // ──────────────────── Chamadas de serviço ────────────────────

  /// Envia uma solicitacao da mesa para o salao (garcom, vallet, conta).
  ///
  /// Os textos sao configuraveis porque nem toda solicitacao e "chamar
  /// alguem": para a conta, "Chamar a conta?" nao faz sentido.
  Future<void> _callService(
    String callType,
    String displayName, {
    String? title,
    String? body,
    String? confirmLabel,
    String? successMessage,
  }) async {
    final settings = _settings;
    if (settings == null || !settings.isComplete) {
      _showMsg('Configure a mesa antes.', isError: true);
      return;
    }

    // Confirmação
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title ?? 'Chamar $displayName?', style: const TextStyle(color: Colors.white)),
        content: Text(
          body ??
              'Enviaremos uma notificação para $displayName atender a mesa ${settings.tableCode}.',
          style: const TextStyle(color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accent),
            child: Text(confirmLabel ?? 'Chamar $displayName'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _apiService.callService(settings: settings, callType: callType);
      _showMsg(successMessage ?? '$displayName foi chamado! Aguarde um momento.');
    } on TabletApiException catch (e) {
      _showMsg(e.message, isError: true);
    } catch (_) {
      _showMsg('Não foi possível enviar a solicitação.', isError: true);
    }
  }

  Future<void> _callWaiter() {
    final table = _settings?.tableCode ?? '';
    return _callService(
      'garcom',
      t('topbar.waiter'),
      title: t('call.waiterTitle'),
      body: t2('call.waiterBody', {'code': table}),
      confirmLabel: t('call.waiterConfirm'),
      successMessage: t('call.waiterSuccess'),
    );
  }

  /// Avisa o salao que a mesa quer fechar a conta. Cai na mesma fila das
  /// chamadas de garcom (restaurant_service_calls, call_type 'conta'), entao
  /// aparece no alerta do sistema e no Mapa de Mesas sem nada a mais.
  Future<void> _requestBill() {
    final table = _settings?.tableCode ?? '';
    return _callService(
      'conta',
      'a conta',
      title: 'Pedir a conta?',
      body: table.isEmpty
          ? 'Vamos avisar o atendente que a mesa quer fechar a conta.'
          : 'Vamos avisar o atendente que a Mesa $table quer fechar a conta.',
      confirmLabel: 'Pedir a conta',
      successMessage: 'Pedido enviado! O atendente já vai levar a conta.',
    );
  }

  // ──────────────────── Minha conta / pedidos ────────────────────

  Future<void> _showMyOrders() async {
    final settings = _settings;
    if (settings == null || !settings.isComplete) {
      _showMsg('Configure a mesa antes.', isError: true);
      return;
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => _OrderHistoryDialog(
        settings: settings,
        apiService: _apiService,
        currency: _currency,
      ),
    );
  }

  // ──────────────────── Helpers ────────────────────

  void _showMsg(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: isError ? AppTheme.danger : AppTheme.accent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(left: 80, right: 320, bottom: 12),
        duration: const Duration(seconds: 2),
      ));
  }

  double get _cartTotal => _cart.fold(0.0, (s, i) => s + i.subtotal);
  int get _cartItemCount => _cart.fold(0, (s, i) => s + i.quantity);

  // ──────────────────── Carrinho ────────────────────

  // _changeQty/_removeItem foram removidos: buscavam a linha por product.id,
  // o que virou ambiguo quando o mesmo produto passou a poder ocupar duas
  // linhas (uma com observacao, outra sem). O carrinho agora opera por indice
  // via _removeCartItemAt/_editItemNotes.

  Future<void> _enviarPedido([PaymentMethod? forma]) async {
    // Rede de seguranca final contra pedido duplicado: vale para TODOS os
    // caminhos (duplo toque, telas empilhadas, dois botoes no mesmo frame).
    // _sendingOrder e ligado de forma sincrona logo abaixo e desligado no
    // finally, entao a guarda funciona mesmo com duas chamadas no mesmo frame.
    if (_sendingOrder) return;
    if (_cart.isEmpty) { _showMsg('Adicione itens antes de enviar.', isError: true); return; }
    final settings = _settings;
    if (settings == null) { _showMsg('Configure o tablet antes.', isError: true); return; }

    // A mesa vem da configuracao do tablet, que fica fixo em uma mesa. Antes
    // o codigo lido no QR sobrescrevia esse valor (copyWith), o que so servia
    // no cenario de comanda individual por pessoa — descartado pelo cliente.
    setState(() => _sendingOrder = true);
    try {
      final pedido = await _apiService.submitOrder(
        settings: settings,
        items: _cart,
        customerName: _customerNameController.text,
        notes: _notesController.text,
        paymentMethod: forma?.name ?? '',
      );
      if (!mounted) return;
      setState(() {
        _cart = [];
        _customerNameController.clear();
        _notesController.clear();
        _pedidoEnviado = pedido;
        _estagio = _Estagio.enviado;
      });

      // O idioma NAO volta ao portugues aqui, ao contrario da versao anterior.
      // Quem acabou de pedir costuma pedir mais, e trocar a tela para outro
      // idioma no meio da refeicao e pior que esperar o fim da sessao — o
      // encerramento (mesa paga ou ociosidade) ja cuida disso.
    } on TabletApiException catch (e) {
      _showMsg(e.message, isError: true);
    } catch (_) {
      _showMsg('Não foi possível enviar o pedido.', isError: true);
    } finally {
      if (mounted) setState(() => _sendingOrder = false);
    }
  }

  // ──────────────────── Content area ────────────────────

  // ──────────────────── Fluxo das telas ────────────────────

  void _abrirCategoria(String categoria) {
    setState(() {
      _categoriaAberta = categoria;
      _estagio = _Estagio.produtos;
    });
  }

  void _abrirProduto(MenuProduct produto) {
    setState(() {
      _produtoAberto = produto;
      _itemEmEdicao = null;
      _estagio = _Estagio.detalhe;
    });
  }

  /// Abre uma linha do carrinho para corrigir quantidade, variacao ou
  /// observacao. Antes so dava para remover e montar tudo de novo.
  void _editarItemDoCarrinho(int indice) {
    if (indice < 0 || indice >= _cart.length) return;
    setState(() {
      _produtoAberto = _cart[indice].product;
      _itemEmEdicao = indice;
      _estagio = _Estagio.detalhe;
    });
  }

  void _irPara(_Estagio destino) => setState(() => _estagio = destino);

  List<MenuProduct> _produtosDaCategoria(String categoria) =>
      (_menu?.products ?? []).where((p) => p.category == categoria).toList();

  /// Adiciona direto da lista, sem abrir o detalhe.
  ///
  /// Produto com variacao obrigatoria NAO entra por aqui: sem a escolha o bar
  /// nao sabe o que preparar, entao o toque leva ao detalhe em vez de adicionar
  /// algo incompleto.
  void _adicaoRapida(MenuProduct produto) {
    final exigeEscolha = produto.optionGroups.any((grupo) => grupo.required);
    if (exigeEscolha) {
      _abrirProduto(produto);
      return;
    }
    _adicionarAoCarrinho(produto, 1, const [], '');
  }

  void _adicionarAoCarrinho(
    MenuProduct produto,
    int quantidade,
    List<ProductOptionChoice> escolhas,
    String observacao,
  ) {
    final obs = observacao.trim();

    // Editando: substitui a linha no lugar e volta ao carrinho, em vez de
    // acrescentar uma segunda linha do mesmo item.
    final emEdicao = _itemEmEdicao;
    if (emEdicao != null && emEdicao < _cart.length) {
      setState(() {
        final atualizado = [..._cart];
        atualizado[emEdicao] = CartItem(
          product: produto,
          quantity: quantidade,
          notes: obs,
          chosenOptions: escolhas,
        );
        _cart = atualizado;
        _itemEmEdicao = null;
        _estagio = _Estagio.carrinho;
      });
      return;
    }

    setState(() {
      // Soma com a linha do MESMO produto, mesma observacao e mesmas variacoes.
      // Sem isso, uma caipira de vodka viraria "2x" junto com uma de cachaca e o
      // bar prepararia duas iguais.
      final idx = _cart.indexWhere((i) => i.matchesWithOptions(produto, obs, escolhas));
      if (idx >= 0) {
        final atualizado = [..._cart];
        atualizado[idx] = _cart[idx].copyWith(quantity: _cart[idx].quantity + quantidade);
        _cart = atualizado;
      } else {
        _cart = [
          ..._cart,
          CartItem(
            product: produto,
            quantity: quantidade,
            notes: obs,
            chosenOptions: escolhas,
          ),
        ];
      }
      // Volta para a lista da categoria: o cliente costuma pedir mais de um item
      // do mesmo grupo, e cair no carrinho a cada adicao obrigaria a voltar.
      if (_estagio == _Estagio.detalhe) _estagio = _Estagio.produtos;
    });
    _showMsg(t2('order.added', {'product': produto.displayName}));
  }

  void _mudarQuantidade(int indice, int delta) {
    if (indice < 0 || indice >= _cart.length) return;
    setState(() {
      final atual = _cart[indice];
      final nova = atual.quantity + delta;
      if (nova <= 0) {
        // Chegar a zero remove a linha: e o que o cliente espera ao apertar "-"
        // no ultimo, e evita item fantasma com quantidade zero na comanda.
        _cart = [..._cart]..removeAt(indice);
        return;
      }
      final atualizado = [..._cart];
      atualizado[indice] = atual.copyWith(quantity: nova);
      _cart = atualizado;
    });
  }

  // ──────────────────── Build ────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loadingConfig) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: AppTheme.background,
          body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
        ),
      );
    }

    // Tela de espera. Fica sobre TODO o resto — inclusive sobre o erro de
    // pareamento, que so interessa a quem esta configurando o tablet e chega
    // pelo cardapio depois de tocar em comecar.
    if (!_sessionActive) {
      return PopScope(
        canPop: false,
        child: WelcomeScreen(
          restaurantName: _nomeDoRestaurante,
          logoUrl: _menu?.logoUrl ?? '',
          backgroundUrl: _menu?.backgroundUrl ?? '',
          primaryColor: _menu?.primaryColor ?? '',
          blocks: _menu?.homeBlocks ?? const [],
          tableCode: _settings?.tableCode ?? _menu?.tableCode ?? '',
          tableName: _menu?.tableName ?? '',
          onStart: _startSession,
          onSettings: _requestSettingsAccess,
          // Sem cardapio carregado nao ha o que pedir: a tela oferece conectar
          // em vez de um botao que leva a um erro.
          conectado: _menu != null,
        ),
      );
    }

    // Cardapio ainda nao carregado. Antes isto caia no layout antigo — com
    // barra lateral e painel de carrinho — e quem estava usando o app achava
    // que o trabalho tinha sumido. Erro e espera agora acontecem DENTRO do
    // desenho novo.
    if (_menu == null) {
      return PopScope(
        canPop: false,
        child: _errorMessage.isEmpty ? _telaCarregando() : _telaErro(),
      );
    }

    switch (_estagio) {
      case _Estagio.categorias:
        return PopScope(
          canPop: false,
          child: CategoriesScreen(
            categories: _menu!.categories,
            products: _menu!.products,
            categoryImages: _menu!.categoryImages,
            categoryLabel: _menu!.labelForCategory,
            logoUrl: _menu!.logoUrl,
            restaurantName: _nomeDoRestaurante,
            cartItemCount: _cartItemCount,
            onCategorySelected: _abrirCategoria,
            onSearchTap: _showMyOrders,
            onCartTap: () => _irPara(_Estagio.carrinho),
            onHomeTap: _endSession,
            onCallWaiter: _callWaiter,
            onRequestBill: _requestBill,
          ),
        );

      case _Estagio.produtos:
        return PopScope(
          canPop: false,
          child: ProductListScreen(
            // Titulo traduzido; o filtro continua usando o nome original.
            categoryName: _menu!.labelForCategory(_categoriaAberta),
            products: _produtosDaCategoria(_categoriaAberta),
            currency: _currency,
            cartItemCount: _cartItemCount,
            onBack: () => _irPara(_Estagio.categorias),
            onHomeTap: () => _irPara(_Estagio.categorias),
            onCartTap: () => _irPara(_Estagio.carrinho),
            onCallWaiter: _callWaiter,
            onRequestBill: _requestBill,
            onProductTap: _abrirProduto,
            onQuickAdd: _adicaoRapida,
          ),
        );

      case _Estagio.detalhe:
        final produto = _produtoAberto;
        // Sem produto escolhido nao ha o que detalhar: volta para a lista, em
        // vez de mostrar uma tela que o cliente nao sabe de onde veio.
        if (produto == null) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _irPara(_Estagio.produtos),
          );
          return _telaCarregando();
        }
        return PopScope(
          canPop: false,
          child: ProductDetailScreen(
            produto: produto,
            currency: _currency,
            cartItemCount: _cartItemCount,
            editando: _itemEmEdicao != null,
            quantidadeInicial: _itemEmEdicao != null && _itemEmEdicao! < _cart.length
                ? _cart[_itemEmEdicao!].quantity
                : 1,
            escolhasIniciais: _itemEmEdicao != null && _itemEmEdicao! < _cart.length
                ? _cart[_itemEmEdicao!].chosenOptions
                : const [],
            observacaoInicial: _itemEmEdicao != null && _itemEmEdicao! < _cart.length
                ? _cart[_itemEmEdicao!].notes
                : '',
            // Voltar do modo edicao leva ao carrinho, de onde se veio.
            onBack: () => _irPara(
              _itemEmEdicao != null ? _Estagio.carrinho : _Estagio.produtos,
            ),
            onCartTap: () => _irPara(_Estagio.carrinho),
            onAdd: (quantidade, escolhas, observacao) =>
                _adicionarAoCarrinho(produto, quantidade, escolhas, observacao),
          ),
        );

      case _Estagio.confirmacao:
        return PopScope(
          canPop: false,
          child: OrderConfirmScreen(
            cart: _cart,
            currency: _currency,
            subtotal: _cartTotal,
            tableCode: _settings?.tableCode ?? '--',
            cartItemCount: _cartItemCount,
            sendingOrder: _sendingOrder,
            nomeInicial: _customerNameController.text,
            onBack: () => _irPara(_Estagio.carrinho),
            onSend: (nome, forma) {
              _customerNameController.text = nome;
              unawaited(_enviarPedido(forma));
            },
          ),
        );

      case _Estagio.enviado:
        final pedido = _pedidoEnviado;
        if (pedido == null) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _irPara(_Estagio.categorias),
          );
          return _telaCarregando();
        }
        return PopScope(
          canPop: false,
          child: OrderSentScreen(
            numero: pedido.numero,
            onFollow: _showMyOrders,
            onKeepOrdering: () => _irPara(_Estagio.categorias),
            // A mesa continua aberta ate o PDV fechar: nao ha por que prender o
            // cliente nesta tela.
          ),
        );

      case _Estagio.carrinho:
        return PopScope(
          canPop: false,
          child: CartScreen(
            cart: _cart,
            currency: _currency,
            subtotal: _cartTotal,
            cartItemCount: _cartItemCount,
            sendingOrder: _sendingOrder,
            notasIniciais: _notesController.text,
            onBack: () => _irPara(
              _categoriaAberta.isEmpty ? _Estagio.categorias : _Estagio.produtos,
            ),
            onIncrement: (i) => _mudarQuantidade(i, 1),
            onDecrement: (i) => _mudarQuantidade(i, -1),
            onClear: () => setState(() => _cart = []),
            onEditItem: _editarItemDoCarrinho,
            onFinish: (notas) {
              _notesController.text = notas;
              _irPara(_Estagio.confirmacao);
            },
          ),
        );
    }
  }

  Widget _telaCarregando() => const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      );

  /// Cardapio que nao carregou.
  ///
  /// Mostra PARA ONDE o tablet tentou falar, e nao so "deu erro": um tablet
  /// pareado numa empresa e levado para outra apenas "nao carregava", sem nada
  /// indicando que o endereco era de outro computador ou de outra rede.
  Widget _telaErro() => Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off, color: AppTheme.textMuted, size: 64),
                    const SizedBox(height: 18),
                    Text(
                      t('error.menuTitle'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: _loadMenu,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.refresh, size: 20),
                        label: Text(
                          t('error.retry'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Configurar continua alcancavel daqui: e justamente com o
                    // cardapio quebrado que alguem precisa corrigir o pareamento.
                    TextButton.icon(
                      onPressed: _requestSettingsAccess,
                      icon: const Icon(Icons.settings, color: AppTheme.textMuted, size: 18),
                      label: Text(
                        t('settings.tooltip'),
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  String get _nomeDoRestaurante =>
      _menu?.organizationName ?? _settings?.organizationName ?? 'DartChef';

}

/// Aviso de ociosidade com contagem visivel.
///
/// A contagem aparece para o cliente entender que a tela vai mudar sozinha, em
/// vez de o cardapio simplesmente desaparecer enquanto ele decidia.
class _IdleWarningDialog extends StatefulWidget {
  const _IdleWarningDialog();

  @override
  State<_IdleWarningDialog> createState() => _IdleWarningDialogState();
}

class _IdleWarningDialogState extends State<_IdleWarningDialog> {
  int _segundos = kIdleWarningSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _segundos -= 1);
      if (_segundos <= 0) {
        timer.cancel();
        // Devolve false: ninguem respondeu, a sessao encerra.
        if (mounted) Navigator.of(context).pop(false);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        t('idle.title'),
        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
      ),
      content: Text(
        t2('idle.body', {'seconds': '$_segundos'}),
        style: const TextStyle(color: AppTheme.textMuted, fontSize: 14, height: 1.4),
      ),
      actions: [
        SizedBox(
          height: 58,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accent,
              padding: const EdgeInsets.symmetric(horizontal: 26),
            ),
            child: Text(
              t('idle.stay'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────── Order History Dialog ────────────────────

class _OrderHistoryDialog extends StatefulWidget {
  const _OrderHistoryDialog({
    required this.settings,
    required this.apiService,
    required this.currency,
  });

  final TabletSettings settings;
  final TabletApiService apiService;
  final NumberFormat currency;

  @override
  State<_OrderHistoryDialog> createState() => _OrderHistoryDialogState();
}

class _OrderHistoryDialogState extends State<_OrderHistoryDialog> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final orders = await widget.apiService.fetchOrderHistory(widget.settings);
      if (!mounted) return;
      setState(() { _orders = orders; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'novo': return 'Novo';
      case 'preparo': return 'Em preparo';
      case 'pronto': return 'Pronto';
      case 'entregue': return 'Entregue';
      case 'fechado': return 'Fechado';
      case 'cancelado': return 'Cancelado';
      default: return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'novo': return const Color(0xFFD97706);
      case 'preparo': return const Color(0xFF2563EB);
      case 'pronto': return const Color(0xFF16A34A);
      case 'entregue': return const Color(0xFF6366F1);
      case 'fechado': return const Color(0xFF64748B);
      case 'cancelado': return const Color(0xFFDC2626);
      default: return const Color(0xFF888888);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF111111),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 560,
        height: 600,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF222222))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, color: AppTheme.accent, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Meus Pedidos — Mesa ${widget.settings.tableCode}',
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, color: Color(0xFF888888))),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                  : _error.isNotEmpty
                      ? Center(child: Text(_error, style: const TextStyle(color: Color(0xFFEF4444)), textAlign: TextAlign.center))
                      : _orders.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_outlined, size: 44, color: Color(0xFF666666)),
                                  SizedBox(height: 12),
                                  Text('Nenhum pedido nesta mesa ainda.', style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 16)),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _orders.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final order = _orders[index];
                                final status = order['status'] as String? ?? 'novo';
                                final items = order['restaurant_order_items'] as List<dynamic>? ?? [];
                                final total = double.tryParse('${order['total'] ?? 0}') ?? 0;
                                final createdAt = order['created_at'] as String?;
                                final dt = createdAt != null ? DateTime.tryParse(createdAt)?.toLocal() : null;
                                final dtStr = dt != null
                                    ? '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}'
                                    : '';

                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A1A),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border(left: BorderSide(color: _statusColor(status), width: 3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text('Pedido #${order['id']}', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 16)),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: _statusColor(status).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: _statusColor(status).withValues(alpha: 0.3)),
                                            ),
                                            child: Text(_statusLabel(status), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _statusColor(status))),
                                          ),
                                        ],
                                      ),
                                      if (dtStr.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(dtStr, style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
                                        ),
                                      const SizedBox(height: 10),
                                      ...items.map((item) {
                                        final i = item as Map<String, dynamic>;
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 4),
                                          child: Row(
                                            children: [
                                              Text('${i['quantity']}x', style: const TextStyle(fontSize: 14, color: Color(0xFFAAAAAA), fontWeight: FontWeight.w600)),
                                              const SizedBox(width: 8),
                                              Expanded(child: Text(i['product_name'] as String? ?? '', style: const TextStyle(fontSize: 14, color: Color(0xFFCCCCCC)))),
                                              Text(widget.currency.format(double.tryParse('${i['subtotal'] ?? 0}') ?? 0),
                                                  style: const TextStyle(fontSize: 14, color: Color(0xFFAAAAAA))),
                                            ],
                                          ),
                                        );
                                      }),
                                      const Divider(color: Color(0xFF2A2A2A), height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          const Text('Total: ', style: TextStyle(fontSize: 15, color: Color(0xFFAAAAAA))),
                                          Text(widget.currency.format(total),
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────── Sub-category pill ────────────────────

// ──────────────────── Helper widgets ────────────────────

/// Dialogo de observacao de um item do carrinho.
///
/// Traz sugestoes prontas porque digitar em teclado virtual de tablet e lento
/// e o cliente esta em pe no salao: na maioria dos casos um toque resolve.
class _ItemNotesDialog extends StatefulWidget {
  const _ItemNotesDialog({required this.productName, required this.initialNotes});

  final String productName;
  final String initialNotes;

  @override
  State<_ItemNotesDialog> createState() => _ItemNotesDialogState();
}

class _ItemNotesDialogState extends State<_ItemNotesDialog> {
  // As sugestoes prontas foram removidas: num tablet de 7" as opcoes ocupavam a
  // tela inteira e EMPURRAVAM o campo de digitar para fora, deixando o cliente
  // sem conseguir escrever. Campo livre resolve e cabe em qualquer tamanho.
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialNotes);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        t2('notes.title', {'product': widget.productName}),
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t('notes.help'),
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              // Teclado abre direto: sem as sugestoes, digitar e a unica acao.
              autofocus: true,
              maxLength: 200,
              maxLines: 4,
              minLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: t('notes.hint'),
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.background,
                counterStyle: const TextStyle(color: AppTheme.textMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.accent, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.initialNotes.trim().isNotEmpty)
          TextButton(
            onPressed: () => Navigator.of(context).pop(''),
            child: Text(t('notes.clear'), style: const TextStyle(color: AppTheme.textMuted)),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t('notes.cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          style: FilledButton.styleFrom(backgroundColor: AppTheme.accent),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

/// Pergunta a variacao do produto antes de ele entrar no carrinho.
///
/// Botoes grandes e uma coluna so: o tablet fica de pe no salao, o cliente
/// escolhe em pe e muitas vezes sem oculos.
class _ProductOptionsDialog extends StatefulWidget {
  const _ProductOptionsDialog({required this.product, required this.currency});

  final MenuProduct product;
  final NumberFormat currency;

  @override
  State<_ProductOptionsDialog> createState() => _ProductOptionsDialogState();
}

class _ProductOptionsDialogState extends State<_ProductOptionsDialog> {
  /// Escolha de cada grupo, por id do grupo.
  final Map<int, ProductOptionChoice> _escolhas = {};

  @override
  void initState() {
    super.initState();
    // Grupo opcional com uma unica opcao ja vem marcado: nao ha decisao a tomar.
    for (final grupo in widget.product.optionGroups) {
      if (!grupo.required && grupo.choices.length == 1) {
        _escolhas[grupo.id] = grupo.choices.first;
      }
    }
  }

  bool get _completo => widget.product.optionGroups
      .where((grupo) => grupo.required)
      .every((grupo) => _escolhas.containsKey(grupo.id));

  double get _total =>
      widget.product.price +
      _escolhas.values.fold(0.0, (soma, escolha) => soma + escolha.priceDelta);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.product.displayName,
        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final grupo in widget.product.optionGroups) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    grupo.required ? grupo.name : '${grupo.name} (${t('options.optional')})',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                for (final opcao in grupo.choices)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _OpcaoBotao(
                      nome: opcao.name,
                      // Mostra so quando muda o preco: "+ R$ 0,00" em toda
                      // opcao vira ruido e faz o cliente procurar pegadinha.
                      extra: opcao.priceDelta == 0
                          ? ''
                          : (opcao.priceDelta > 0
                              ? '+ ${widget.currency.format(opcao.priceDelta)}'
                              : '- ${widget.currency.format(opcao.priceDelta.abs())}'),
                      selecionado: _escolhas[grupo.id]?.id == opcao.id,
                      onTap: () => setState(() => _escolhas[grupo.id] = opcao),
                    ),
                  ),
                const SizedBox(height: 6),
              ],
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    t('cart.total'),
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                  ),
                  Text(
                    widget.currency.format(_total),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t('notes.cancel'), style: const TextStyle(color: AppTheme.textMuted)),
        ),
        FilledButton(
          // Desabilitado enquanto falta escolher: melhor o botao nao responder
          // do que aceitar e a comanda chegar incompleta no bar.
          onPressed: _completo
              ? () => Navigator.of(context).pop(_escolhas.values.toList())
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.accent,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          ),
          child: Text(
            t('product.addUpper'),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _OpcaoBotao extends StatelessWidget {
  const _OpcaoBotao({
    required this.nome,
    required this.extra,
    required this.selecionado,
    required this.onTap,
  });

  final String nome;
  final String extra;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selecionado ? AppTheme.accent.withValues(alpha: 0.18) : AppTheme.background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          // 60 de altura: alvo de toque confortavel de pe, com o tablet fixo
          // na mesa.
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selecionado ? AppTheme.accent : AppTheme.border,
              width: selecionado ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selecionado ? Icons.check_circle : Icons.circle_outlined,
                color: selecionado ? AppTheme.accent : AppTheme.textMuted,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  nome,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: selecionado ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              if (extra.isNotEmpty)
                Text(
                  extra,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialogo do PIN das configuracoes.
///
/// StatefulWidget de proposito, e nao um controller criado na funcao que abre o
/// dialogo: assim o TextEditingController pertence ao widget e e liberado no
/// dispose dele. Descartar o controller logo depois do `await showDialog`
/// parecia funcionar, mas quebrava com "A TextEditingController was used after
/// being disposed" quando o dialogo era fechado DE FORA — pela ociosidade — e
/// ainda estava animando a saida.
class _PinDialog extends StatefulWidget {
  const _PinDialog({required this.pinEsperado});

  final String pinEsperado;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _errado = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (_controller.text.trim() == widget.pinEsperado) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _errado = true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: const Text('Configurações protegidas'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Digite o PIN para continuar.', style: TextStyle(color: AppTheme.textMuted)),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 8,
              decoration: InputDecoration(
                counterText: '',
                labelText: 'PIN',
                errorText: _errado ? 'PIN incorreto.' : null,
              ),
              onSubmitted: (_) => _confirmar(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _confirmar, child: const Text('Entrar')),
      ],
    );
  }
}

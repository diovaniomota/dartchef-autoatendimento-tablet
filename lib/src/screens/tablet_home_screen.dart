import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../models/cart_item.dart';
import '../models/menu_product.dart';
import '../models/table_menu.dart';
import '../models/tablet_settings.dart';
import '../services/local_settings_service.dart';
import '../services/tablet_api_service.dart';
import '../widgets/cart_panel_widget.dart';
import '../widgets/home_highlights_widget.dart';
import '../widgets/product_card_widget.dart';
import '../widgets/sidebar_widget.dart';
import '../widgets/top_bar_widget.dart';
import 'confirm_order_screen.dart';
import 'qr_scanner_screen.dart';

class TabletHomeScreen extends StatefulWidget {
  const TabletHomeScreen({super.key});

  @override
  State<TabletHomeScreen> createState() => _TabletHomeScreenState();
}

class _TabletHomeScreenState extends State<TabletHomeScreen> with WidgetsBindingObserver {
  final LocalSettingsService _settingsService = LocalSettingsService();
  final TabletApiService _apiService = TabletApiService();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final NumberFormat _currency = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

  TabletSettings? _settings;
  TableMenu? _menu;
  List<CartItem> _cart = [];
  String _activeCategory = 'Todos';
  String? _activeSubcategory; // null = show all (Todos)
  String _searchTerm = '';
  bool _loadingConfig = true;
  bool _loadingMenu = false;
  bool _sendingOrder = false;
  String _errorMessage = '';
  bool _showCart = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _customerNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Reaplica modo imersivo toda vez que o app volta ao foco
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  // ──────────────────── Bootstrap ────────────────────

  Future<void> _bootstrap() async {
    final loaded = await _settingsService.load();
    if (!mounted) return;
    setState(() {
      _settings = loaded;
      _loadingConfig = false;
    });
    if (loaded.isComplete) await _loadMenu();
  }

  Future<void> _loadMenu() async {
    final settings = _settings;
    if (settings == null || !settings.isComplete) return;
    setState(() { _loadingMenu = true; _errorMessage = ''; });
    try {
      final menu = await _apiService.fetchMenu(settings);
      if (!mounted) return;
      setState(() {
        _menu = menu;
        _activeCategory = 'Todos';
      });
    } on TabletApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Não foi possível carregar o cardápio.');
    } finally {
      if (mounted) setState(() => _loadingMenu = false);
    }
  }

  // ──────────────────── Settings dialog ────────────────────

  // Aplica um pareamento (por QR ou manual), salva e recarrega o cardápio.
  Future<void> _applySettings(TabletSettings next) async {
    await _settingsService.save(next);
    if (!mounted) return;
    setState(() { _settings = next; _menu = null; _cart = []; _activeCategory = 'Todos'; });
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
      );
      if (!next.isComplete) {
        _showMsg('QR Code incompleto. Gere um novo em Configurações > Mesas.', isError: true);
        return;
      }
      await _applySettings(next);
      _showMsg('Mesa ${next.tableCode} pareada com sucesso!');
    } catch (_) {
      _showMsg('QR Code inválido. Escaneie o QR de pareamento do dartchef.', isError: true);
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
          width: 460,
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
            ],
          ),
        ),
        actions: [
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
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    apiCtrl.dispose(); orgCtrl.dispose(); tableCtrl.dispose();
  }

  // ──────────────────── SOBRE dialog ────────────────────

  void _showAboutDialog() {
    final org = _menu?.organizationName ?? _settings?.organizationId ?? 'Restaurante';
    final mesa = _settings?.tableCode ?? '--';
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header com gradiente ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE55525), Color(0xFFFF6B35)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Logo
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        org,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Mesa $mesa',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Corpo ──
                Container(
                  color: const Color(0xFF111111),
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Column(
                    children: [
                      _AboutFeature(
                        icon: Icons.restaurant_menu_rounded,
                        color: AppTheme.accent,
                        title: 'Cardápio Digital',
                        subtitle: 'Navegue pelo cardápio e faça pedidos direto da mesa.',
                      ),
                      _AboutFeature(
                        icon: Icons.bolt_rounded,
                        color: AppTheme.badgeYellow,
                        title: 'Pedidos Instantâneos',
                        subtitle: 'Seu pedido chega à cozinha em segundos.',
                      ),
                      _AboutFeature(
                        icon: Icons.support_agent_rounded,
                        color: AppTheme.success,
                        title: 'Atendimento na Mesa',
                        subtitle: 'Chame o garçom com um toque.',
                      ),
                    ],
                  ),
                ),

                // ── Rodapé ──
                Container(
                  color: const Color(0xFF0D0D0D),
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                        ),
                        child: const Text('DartSoft', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.accent, letterSpacing: 0.5)),
                      ),
                      const SizedBox(width: 8),
                      const Text('Sistema de pedidos para mesas', style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.accent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Fechar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────── Chamadas de serviço ────────────────────

  Future<void> _callService(String callType, String displayName) async {
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
        title: Text('Chamar $displayName?', style: const TextStyle(color: Colors.white)),
        content: Text(
          'Enviaremos uma notificação para $displayName atender a mesa ${settings.tableCode}.',
          style: const TextStyle(color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accent),
            child: Text('Chamar $displayName'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _apiService.callService(settings: settings, callType: callType);
      _showMsg('$displayName foi chamado! Aguarde um momento.');
    } on TabletApiException catch (e) {
      _showMsg(e.message, isError: true);
    } catch (_) {
      _showMsg('Não foi possível enviar a solicitação.', isError: true);
    }
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

  List<MenuProduct> get _filteredProducts {
    final products = _menu?.products ?? [];
    final search = _searchTerm.trim().toLowerCase();
    return products.where((p) {
      final catOk = _activeCategory == 'Todos' || p.category == _activeCategory;
      final subOk = _activeSubcategory == null || p.subcategory == _activeSubcategory;
      final searchOk = search.isEmpty || p.name.toLowerCase().contains(search) || p.brand.toLowerCase().contains(search);
      return catOk && subOk && searchOk;
    }).toList();
  }

  double get _cartTotal => _cart.fold(0.0, (s, i) => s + i.subtotal);
  int get _cartItemCount => _cart.fold(0, (s, i) => s + i.quantity);

  // ──────────────────── Carrinho ────────────────────

  void _addToCart(MenuProduct product) {
    setState(() {
      final idx = _cart.indexWhere((i) => i.product.id == product.id);
      if (idx >= 0) {
        _cart[idx] = _cart[idx].copyWith(quantity: _cart[idx].quantity + 1);
      } else {
        _cart = [..._cart, CartItem(product: product, quantity: 1)];
      }
    });
    _showMsg('${product.name} adicionado!');
  }

  void _changeQty(MenuProduct product, int delta) {
    setState(() {
      final idx = _cart.indexWhere((i) => i.product.id == product.id);
      if (idx < 0) return;
      final next = _cart[idx].quantity + delta;
      if (next <= 0) {
        _cart = [..._cart]..removeAt(idx);
        return;
      }
      final updated = [..._cart];
      updated[idx] = _cart[idx].copyWith(quantity: next);
      _cart = updated;
    });
  }

  void _removeItem(MenuProduct product, int qty) => _changeQty(product, -qty);

  void _openConfirmScreen() {
    if (_cart.isEmpty) { _showMsg('Adicione itens antes de enviar.', isError: true); return; }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ConfirmOrderScreen(
        cart: _cart,
        tableCode: _settings?.tableCode ?? '--',
        onConfirmWithComanda: (comandaCode) {
          _submitOrder(comandaCode);
        },
        sending: _sendingOrder,
      ),
    ));
  }

  Future<void> _submitOrder(String comandaCode) async {
    if (_cart.isEmpty) { _showMsg('Adicione itens antes de enviar.', isError: true); return; }
    final settings = _settings;
    if (settings == null) { _showMsg('Configure o tablet antes.', isError: true); return; }

    final settingsWithComanda = settings.copyWith(tableCode: comandaCode);

    setState(() => _sendingOrder = true);
    try {
      final orderId = await _apiService.submitOrder(
        settings: settingsWithComanda,
        items: _cart,
        customerName: _customerNameController.text,
        notes: _notesController.text,
      );
      if (!mounted) return;
      setState(() {
        _cart = [];
        _customerNameController.clear();
        _notesController.clear();
        _showCart = false;
      });
      _showMsg('Pedido #$orderId enviado para comanda $comandaCode! 🎉');
    } on TabletApiException catch (e) {
      _showMsg(e.message, isError: true);
    } catch (_) {
      _showMsg('Não foi possível enviar o pedido.', isError: true);
    } finally {
      if (mounted) setState(() => _sendingOrder = false);
    }
  }

  // ──────────────────── Content area ────────────────────

  Widget _buildContentArea() {
    if (_loadingMenu && _menu == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 52, color: Color(0xFF888888)),
              const SizedBox(height: 14),
              const Text('Não foi possível carregar o cardápio',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 6),
              Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: Color(0xFFAAAAAA))),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _loadMenu,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
                style: FilledButton.styleFrom(backgroundColor: AppTheme.accent),
              ),
            ],
          ),
        ),
      );
    }

    if (_menu == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.tablet_android_rounded, size: 52, color: Color(0xFF888888)),
              const SizedBox(height: 14),
              const Text('Configure este tablet',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 6),
              const Text('Pressione e segure o logo para configurar.',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Color(0xFFAAAAAA))),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _openSettingsDialog,
                icon: const Icon(Icons.settings_rounded),
                label: const Text('Configurar agora'),
                style: FilledButton.styleFrom(backgroundColor: AppTheme.accent),
              ),
            ],
          ),
        ),
      );
    }

    final products = _filteredProducts;
    // Tela DESTAQUES — hero carrossel + recomendados
    if (_activeCategory == 'Todos' && _searchTerm.isEmpty) {
      return Column(
        children: [
          if (_loadingMenu)
            const LinearProgressIndicator(minHeight: 2, color: AppTheme.accent, backgroundColor: AppTheme.surface),
          Expanded(
            child: products.isEmpty
                ? const Center(child: Text('Nenhum produto disponível.', style: TextStyle(fontSize: 15, color: AppTheme.textMuted)))
                : HomeHighlightsWidget(products: products, currency: _currency, onAdd: _addToCart, organizationName: ''),
          ),
        ],
      );
    }

    // Tela CARDÁPIO — banner + lista de produtos
    return Container(
      color: const Color(0xFF111111),
      child: Column(
        children: [
          if (_loadingMenu)
            const LinearProgressIndicator(minHeight: 2, color: AppTheme.accent, backgroundColor: AppTheme.background),
          Expanded(
            child: products.isEmpty
                ? Center(child: Text(
                    _searchTerm.isNotEmpty ? 'Nenhum produto encontrado.' : 'Nenhum produto nesta categoria.',
                    style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 16)))
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: products.length + 2, // +2: banner + section header
                    itemBuilder: (context, index) {
                      if (index == 0) return _buildCategoryBanner(products);
                      if (index == 1) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(_activeCategory, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                                        const SizedBox(height: 2),
                                        Text(_categorySubtitle(_activeCategory), style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                                      ],
                                    ),
                                  ),
                                  const Text('Ver tudo >', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.accent)),
                                ],
                              ),
                            ),
                            // Sub-category pills (dynamic from API)
                            if ((_menu?.subcategories[_activeCategory] ?? []).isNotEmpty)
                              SizedBox(
                                height: 40,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  children: [
                                    GestureDetector(
                                      onTap: () => setState(() => _activeSubcategory = null),
                                      child: _SubCategoryPill(label: 'Todos', isActive: _activeSubcategory == null),
                                    ),
                                    ...(_menu!.subcategories[_activeCategory]!).map((sub) =>
                                      GestureDetector(
                                        onTap: () => setState(() => _activeSubcategory = sub),
                                        child: _SubCategoryPill(label: sub, isActive: _activeSubcategory == sub),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 4),
                          ],
                        );
                      }
                      final product = products[index - 2];
                      return ProductCardWidget(product: product, currency: _currency, onAdd: () => _addToCart(product));
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _categorySubtitle(String cat) {
    final l = cat.toLowerCase();
    if (l.contains('hambur') || l.contains('burger') || l.contains('lanch')) return 'Feitos com blends exclusivos e ingredientes frescos';
    if (l.contains('pizza')) return 'Massa artesanal assada no forno a lenha';
    if (l.contains('bebida') || l.contains('drink') || l.contains('bar')) return 'Drinks e bebidas para acompanhar sua refeição';
    if (l.contains('sobremesa') || l.contains('doce')) return 'Finalize com um toque de doçura';
    if (l.contains('salada') || l.contains('vegeta')) return 'Opções leves e saudáveis';
    if (l.contains('entrada') || l.contains('porção') || l.contains('porcao')) return 'Para começar bem a sua experiência';
    if (l.contains('prato') || l.contains('principal')) return 'Os favoritos da casa preparados com carinho';
    if (l.contains('suco') || l.contains('fruta')) return 'Sucos naturais e vitaminas refrescantes';
    return 'Selecionados especialmente para você';
  }

  Widget _buildCategoryBanner(List<MenuProduct> products) {
    final firstWithImage = products.firstWhere(
      (p) => p.imageUrl != null && p.imageUrl!.isNotEmpty,
      orElse: () => products.first,
    );
    return SizedBox(
      height: 180,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagem de fundo
          if (firstWithImage.imageUrl != null && firstWithImage.imageUrl!.isNotEmpty)
            Image.network(firstWithImage.imageUrl!, fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF1A1B2E), Color(0xFF0F1B3E)]),
                  ),
                ))
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF1A1B2E), Color(0xFF0F1B3E)]),
              ),
            ),
          // Gradiente escuro
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xF0000000), Color(0x88000000), Color(0x00000000)],
                stops: [0.0, 0.5, 1.0],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          // Conteúdo
          Positioned(
            left: 24,
            right: 24,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    '${products.length} ${products.length == 1 ? 'ITEM' : 'ITENS'}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _activeCategory,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1),
                ),
                const SizedBox(height: 4),
                Text(
                  _categorySubtitle(_activeCategory),
                  style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.75)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  List<MenuProduct> get _suggestions {
    final all = _menu?.products ?? [];
    final cartIds = _cart.map((i) => i.product.id).toSet();
    final others = all.where((p) => !cartIds.contains(p.id)).toList();
    return others.take(3).toList();
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

    final categories = _menu?.categories ?? [];
    final tableCode = _settings?.tableCode ?? '--';
    final showCartPanel = _menu != null; // always show right panel when menu is loaded

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Row(
            children: [
              // ── Sidebar com categorias integradas ──
              SidebarWidget(
                categories: categories,
                activeCategory: _activeCategory,
                onCategorySelected: (cat) => setState(() { _activeCategory = cat; _activeSubcategory = null; _searchTerm = ''; }),
                onSettingsTap: _openSettingsDialog,
                onAboutTap: _showAboutDialog,
              ),

              // ── Conteúdo principal ──
              Expanded(
                child: Column(
                  children: [
                    TopBarWidget(
                      tableCode: tableCode,
                      cartItemCount: _cartItemCount,
                      onSearchChanged: (v) => setState(() => _searchTerm = v),
                      onCartTap: () => setState(() => _showCart = !_showCart),
                      onCallWaiter: () => _callService('garcom', 'Garçom'),
                      onMyAccount: _showMyOrders,
                      onRefresh: _loadMenu,
                    ),
                    Expanded(child: _buildContentArea()),
                  ],
                ),
              ),

              // ── Painel do carrinho (direita) ──
              if (showCartPanel)
                CartPanelWidget(
                  cart: _cart,
                  currency: _currency,
                  cartTotal: _cartTotal,
                  sendingOrder: _sendingOrder,
                  suggestions: _suggestions,
                  onAddSuggestion: _addToCart,
                  onChangeQuantity: _changeQty,
                  onRemoveItem: _removeItem,
                  onSubmitOrder: _openConfirmScreen,
                ),
            ],
          ),
        ),
      ),
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

class _SubCategoryPill extends StatelessWidget {
  const _SubCategoryPill({required this.label, required this.isActive});
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.accent : AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: isActive ? null : Border.all(color: AppTheme.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.white : AppTheme.textMuted,
        ),
      ),
    );
  }
}

// ──────────────────── Helper widgets ────────────────────

class _AboutFeature extends StatelessWidget {
  const _AboutFeature({required this.icon, required this.color, required this.title, required this.subtitle});
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF999999), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

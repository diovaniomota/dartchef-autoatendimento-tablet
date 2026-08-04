import 'package:flutter/material.dart';

import '../core/app_language.dart';
import '../core/app_theme.dart';
import 'flag_icon.dart';

class TopBarWidget extends StatelessWidget {
  const TopBarWidget({
    super.key,
    required this.tableCode,
    required this.cartItemCount,
    required this.onSearchChanged,
    required this.onCartTap,
    required this.onCallWaiter,
    required this.onMyAccount,
    required this.onRequestBill,
    required this.onRefresh,
  });

  // organizationName não é mais usado no top bar (removido do print)
  final String tableCode;
  final int cartItemCount;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onCartTap;
  final VoidCallback onCallWaiter;
  final VoidCallback onMyAccount;
  final VoidCallback onRequestBill;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        children: [
          // Campo de busca
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.search_rounded, size: 20, color: AppTheme.textMuted),
                  ),
                  Expanded(
                    child: TextField(
                      onChanged: onSearchChanged,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: t('search.hint'),
                        hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // MESA badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.table_restaurant_rounded, size: 16, color: AppTheme.textMuted),
                const SizedBox(width: 6),
                Text(
                  t2('topbar.table', {'code': tableCode}),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.3),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // GARÇOM (so icone - texto nao cabe em tablets de tela estreita)
          _TopButton(icon: Icons.support_agent_rounded, label: t('topbar.waiter'), onTap: onCallWaiter, iconOnly: true),
          const SizedBox(width: 8),

          // MINHA CONTA (so icone - texto nao cabe em tablets de tela estreita)
          // Abre o historico do que a mesa consumiu, sem avisar o salao.
          _TopButton(icon: Icons.receipt_long_rounded, label: t('topbar.myBill'), onTap: onMyAccount, iconOnly: true),
          const SizedBox(width: 8),

          // PEDIR A CONTA — diferente de "Minha conta": avisa o salao, e o
          // pedido aparece no sistema igual a chamada de garcom.
          _TopButton(icon: Icons.point_of_sale_rounded, label: t('topbar.requestBill'), onTap: onRequestBill, iconOnly: true),
          const SizedBox(width: 8),

          // IDIOMA (bandeira atual; abre a escolha)
          const LanguageButton(),
          const SizedBox(width: 8),

          // ATUALIZAR
          _TopButton(icon: Icons.refresh_rounded, label: '', onTap: onRefresh, iconOnly: true),
          const SizedBox(width: 12),

          // MEU PEDIDO (CTA principal)
          GestureDetector(
            onTap: onCartTap,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: cartItemCount > 0 ? AppTheme.accent : AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: cartItemCount > 0 ? null : Border.all(color: AppTheme.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_rounded, size: 18, color: cartItemCount > 0 ? Colors.white : AppTheme.textMuted),
                  const SizedBox(width: 7),
                  Text(
                    cartItemCount > 0
                        ? t2('topbar.myOrderCount', {'count': '$cartItemCount'})
                        : t('topbar.myOrder'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: cartItemCount > 0 ? Colors.white : AppTheme.textMuted,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopButton extends StatelessWidget {
  const _TopButton({required this.icon, required this.label, required this.onTap, this.iconOnly = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final button = InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        height: 44,
        padding: EdgeInsets.symmetric(horizontal: iconOnly ? 12 : 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: AppTheme.textMuted),
            if (!iconOnly && label.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted, letterSpacing: 0.3)),
            ],
          ],
        ),
      ),
    );

    // Botao so-icone: mantem o rotulo acessivel via toque longo, ja que o
    // texto foi removido pra caber em tablets de tela estreita.
    if (iconOnly && label.isNotEmpty) {
      return Tooltip(message: label, child: button);
    }
    return button;
  }
}

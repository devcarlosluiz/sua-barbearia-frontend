import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/responsive.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/engagement_providers.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/widgets.dart';
import '../auth/widgets/auth_scaffold.dart';

/// Item de navegação de um shell.
class NavItem {
  const NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    this.showInBottomBar = true,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
  final bool showInBottomBar;
}

/// Casca de navegação usada pelas três áreas do app.
///
/// Desktop/tablet: sidebar fixa + topbar. Mobile: AppBar + bottom navigation
/// (com os itens excedentes em um menu "Mais").
class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.items,
    required this.child,
    this.floatingActionButton,
  });

  final String title;
  final List<NavItem> items;
  final Widget child;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final hasSidebar = Responsive.hasSidebar(context);

    if (hasSidebar) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(items: items, location: location),
            Expanded(
              child: Column(
                children: [
                  _TopBar(title: title),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: floatingActionButton,
      );
    }

    final bottomItems = items.where((item) => item.showInBottomBar).toList();
    final overflowItems = items.where((item) => !item.showInBottomBar).toList();
    final currentIndex = _indexFor(bottomItems, location);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          const _ThemeMenuButton(),
          const _NotificationsButton(),
          _ProfileMenu(overflowItems: overflowItems),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: child,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex < 0 ? 0 : currentIndex,
        onDestinationSelected: (index) => context.go(bottomItems[index].route),
        destinations: bottomItems
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }

  static int _indexFor(List<NavItem> items, String location) {
    return items.indexWhere((item) => location.startsWith(item.route));
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.items, required this.location});

  final List<NavItem> items;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);

    return Container(
      width: AppSpacing.sidebarWidth,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(right: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            child: SuaBarbeariaWordmark(),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = location.startsWith(item.route);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  // A sidebar tem fundo próprio (um `DecoratedBox`), que fica
                  // entre o `ListTile` e o `Material` mais próximo — e cobre a
                  // cor do item selecionado e o efeito de toque. Dar um
                  // `Material` transparente aqui devolve a superfície de pintura
                  // para dentro do fundo.
                  child: Material(
                    type: MaterialType.transparency,
                    child: ListTile(
                      dense: true,
                      selected: isSelected,
                      selectedTileColor: AppColors.gold.withValues(alpha: 0.12),
                      selectedColor: theme.colorScheme.onSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      leading: Icon(
                        isSelected ? item.selectedIcon : item.icon,
                        size: 20,
                        color: isSelected
                            ? AppColors.gold
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      title: Text(
                        item.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      onTap: () => context.go(item.route),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                AppAvatar(
                  name: user?.name ?? 'Sua Barbearia',
                  imageUrl: user?.avatarUrl,
                  size: 38,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? '',
                        style: theme.textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user?.role.label ?? '',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Sair',
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  onPressed: () => _confirmLogout(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
          const _ThemeMenuButton(),
          const _NotificationsButton(),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
    );
  }
}

/// Escolha do tema: claro, escuro ou o do sistema.
///
/// Um menu explícito, e não um botão que inverte no toque: com três estados
/// possíveis, um toggle esconderia a opção "seguir o sistema" atrás de um
/// gesto que ninguém descobre.
///
/// Usa `IconButton` + `showMenu` em vez de `PopupMenuButton`: o botão embutido
/// no `PopupMenuButton` não estava aparecendo no build web, enquanto o
/// `IconButton` do sino ao lado — mesmo contexto, mesma `Row` — aparece. Com o
/// `IconButton` explícito o ícone segue exatamente o mesmo caminho de
/// renderização e de resolução de cor do que já funciona.
class _ThemeMenuButton extends ConsumerWidget {
  const _ThemeMenuButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mode = ref.watch(themeModeProvider);
    final isDark = theme.brightness == Brightness.dark;

    return IconButton(
      tooltip: 'Tema: ${ThemeModeController.labelFor(mode)}',
      // Cor explícita: não depender do `IconTheme` ambiente elimina a chance
      // de o ícone sair da mesma cor do fundo da barra.
      color: theme.colorScheme.onSurface,
      // O ícone mostra o brilho em uso, não o modo guardado: em "seguir o
      // sistema" é o efetivo que a pessoa enxerga na tela.
      //
      // Sol/lua vêm de `wb_sunny_rounded` e `nightlight_rounded`, e não de
      // `light_mode_rounded`/`dark_mode_rounded`: estes últimos saem em branco
      // no build web deste projeto. O glifo está presente na fonte, então a
      // falha é do CanvasKit ao desenhá-lo — os ícones abaixo foram conferidos
      // renderizando na tela.
      icon: Icon(isDark ? Icons.nightlight_rounded : Icons.wb_sunny_rounded),
      onPressed: () => _escolherTema(context, ref, mode),
    );
  }

  Future<void> _escolherTema(
    BuildContext context,
    WidgetRef ref,
    ThemeMode atual,
  ) async {
    final botao = context.findRenderObject() as RenderBox?;
    final overlay =
        Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;
    if (botao == null || overlay == null) return;

    final posicao = RelativeRect.fromRect(
      Rect.fromPoints(
        botao.localToGlobal(botao.size.bottomLeft(Offset.zero),
            ancestor: overlay),
        botao.localToGlobal(botao.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final escolhido = await showMenu<ThemeMode>(
      context: context,
      position: posicao,
      initialValue: atual,
      items: [
        for (final option in ThemeMode.values)
          PopupMenuItem<ThemeMode>(
            value: option,
            child: Row(
              children: [
                Icon(ThemeModeController.iconFor(option), size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(ThemeModeController.labelFor(option))),
                if (option == atual)
                  const Icon(Icons.task_alt_rounded, size: 16),
              ],
            ),
          ),
      ],
    );

    if (escolhido != null) {
      await ref.read(themeModeProvider.notifier).setMode(escolhido);
    }
  }
}

/// Escolha do tema em uma folha, com os rótulos escritos.
///
/// Aberta pelo menu do avatar. Diferente do menu ancorado no botão da barra,
/// não precisa de um `RenderBox` de referência — funciona de qualquer lugar.
Future<void> escolherTemaEmFolha(BuildContext context, WidgetRef ref) async {
  final atual = ref.read(themeModeProvider);

  final escolhido = await showModalBottomSheet<ThemeMode>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in ThemeMode.values)
            ListTile(
              leading: Icon(ThemeModeController.iconFor(option)),
              title: Text(ThemeModeController.labelFor(option)),
              trailing: option == atual
                  ? const Icon(Icons.task_alt_rounded, size: 18)
                  : null,
              onTap: () => Navigator.of(context).pop(option),
            ),
        ],
      ),
    ),
  );

  if (escolhido != null) {
    await ref.read(themeModeProvider.notifier).setMode(escolhido);
  }
}

class _NotificationsButton extends ConsumerWidget {
  const _NotificationsButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsProvider);

    return IconButton(
      tooltip: 'Notificações',
      onPressed: () => _openNotifications(context, ref),
      icon: AppCountBadge(
        count: unread.valueOrNull ?? 0,
        child: const Icon(Icons.notifications_none_rounded),
      ),
    );
  }
}

class _ProfileMenu extends ConsumerWidget {
  const _ProfileMenu({required this.overflowItems});

  final List<NavItem> overflowItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return PopupMenuButton<String>(
      tooltip: 'Menu',
      offset: const Offset(0, 48),
      icon: AppAvatar(
        name: user?.name ?? 'Sua Barbearia',
        imageUrl: user?.avatarUrl,
        size: 32,
      ),
      onSelected: (value) {
        if (value == '__logout__') {
          _confirmLogout(context, ref);
          return;
        }
        if (value == '__theme__') {
          escolherTemaEmFolha(context, ref);
          return;
        }
        context.go(value);
      },
      itemBuilder: (context) => [
        for (final item in overflowItems)
          PopupMenuItem<String>(
            value: item.route,
            child: Row(
              children: [
                Icon(item.icon, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Text(item.label),
              ],
            ),
          ),
        if (overflowItems.isNotEmpty) const PopupMenuDivider(),
        // O botão de tema na barra depende de um glifo da fonte de ícones ser
        // desenhado — e neste projeto já falhou duas vezes no web. Aqui a opção
        // aparece escrita: texto não some por problema de fonte de ícone.
        PopupMenuItem<String>(
          value: '__theme__',
          child: Row(
            children: [
              Icon(ThemeModeController.iconFor(ref.watch(themeModeProvider)),
                  size: 18),
              const SizedBox(width: AppSpacing.xs),
              // Rótulo curto e `Expanded`: o menu é estreito no celular, e
              // "Tema: Seguir o sistema" estourava a largura. Qual modo está
              // ativo aparece marcado dentro da folha.
              const Expanded(
                child: Text('Tema', overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: '__logout__',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 18),
              SizedBox(width: AppSpacing.xs),
              Text('Sair'),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
  final confirmed = await AppDialog.confirm(
    context,
    title: 'Sair da conta',
    message: 'Você precisará entrar novamente para acessar o sistema.',
    confirmLabel: 'Sair',
    isDestructive: true,
    icon: Icons.logout_rounded,
  );
  if (!confirmed) return;

  await ref.read(authControllerProvider.notifier).logout();
  if (context.mounted) context.go(AppRoutes.login);
}

Future<void> _openNotifications(BuildContext context, WidgetRef ref) async {
  await AppBottomSheet.show<void>(
    context,
    title: 'Notificações',
    child: const NotificationsSheet(),
  );
  ref.invalidate(unreadNotificationsProvider);
  ref.invalidate(notificationsProvider);
}

/// Conteúdo do painel de notificações.
class NotificationsSheet extends ConsumerWidget {
  const NotificationsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final theme = Theme.of(context);

    return AsyncView(
      value: notifications,
      onRetry: () => ref.invalidate(notificationsProvider),
      emptyMessage: 'Você está em dia — nenhuma notificação por aqui.',
      isEmpty: (items) => items.isEmpty,
      emptyIcon: Icons.notifications_off_outlined,
      builder: (items) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                await ref.read(engagementRepositoryProvider).markRead();
                ref.invalidate(notificationsProvider);
                ref.invalidate(unreadNotificationsProvider);
              },
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Marcar todas como lidas'),
            ),
          ),
          ...items.map(
            (notification) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: AppCard(
                color: notification.isRead
                    ? null
                    : AppColors.gold.withValues(alpha: 0.07),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            height: 8,
                            width: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(notification.body, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

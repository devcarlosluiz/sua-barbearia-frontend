import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../providers/branding_provider.dart';

/// Layout das telas de autenticação.
///
/// No desktop, painel de marca à esquerda e formulário à direita; no mobile,
/// uma única coluna com o logo no topo.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final isWide = !Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: isWide
            ? Row(
                children: [
                  const Expanded(flex: 5, child: _BrandPanel()),
                  Expanded(flex: 6, child: _buildForm(context, maxWidth: 460)),
                ],
              )
            : _buildForm(context, maxWidth: 520, showLogo: true),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context, {
    required double maxWidth,
    bool showLogo = false,
  }) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (onBack != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: TextButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Voltar'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              if (showLogo) ...[
                const SuaBarbeariaWordmark(),
                const SizedBox(height: AppSpacing.xl),
              ],
              Text(title, style: theme.textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xl),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.black, AppColors.charcoal, AppColors.graphite],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SuaBarbeariaWordmark(inverted: true, large: true),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'A gestão completa da sua barbearia,\nem um só lugar.',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.white,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const _BrandFeature(
              icon: Icons.event_available_rounded,
              text: 'Agenda inteligente, sem conflito de horários',
            ),
            const _BrandFeature(
              icon: Icons.store_mall_directory_rounded,
              text: 'Várias filiais sob o mesmo controle',
            ),
            const _BrandFeature(
              icon: Icons.insights_rounded,
              text: 'Financeiro, comissões e relatórios em tempo real',
            ),
            const _BrandFeature(
              icon: Icons.workspace_premium_rounded,
              text: 'Fidelidade que traz o cliente de volta',
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandFeature extends StatelessWidget {
  const _BrandFeature({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.greyLight),
            ),
          ),
        ],
      ),
    );
  }
}

/// Assinatura visual da marca Sua Barbearia.
class SuaBarbeariaWordmark extends ConsumerWidget {
  const SuaBarbeariaWordmark({
    super.key,
    this.inverted = false,
    this.large = false,
  });

  /// Sobre fundo escuro (painel do login, splash).
  final bool inverted;
  final bool large;

  /// Altura de desenho da logo enviada.
  ///
  /// Maior que a da marca padrão (40/52 px): aquela é um ícone somado a duas
  /// linhas de texto, que já ocupam a largura toda. A logo do proprietário é
  /// uma imagem só, e na mesma altura ficava visivelmente pequena.
  double get _logoHeight => large ? 100 : 62;

  /// Teto de largura, para uma logo muito deitada não empurrar o resto da
  /// barra. `BoxFit.contain` reduz a altura proporcionalmente se bater aqui.
  ///
  /// Na barra lateral o teto é o espaço real disponível: 264 px de largura
  /// menos 16 de recuo de cada lado.
  double get _logoMaxWidth => large ? 440 : 224;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A logo é opcional e nunca pode travar a interface: enquanto carrega, ou
    // se a requisição falhar, a marca padrão é desenhada.
    final logoUrl = ref.watch(brandingProvider).valueOrNull?.logoUrl;
    if (logoUrl == null || logoUrl.isEmpty) {
      return _DefaultWordmark(inverted: inverted, large: large);
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: _logoHeight,
        maxWidth: _logoMaxWidth,
      ),
      // `Image.network`, e não `CachedNetworkImage`: na web este usa a própria
      // tag de imagem do navegador, que já tem cache HTTP e não passa por XHR.
      // Com o `CachedNetworkImage` a logo ficava presa carregando e o espaço
      // aparecia vazio, sem nunca chamar o `errorWidget`.
      child: Image.network(
        logoUrl,
        height: _logoHeight,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        // Enquanto carrega e se falhar, a marca padrão ocupa o lugar. Um buraco
        // no cabeçalho é pior do que uma marca provisória.
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : _DefaultWordmark(inverted: inverted, large: large),
        errorBuilder: (context, _, __) =>
            _DefaultWordmark(inverted: inverted, large: large),
      ),
    );
  }
}

/// Marca desenhada enquanto o proprietário não envia uma logo.
///
/// O texto é o nome configurado da barbearia, não uma constante: trocar o nome
/// nas configurações precisa refletir em todo lugar onde a marca aparece.
class _DefaultWordmark extends ConsumerWidget {
  const _DefaultWordmark({required this.inverted, required this.large});

  final bool inverted;
  final bool large;

  /// Divide o nome em marca + descritor, como "SUA" + "BARBEARIA".
  ///
  /// A última palavra vira a linha de baixo quando há mais de uma; com um nome
  /// de palavra única, a segunda linha simplesmente não aparece. Isso preserva
  /// o desenho original sem obrigar o proprietário a pensar em duas partes.
  static (String, String?) splitName(String nome) {
    final partes = nome.trim().split(RegExp(r'\s+'));
    if (partes.length < 2) return (nome.trim().toUpperCase(), null);
    final descritor = partes.removeLast();
    return (partes.join(' ').toUpperCase(), descritor.toUpperCase());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final baseColor = inverted ? AppColors.white : theme.colorScheme.onSurface;
    final nome =
        ref.watch(brandingProvider).valueOrNull?.companyName ?? 'Sua Barbearia';
    final (marca, descritor) = splitName(nome);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: large ? 52 : 40,
          width: large ? 52 : 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.goldLight, AppColors.gold, AppColors.goldDark],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            Icons.content_cut_rounded,
            color: AppColors.black,
            size: large ? 28 : 22,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              marca,
              style: (large
                      ? theme.textTheme.headlineMedium
                      : theme.textTheme.titleLarge)
                  ?.copyWith(
                color: baseColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            if (descritor != null)
              Text(
                descritor,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.gold,
                  letterSpacing: 4,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

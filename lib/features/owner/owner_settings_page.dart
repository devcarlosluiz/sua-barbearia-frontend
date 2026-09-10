import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/app_config.dart';
import '../../core/errors/api_exception.dart';
import '../../core/responsive/responsive.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/branding.dart';
import '../../models/loyalty.dart';
import '../../providers/auth_provider.dart';
import '../../providers/branding_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/engagement_providers.dart';
import '../../widgets/widgets.dart';

class OwnerSettingsPage extends ConsumerWidget {
  const OwnerSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final rewards = ref.watch(allLoyaltyRewardsProvider);

    return ListView(
      padding: Responsive.pagePadding(context),
      children: [
        const AppSectionHeader(title: 'Minha conta'),
        AppCard(
          child: Row(
            children: [
              AvatarPicker(
                name: user?.name ?? 'Proprietário',
                imageUrl: user?.avatarUrl,
                size: 64,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? '',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      user?.email ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    const AppBadge(
                      label: 'Proprietário',
                      color: AppColors.gold,
                      icon: Icons.shield_rounded,
                      dense: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const AppSectionHeader(
          title: 'Programa de fidelidade',
          subtitle: 'Recompensas que o cliente pode resgatar com pontos.',
        ),
        AsyncView<List<LoyaltyReward>>(
          value: rewards,
          onRetry: () => ref.invalidate(allLoyaltyRewardsProvider),
          emptyMessage: 'Nenhuma recompensa cadastrada.',
          isEmpty: (items) => items.isEmpty,
          emptyIcon: Icons.card_giftcard_rounded,
          emptyActionLabel: 'Criar recompensa',
          onEmptyAction: () => _openRewardForm(context),
          builder: (items) => Column(
            children: [
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var index = 0; index < items.length; index++) ...[
                      if (index > 0) const Divider(height: 1),
                      ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0x22C8A24A),
                          child: Icon(
                            Icons.card_giftcard_rounded,
                            color: AppColors.gold,
                            size: 18,
                          ),
                        ),
                        title: Text(items[index].name),
                        subtitle: Text(
                          '${items[index].pointsCost} pontos · '
                          '${items[index].typeLabel}'
                          '${items[index].discountValue > 0 ? ' · ${Formatters.currency(items[index].discountValue)}' : ''}',
                        ),
                        trailing: AppBadge(
                          label: items[index].isActive ? 'Ativa' : 'Inativa',
                          color: items[index].isActive
                              ? AppColors.success
                              : AppColors.grey,
                          dense: true,
                        ),
                        onTap: () =>
                            _openRewardForm(context, reward: items[index]),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton.outline(
                label: 'Nova recompensa',
                icon: Icons.add_rounded,
                onPressed: () => _openRewardForm(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const AppSectionHeader(
          title: 'Identidade visual',
          subtitle: 'A logo aparece no aplicativo inteiro e na tela de login.',
        ),
        const _LogoCard(),
        const SizedBox(height: AppSpacing.lg),
        const AppSectionHeader(title: 'Sistema'),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.lock_outline_rounded),
                title: const Text('Alterar minha senha'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => AppBottomSheet.show<void>(
                  context,
                  title: 'Alterar senha',
                  child: const _OwnerPasswordForm(),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.api_rounded),
                title: const Text('Servidor da API'),
                subtitle: Text(AppConfig.apiUrl),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.menu_book_rounded),
                title: const Text('Documentação da API'),
                subtitle: Text('${AppConfig.apiBaseUrl}/api/docs/'),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.info_outline_rounded),
                title: Text('Versão'),
                subtitle: Text('Sua Barbearia 1.0.0'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.logout_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Sair da conta',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () async {
                  final confirmed = await AppDialog.confirm(
                    context,
                    title: 'Sair da conta',
                    message: 'Você precisará entrar novamente.',
                    confirmLabel: 'Sair',
                    isDestructive: true,
                  );
                  if (!confirmed) return;
                  await ref.read(authControllerProvider.notifier).logout();
                  if (context.mounted) context.go(AppRoutes.login);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  static Future<void> _openRewardForm(
    BuildContext context, {
    LoyaltyReward? reward,
  }) async {
    await AppBottomSheet.show<void>(
      context,
      title: reward == null ? 'Nova recompensa' : 'Editar recompensa',
      child: _RewardForm(reward: reward),
    );
  }
}

class _RewardForm extends ConsumerStatefulWidget {
  const _RewardForm({this.reward});

  final LoyaltyReward? reward;

  @override
  ConsumerState<_RewardForm> createState() => _RewardFormState();
}

class _RewardFormState extends ConsumerState<_RewardForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.reward?.name ?? '');
  late final TextEditingController _description =
      TextEditingController(text: widget.reward?.description ?? '');
  late final TextEditingController _points = TextEditingController(
    text: '${widget.reward?.pointsCost ?? 500}',
  );
  late final TextEditingController _value = TextEditingController(
    text: (widget.reward?.discountValue ?? 20).toStringAsFixed(2),
  );

  late String _type = widget.reward?.type ?? 'DISCOUNT_FIXED';
  late bool _isActive = widget.reward?.isActive ?? true;
  bool _isLoading = false;

  static const _types = {
    'DISCOUNT_FIXED': 'Desconto em reais',
    'DISCOUNT_PERCENT': 'Desconto percentual',
  };

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _points.dispose();
    _value.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(engagementRepositoryProvider).saveReward(
        {
          'name': _name.text.trim(),
          'description': _description.text.trim(),
          'type': _type,
          'points_cost': int.parse(_points.text),
          'discount_value':
              double.parse(_value.text.replaceAll(',', '.')).toStringAsFixed(2),
          'is_active': _isActive,
        },
        id: widget.reward?.id,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      AppFeedback.success(
        context,
        widget.reward == null ? 'Recompensa criada.' : 'Recompensa atualizada.',
      );
      ref.invalidate(allLoyaltyRewardsProvider);
      ref.invalidate(loyaltyRewardsProvider);
    } on ApiException catch (error) {
      if (mounted) AppFeedback.error(context, error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'Nome',
            controller: _name,
            hint: 'Ex.: Desconto de R\$ 20',
            isRequired: true,
            validator: (value) => Validators.required(value, field: 'O nome'),
          ),
          const SizedBox(height: AppSpacing.md),
          AppDropdown<String>(
            label: 'Tipo',
            items: _types.keys.toList(),
            value: _type,
            isRequired: true,
            itemLabel: (value) => _types[value]!,
            onChanged: (value) =>
                setState(() => _type = value ?? 'DISCOUNT_FIXED'),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Custo em pontos',
                  controller: _points,
                  keyboardType: TextInputType.number,
                  isRequired: true,
                  validator: Validators.positiveInteger,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(
                  label: _type == 'DISCOUNT_PERCENT'
                      ? 'Desconto (%)'
                      : 'Valor (R\$)',
                  controller: _value,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [MoneyInputFormatter()],
                  isRequired: true,
                  validator: Validators.money,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Descrição',
            controller: _description,
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile.adaptive(
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
            title: const Text('Recompensa ativa'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: widget.reward == null ? 'Criar recompensa' : 'Salvar',
            isLoading: _isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _OwnerPasswordForm extends ConsumerStatefulWidget {
  const _OwnerPasswordForm();

  @override
  ConsumerState<_OwnerPasswordForm> createState() => _OwnerPasswordFormState();
}

class _OwnerPasswordFormState extends ConsumerState<_OwnerPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirm = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _current.dispose();
    _newPassword.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(authRepositoryProvider).changePassword(
            currentPassword: _current.text,
            newPassword: _newPassword.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      AppFeedback.success(context, 'Senha alterada com sucesso.');
    } on ApiException catch (error) {
      if (mounted) {
        AppFeedback.error(
          context,
          error.errorFor('current_password') ?? error.message,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'Senha atual',
            controller: _current,
            obscureText: true,
            isRequired: true,
            validator: (value) =>
                Validators.required(value, field: 'A senha atual'),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Nova senha',
            controller: _newPassword,
            obscureText: true,
            isRequired: true,
            helper: 'Mínimo de 8 caracteres.',
            validator: Validators.password,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Confirmar nova senha',
            controller: _confirm,
            obscureText: true,
            isRequired: true,
            validator: Validators.confirmPassword(() => _newPassword.text),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Alterar senha',
            isLoading: _isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

/// Envio e remoção da logo do sistema.
///
/// O tamanho recomendado vem do backend (`recommended_width/height`) para a
/// orientação exibida aqui não sair do ar quando a regra mudar lá.
class _LogoCard extends ConsumerStatefulWidget {
  const _LogoCard();

  @override
  ConsumerState<_LogoCard> createState() => _LogoCardState();
}

class _LogoCardState extends ConsumerState<_LogoCard> {
  final _nome = TextEditingController();
  bool _isWorking = false;
  bool _isSavingName = false;

  /// Nome já carregado no campo, para não sobrescrever o que está sendo
  /// digitado a cada reconstrução do provider.
  String? _nomeCarregado;

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  void _sincronizaNome(String atual) {
    if (_nomeCarregado == atual) return;
    _nomeCarregado = atual;
    _nome.text = atual;
  }

  Future<void> _salvarNome() async {
    final nome = _nome.text.trim();
    if (nome.length < 2) {
      AppFeedback.error(context, 'Informe ao menos 2 caracteres.');
      return;
    }

    setState(() => _isSavingName = true);
    try {
      await ref.read(brandingRepositoryProvider).updateName(nome);
      if (!mounted) return;
      _nomeCarregado = nome;
      ref.invalidate(brandingProvider);
      AppFeedback.success(context, 'Nome atualizado.');
    } on ApiException catch (error) {
      if (mounted) {
        AppFeedback.error(
          context,
          error.errorFor('company_name') ?? error.message,
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingName = false);
    }
  }

  Future<void> _enviar() async {
    final XFile? escolhido;
    try {
      escolhido = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        // Não redimensiona aqui: o backend normaliza e valida, e limitar no
        // cliente esconderia do proprietário o motivo de uma recusa.
        requestFullMetadata: false,
      );
    } catch (error, stackTrace) {
      // Um seletor que não abre precisa dizer isso. Este botão já ficou mudo
      // uma vez, quando o plugin não entrou no build web, e não havia como o
      // proprietário saber que o problema não era ele.
      debugPrint('[Logo] falha ao abrir o seletor de imagem: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        AppFeedback.error(
          context,
          'Não foi possível abrir o seletor de imagens neste dispositivo.',
        );
      }
      return;
    }

    if (escolhido == null || !mounted) return;

    setState(() => _isWorking = true);
    try {
      // Bytes, e não caminho: na web não existe caminho de arquivo.
      final bytes = await escolhido.readAsBytes();
      await ref.read(brandingRepositoryProvider).uploadLogo(
            bytes: bytes,
            filename: escolhido.name,
          );
      if (!mounted) return;
      ref.invalidate(brandingProvider);
      AppFeedback.success(context, 'Logo atualizada.');
    } on ApiException catch (error) {
      if (mounted) {
        // A mensagem do campo `logo` explica o motivo exato da recusa
        // (tamanho, dimensões, formato) — bem melhor que o texto genérico.
        AppFeedback.error(context, error.errorFor('logo') ?? error.message);
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _remover() async {
    final confirmado = await AppDialog.confirm(
      context,
      title: 'Voltar à logo padrão?',
      message: 'A sua logo será removida e o aplicativo passa a exibir a marca '
          'padrão do aplicativo.',
      confirmLabel: 'Remover',
      isDestructive: true,
      icon: Icons.image_not_supported_outlined,
    );
    if (!confirmado || !mounted) return;

    setState(() => _isWorking = true);
    try {
      await ref.read(brandingRepositoryProvider).removeLogo();
      if (!mounted) return;
      ref.invalidate(brandingProvider);
      AppFeedback.success(context, 'Logo removida.');
    } on ApiException catch (error) {
      if (mounted) AppFeedback.error(context, error.message);
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final branding = ref.watch(brandingProvider);

    return AppCard(
      child: AsyncView<Branding>(
        value: branding,
        onRetry: () => ref.invalidate(brandingProvider),
        builder: (data) {
          _sincronizaNome(data.companyName);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'Nome da barbearia',
                controller: _nome,
                isRequired: true,
                helper: 'Aparece na marca do aplicativo, no título da página '
                    'e na tela de login.',
                validator: (value) =>
                    Validators.required(value, field: 'O nome'),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton.outline(
                label: 'Salvar nome',
                icon: Icons.check_rounded,
                isLoading: _isSavingName,
                onPressed: _salvarNome,
              ),
              const Divider(height: AppSpacing.xl),
              Text('Logo', style: theme.textTheme.labelLarge),
              const SizedBox(height: AppSpacing.xs),
              Container(
                height: 112,
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                alignment: Alignment.center,
                child: data.hasLogo
                    // Mesmo motivo do cabeçalho: na web a tag de imagem do
                    // navegador carrega de forma confiável, enquanto o
                    // `CachedNetworkImage` ficava preso sem exibir nada.
                    ? Image.network(
                        data.logoUrl!,
                        height: 72,
                        fit: BoxFit.contain,
                        errorBuilder: (context, _, __) =>
                            const Text('Não foi possível carregar a logo.'),
                      )
                    : Text(
                        'Usando a marca padrão do aplicativo',
                        style: theme.textTheme.bodySmall,
                      ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child:
                        Text(data.uploadHint, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'A logo é desenhada com altura fixa e largura proporcional — '
                'formatos deitados funcionam melhor. Use fundo transparente para '
                'ela ficar boa nos temas claro e escuro.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: data.hasLogo ? 'Trocar logo' : 'Enviar logo',
                      icon: Icons.upload_rounded,
                      isLoading: _isWorking,
                      onPressed: _enviar,
                    ),
                  ),
                  if (data.hasLogo) ...[
                    const SizedBox(width: AppSpacing.sm),
                    AppButton.outline(
                      label: 'Remover',
                      expanded: false,
                      onPressed: _isWorking ? null : _remover,
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

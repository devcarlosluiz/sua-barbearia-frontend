import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/api_exception.dart';
import '../../core/responsive/responsive.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/barber.dart';
import '../../models/branch.dart';
import '../../models/client.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_providers.dart';
import '../../providers/client_providers.dart';
import '../../providers/core_providers.dart';
import '../../widgets/widgets.dart';

class ClientProfilePage extends ConsumerWidget {
  const ClientProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(myClientProfileProvider);

    return AsyncView<Client>(
      value: profile,
      onRetry: () => ref.invalidate(myClientProfileProvider),
      builder: (client) => ListView(
        padding: Responsive.pagePadding(context),
        children: [
          AppCard(
            child: Row(
              children: [
                AvatarPicker(
                  name: user?.name ?? client.name,
                  imageUrl: user?.avatarUrl,
                  size: 64,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        client.email,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (client.phone.isNotEmpty)
                        Text(
                          Formatters.phone(client.phone),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const AppSectionHeader(title: 'Dados pessoais'),
          _PersonalDataForm(client: client),
          const SizedBox(height: AppSpacing.lg),
          const AppSectionHeader(title: 'Preferências'),
          _PreferencesForm(client: client),
          const SizedBox(height: AppSpacing.lg),
          const AppSectionHeader(title: 'Conta'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline_rounded),
                  title: const Text('Alterar senha'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _changePassword(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.history_rounded),
                  title: const Text('Histórico de atendimentos'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.go(AppRoutes.clientHistory),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.logout_rounded,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Sair da conta',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  onTap: () => _logout(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    await AppBottomSheet.show<void>(
      context,
      title: 'Alterar senha',
      child: const _ChangePasswordForm(),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Sair da conta',
      message: 'Você precisará entrar novamente para acessar o aplicativo.',
      confirmLabel: 'Sair',
      isDestructive: true,
      icon: Icons.logout_rounded,
    );
    if (!confirmed) return;

    await ref.read(authControllerProvider.notifier).logout();
    if (context.mounted) context.go(AppRoutes.login);
  }
}

class _PersonalDataForm extends ConsumerStatefulWidget {
  const _PersonalDataForm({required this.client});

  final Client client;

  @override
  ConsumerState<_PersonalDataForm> createState() => _PersonalDataFormState();
}

class _PersonalDataFormState extends ConsumerState<_PersonalDataForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName =
      TextEditingController(text: widget.client.firstName);
  late final TextEditingController _lastName =
      TextEditingController(text: widget.client.lastName);
  late final TextEditingController _phone =
      TextEditingController(text: Formatters.phone(widget.client.phone));
  bool _isLoading = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    final success =
        await ref.read(authControllerProvider.notifier).updateProfile(
              firstName: _firstName.text,
              lastName: _lastName.text,
              phone: _phone.text,
            );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      AppFeedback.success(context, 'Dados atualizados.');
      ref.invalidate(myClientProfileProvider);
    } else {
      final message = ref.read(authControllerProvider).errorMessage;
      AppFeedback.error(context, message ?? 'Não foi possível salvar.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            AppTextField(
              label: 'Nome',
              controller: _firstName,
              validator: (value) => Validators.required(value, field: 'O nome'),
              isRequired: true,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(label: 'Sobrenome', controller: _lastName),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Telefone',
              controller: _phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [PhoneInputFormatter()],
              validator: (value) => Validators.phone(value, isRequired: false),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Salvar alterações',
              isLoading: _isLoading,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferencesForm extends ConsumerStatefulWidget {
  const _PreferencesForm({required this.client});

  final Client client;

  @override
  ConsumerState<_PreferencesForm> createState() => _PreferencesFormState();
}

class _PreferencesFormState extends ConsumerState<_PreferencesForm> {
  late int? _branchId = widget.client.preferredBranchId;
  late int? _barberId = widget.client.preferredBarberId;
  late bool _acceptsMarketing = widget.client.acceptsMarketing;
  late DateTime? _birthDate = widget.client.birthDate;
  bool _isLoading = false;

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(clientRepositoryProvider).updateMe({
        'preferred_branch': _branchId,
        'preferred_barber': _barberId,
        'accepts_marketing': _acceptsMarketing,
        if (_birthDate != null)
          'birth_date': '${_birthDate!.year.toString().padLeft(4, '0')}-'
              '${_birthDate!.month.toString().padLeft(2, '0')}-'
              '${_birthDate!.day.toString().padLeft(2, '0')}',
      });
      if (!mounted) return;
      AppFeedback.success(context, 'Preferências salvas.');
      ref.invalidate(myClientProfileProvider);
    } on ApiException catch (error) {
      if (mounted) AppFeedback.error(context, error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branches = ref.watch(branchesProvider);
    final barbers =
        ref.watch(barbersProvider(CatalogFilter(branchId: _branchId)));

    return AppCard(
      child: Column(
        children: [
          branches.when(
            loading: () => const AppSkeleton(height: 64),
            error: (_, __) => const SizedBox.shrink(),
            data: (items) => AppDropdown<Branch>(
              label: 'Filial preferida',
              hint: 'Nenhuma',
              items: items,
              value: items.where((b) => b.id == _branchId).firstOrNull,
              itemLabel: (branch) => branch.name,
              onChanged: (branch) => setState(() {
                _branchId = branch?.id;
                _barberId = null;
              }),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          barbers.when(
            loading: () => const AppSkeleton(height: 64),
            error: (_, __) => const SizedBox.shrink(),
            data: (items) => AppDropdown<Barber>(
              label: 'Barbeiro preferido',
              hint: 'Nenhum',
              items: items,
              value: items.where((b) => b.id == _barberId).firstOrNull,
              itemLabel: (barber) => barber.name,
              onChanged: (barber) => setState(() => _barberId = barber?.id),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppDatePicker(
            label: 'Data de nascimento',
            value: _birthDate,
            lastDate: DateTime.now(),
            onChanged: (value) => setState(() => _birthDate = value),
          ),
          const SizedBox(height: AppSpacing.xs),
          SwitchListTile.adaptive(
            value: _acceptsMarketing,
            onChanged: (value) => setState(() => _acceptsMarketing = value),
            title: const Text('Receber promoções e novidades'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.xs),
          AppButton(
            label: 'Salvar preferências',
            isLoading: _isLoading,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordForm extends ConsumerStatefulWidget {
  const _ChangePasswordForm();

  @override
  ConsumerState<_ChangePasswordForm> createState() =>
      _ChangePasswordFormState();
}

class _ChangePasswordFormState extends ConsumerState<_ChangePasswordForm> {
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
            validator: (value) =>
                Validators.required(value, field: 'A senha atual'),
            isRequired: true,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Nova senha',
            controller: _newPassword,
            obscureText: true,
            helper: 'Mínimo de 8 caracteres.',
            validator: Validators.password,
            isRequired: true,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Confirmar nova senha',
            controller: _confirm,
            obscureText: true,
            validator: Validators.confirmPassword(() => _newPassword.text),
            isRequired: true,
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

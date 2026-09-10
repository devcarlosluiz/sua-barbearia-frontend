import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/validators.dart';
import '../../models/branch.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_providers.dart';
import '../../widgets/widgets.dart';
import 'widgets/auth_scaffold.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  Branch? _preferredBranch;
  DateTime? _birthDate;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final success = await ref.read(authControllerProvider.notifier).register(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          password: _passwordController.text,
          passwordConfirm: _confirmController.text,
          preferredBranchId: _preferredBranch?.id,
          birthDate: _birthDate,
        );

    if (!mounted) return;
    if (success) {
      AppFeedback.success(context, 'Conta criada com sucesso. Bem-vindo!');
      context.go(AppRoutes.clientHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final branches = ref.watch(branchesProvider);

    return AuthScaffold(
      title: 'Criar conta',
      subtitle: 'Leva menos de um minuto para agendar seu primeiro horário.',
      onBack: () =>
          context.canPop() ? context.pop() : context.go(AppRoutes.login),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (auth.errorMessage != null) ...[
              _InlineError(message: auth.errorMessage!),
              const SizedBox(height: AppSpacing.md),
            ],
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Nome',
                    controller: _firstNameController,
                    textInputAction: TextInputAction.next,
                    validator: (value) =>
                        Validators.required(value, field: 'O nome'),
                    isRequired: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppTextField(
                    label: 'Sobrenome',
                    controller: _lastNameController,
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'E-mail',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.mail_outline_rounded,
              validator: Validators.email,
              isRequired: true,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Telefone',
              controller: _phoneController,
              hint: '(41) 99999-9999',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.phone_outlined,
              inputFormatters: [PhoneInputFormatter()],
              validator: Validators.phone,
              isRequired: true,
            ),
            const SizedBox(height: AppSpacing.md),
            branches.when(
              loading: () => const AppSkeleton(height: 64),
              error: (_, __) => const SizedBox.shrink(),
              data: (items) => AppDropdown<Branch>(
                label: 'Filial preferida',
                hint: 'Escolha onde você costuma se atender',
                items: items,
                value: _preferredBranch,
                itemLabel: (branch) => branch.name,
                onChanged: (branch) =>
                    setState(() => _preferredBranch = branch),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppDatePicker(
              label: 'Data de nascimento',
              value: _birthDate,
              lastDate: DateTime.now(),
              onChanged: (value) => setState(() => _birthDate = value),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Senha',
              controller: _passwordController,
              obscureText: true,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.lock_outline_rounded,
              helper: 'Mínimo de 8 caracteres.',
              validator: Validators.password,
              isRequired: true,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Confirmar senha',
              controller: _confirmController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              prefixIcon: Icons.lock_outline_rounded,
              validator:
                  Validators.confirmPassword(() => _passwordController.text),
              isRequired: true,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Criar conta',
              isLoading: auth.isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('Já tenho conta — entrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Text(
        message,
        style:
            theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
      ),
    );
  }
}

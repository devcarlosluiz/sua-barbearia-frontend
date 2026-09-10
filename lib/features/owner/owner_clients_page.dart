import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/api_exception.dart';
import '../../core/network/paginated.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/branch.dart';
import '../../models/client.dart';
import '../../providers/catalog_providers.dart';
import '../../providers/client_providers.dart';
import '../../providers/core_providers.dart';
import '../../widgets/widgets.dart';

class OwnerClientsPage extends ConsumerWidget {
  const OwnerClientsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clients = ref.watch(clientsProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppSearchField(
              hint: 'Buscar por nome, e-mail ou telefone',
              onSearch: (value) => ref
                  .read(clientFilterProvider.notifier)
                  .update((state) => state.copyWith(search: value, page: 1)),
            ),
          ),
          Expanded(
            child: AsyncView<Paginated<Client>>(
              value: clients,
              onRetry: () => ref.invalidate(clientsProvider),
              emptyMessage: 'Nenhum cliente encontrado.',
              isEmpty: (page) => page.isEmpty,
              emptyIcon: Icons.people_outline_rounded,
              builder: (page) => ListView(
                padding: Responsive.pagePadding(context),
                children: [
                  if (Responsive.isMobile(context))
                    ...page.results.map(
                      (client) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _ClientCard(client: client),
                      ),
                    )
                  else
                    AppDataTable(
                      columns: const [
                        'Cliente',
                        'Contato',
                        'Filial preferida',
                        'Visitas',
                        'Total gasto',
                        'Última visita',
                        'Pontos',
                      ],
                      rows: page.results
                          .map(
                            (client) => AppDataRow(
                              cells: [
                                Row(
                                  children: [
                                    AppAvatar(name: client.name, size: 30),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(client.name),
                                  ],
                                ),
                                Text(
                                  client.phone.isEmpty
                                      ? client.email
                                      : Formatters.phone(client.phone),
                                ),
                                Text(client.preferredBranchName ?? '-'),
                                Text('${client.totalVisits}'),
                                Text(Formatters.currency(client.totalSpent)),
                                Text(
                                  client.lastVisitAt == null
                                      ? '-'
                                      : Formatters.date(client.lastVisitAt),
                                ),
                                Text('${client.loyaltyPoints}'),
                              ],
                            ),
                          )
                          .toList(),
                      onRowTap: (index) =>
                          _openDetail(context, ref, page.results[index]),
                    ),
                  AppPagination(
                    currentPage: page.currentPage,
                    totalPages: page.totalPages,
                    totalCount: page.count,
                    onPageChanged: (value) => ref
                        .read(clientFilterProvider.notifier)
                        .update((state) => state.copyWith(page: value)),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AppBottomSheet.show<void>(
          context,
          title: 'Novo cliente',
          subtitle: 'Cadastro rápido pelo balcão.',
          child: const _ClientForm(),
        ),
        icon: const Icon(Icons.person_add_alt_rounded),
        label: const Text('Novo cliente'),
      ),
    );
  }

  static void _openDetail(BuildContext context, WidgetRef ref, Client client) {
    AppBottomSheet.show<void>(
      context,
      title: client.name,
      subtitle: client.email,
      child: _ClientDetail(client: client),
    );
  }
}

class _ClientCard extends ConsumerWidget {
  const _ClientCard({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: () => OwnerClientsPage._openDetail(context, ref, client),
      child: Row(
        children: [
          AppAvatar(name: client.name, imageUrl: client.avatarUrl, size: 46),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(client.name, style: theme.textTheme.titleSmall),
                Text(
                  client.phone.isEmpty
                      ? client.email
                      : Formatters.phone(client.phone),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    AppBadge(
                      label: '${client.totalVisits} visita(s)',
                      color: AppColors.info,
                      dense: true,
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    AppBadge(
                      label: '${client.loyaltyPoints} pts',
                      color: AppColors.gold,
                      dense: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            Formatters.currency(client.totalSpent),
            style: theme.textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}

class _ClientDetail extends ConsumerWidget {
  const _ClientDetail({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatGrid(
          minTileWidth: 140,
          children: [
            StatCard(
              label: 'Visitas',
              value: '${client.totalVisits}',
              icon: Icons.event_available_rounded,
              compact: true,
            ),
            StatCard(
              label: 'Total gasto',
              value: Formatters.currency(client.totalSpent),
              icon: Icons.payments_rounded,
              accentColor: AppColors.success,
              compact: true,
            ),
            StatCard(
              label: 'Ticket médio',
              value: Formatters.currency(client.averageTicket),
              icon: Icons.receipt_rounded,
              compact: true,
            ),
            StatCard(
              label: 'Pontos',
              value: '${client.loyaltyPoints}',
              icon: Icons.workspace_premium_rounded,
              compact: true,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _DetailRow(label: 'E-mail', value: client.email),
        _DetailRow(
          label: 'Telefone',
          value: client.phone.isEmpty ? '-' : Formatters.phone(client.phone),
        ),
        _DetailRow(
          label: 'Nascimento',
          value: client.birthDate == null
              ? '-'
              : Formatters.date(client.birthDate),
        ),
        _DetailRow(
            label: 'Filial preferida',
            value: client.preferredBranchName ?? '-'),
        _DetailRow(
            label: 'Barbeiro preferido',
            value: client.preferredBarberName ?? '-'),
        _DetailRow(
            label: 'Serviço favorito',
            value: client.favoriteServiceName ?? '-'),
        _DetailRow(
          label: 'Última visita',
          value: client.lastVisitAt == null
              ? 'Ainda não atendido'
              : Formatters.dateTime(client.lastVisitAt),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Observações internas', style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xxs),
        _InternalNotes(client: client),
      ],
    );
  }
}

class _InternalNotes extends ConsumerStatefulWidget {
  const _InternalNotes({required this.client});

  final Client client;

  @override
  ConsumerState<_InternalNotes> createState() => _InternalNotesState();
}

class _InternalNotesState extends ConsumerState<_InternalNotes> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.client.notes);
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(clientRepositoryProvider).update(
        widget.client.id,
        {'notes': _controller.text.trim()},
      );
      if (!mounted) return;
      AppFeedback.success(context, 'Observações salvas.');
      ref.invalidate(clientsProvider);
    } on ApiException catch (error) {
      if (mounted) AppFeedback.error(context, error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Preferências, alergias, histórico...',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton.outline(
          label: 'Salvar observações',
          isLoading: _isSaving,
          onPressed: _save,
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.titleSmall,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientForm extends ConsumerStatefulWidget {
  const _ClientForm();

  @override
  ConsumerState<_ClientForm> createState() => _ClientFormState();
}

class _ClientFormState extends ConsumerState<_ClientForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  Branch? _branch;
  DateTime? _birthDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(clientRepositoryProvider).create(
            firstName: _firstName.text,
            lastName: _lastName.text,
            email: _email.text,
            phone: _phone.text,
            preferredBranchId: _branch?.id,
            birthDate: _birthDate,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      AppFeedback.success(
        context,
        'Cliente cadastrado. A senha inicial é a padrão de desenvolvimento.',
      );
      ref.invalidate(clientsProvider);
    } on ApiException catch (error) {
      if (mounted) {
        AppFeedback.error(
          context,
          error.errorFor('user') ?? error.message,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branches = ref.watch(branchesProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Nome',
                  controller: _firstName,
                  isRequired: true,
                  validator: (value) =>
                      Validators.required(value, field: 'O nome'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(label: 'Sobrenome', controller: _lastName),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'E-mail',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            isRequired: true,
            validator: Validators.email,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Telefone',
            controller: _phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [PhoneInputFormatter()],
            isRequired: true,
            validator: Validators.phone,
          ),
          const SizedBox(height: AppSpacing.md),
          branches.when(
            loading: () => const AppSkeleton(height: 64),
            error: (_, __) => const SizedBox.shrink(),
            data: (items) => AppDropdown<Branch>(
              label: 'Filial preferida',
              hint: 'Nenhuma',
              items: items,
              value: _branch,
              itemLabel: (branch) => branch.name,
              onChanged: (branch) => setState(() => _branch = branch),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppDatePicker(
            label: 'Data de nascimento',
            value: _birthDate,
            lastDate: DateTime.now(),
            onChanged: (value) => setState(() => _birthDate = value),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Cadastrar cliente',
            isLoading: _isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

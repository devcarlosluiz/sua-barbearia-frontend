import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/api_exception.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/barber.dart';
import '../../models/branch.dart';
import '../../providers/catalog_providers.dart';
import '../../providers/core_providers.dart';
import '../../widgets/widgets.dart';

class OwnerBarbersPage extends ConsumerWidget {
  const OwnerBarbersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final barbers = ref.watch(allBarbersProvider);

    return Scaffold(
      body: AsyncView<List<Barber>>(
        value: barbers,
        onRetry: () => ref.invalidate(allBarbersProvider),
        emptyMessage: 'Nenhum barbeiro cadastrado ainda.',
        isEmpty: (items) => items.isEmpty,
        emptyIcon: Icons.content_cut_rounded,
        emptyActionLabel: 'Cadastrar barbeiro',
        onEmptyAction: () => _openForm(context, ref),
        builder: (items) => ListView(
          padding: Responsive.pagePadding(context),
          children: [
            ...items.map(
              (barber) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _BarberCard(barber: barber),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo barbeiro'),
      ),
    );
  }

  static Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    Barber? barber,
  }) async {
    // A listagem usa um payload enxuto (sem e-mail, telefone, comissão, bio
    // nem serviços). Abrir o formulário com ele preencheria os campos vazios e
    // um "salvar" zeraria esses dados — por isso buscamos o detalhe completo.
    Barber? full = barber;
    if (barber != null) {
      try {
        full = await ref.read(catalogRepositoryProvider).barber(barber.id);
      } on ApiException catch (error) {
        if (context.mounted) AppFeedback.error(context, error.message);
        return;
      }
    }

    if (!context.mounted) return;
    await AppBottomSheet.show<void>(
      context,
      title: barber == null ? 'Novo barbeiro' : 'Editar barbeiro',
      subtitle: full?.name,
      child: _BarberForm(barber: full),
    );
  }
}

class _BarberCard extends ConsumerWidget {
  const _BarberCard({required this.barber});

  final Barber barber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final branches =
        ref.watch(branchesProvider).valueOrNull ?? const <Branch>[];
    final barberBranches = branches
        .where((branch) => barber.branchIds.contains(branch.id))
        .map((branch) => branch.name)
        .join(', ');

    return AppCard(
      onTap: () => OwnerBarbersPage._openForm(context, ref, barber: barber),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(
                  name: barber.name, imageUrl: barber.avatarUrl, size: 52),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            barber.name,
                            style: theme.textTheme.titleSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!barber.isActive) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const AppBadge(
                            label: 'Inativo',
                            color: AppColors.danger,
                            dense: true,
                          ),
                        ],
                      ],
                    ),
                    Text(barber.email, style: theme.textTheme.bodySmall),
                    if (barberBranches.isNotEmpty)
                      Text(barberBranches, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppBadge(
                    label: '${barber.commissionPercentage.toStringAsFixed(0)}%',
                    color: AppColors.gold,
                    icon: Icons.percent_rounded,
                    dense: true,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  if (barber.hasRating)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: AppColors.gold,
                        ),
                        Text(
                          barber.rating.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
          if (barber.services.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xxs,
              runSpacing: AppSpacing.xxs,
              children: barber.services
                  .take(6)
                  .map(
                    (item) => AppBadge(
                      label: item.name,
                      color: AppColors.info,
                      dense: true,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _BarberForm extends ConsumerStatefulWidget {
  const _BarberForm({this.barber});

  final Barber? barber;

  @override
  ConsumerState<_BarberForm> createState() => _BarberFormState();
}

class _BarberFormState extends ConsumerState<_BarberForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _nickname;
  late final TextEditingController _bio;
  late final TextEditingController _commission;
  late final TextEditingController _specialties;

  late Set<int> _branchIds;
  late Set<int> _serviceIds;
  late bool _isActive;
  bool _isLoading = false;

  /// Barbeiro recém-criado neste formulário. A jornada de trabalho só existe
  /// depois que o barbeiro tem `id` e filiais salvas, então o cadastro não
  /// fecha o formulário: ele passa a modo edição e libera a seção de jornada.
  Barber? _saved;

  Barber? get _current => _saved ?? widget.barber;

  bool get _isEditing => _current != null;

  /// As filiais escolhidas ainda não persistidas. A jornada é validada contra
  /// os vínculos salvos no backend, por isso avisamos em vez de dar erro 400.
  bool get _hasUnsavedBranches =>
      !const SetEquality<int>().equals(_branchIds, _current!.branchIds.toSet());

  @override
  void initState() {
    super.initState();
    final barber = widget.barber;

    // Usa os campos reais do usuário. `barber.name` é o nome de exibição
    // (o apelido, quando existe) — fatiá-lo aqui sobrescreveria o cadastro.
    _firstName = TextEditingController(text: barber?.firstName ?? '');
    _lastName = TextEditingController(text: barber?.lastName ?? '');
    _email = TextEditingController(text: barber?.email ?? '');
    _phone = TextEditingController(text: Formatters.phone(barber?.phone));
    _nickname = TextEditingController(text: barber?.nickname ?? '');
    _bio = TextEditingController(text: barber?.bio ?? '');
    _commission = TextEditingController(
      text: (barber?.commissionPercentage ?? 40).toStringAsFixed(2),
    );
    _specialties = TextEditingController(
      text: (barber?.specialties ?? const []).join(', '),
    );
    _branchIds = {...?barber?.branchIds};
    _serviceIds = {...?barber?.services.map((item) => item.serviceId)};
    _isActive = barber?.isActive ?? true;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _nickname.dispose();
    _bio.dispose();
    _commission.dispose();
    _specialties.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_branchIds.isEmpty) {
      AppFeedback.error(context, 'Selecione ao menos uma filial.');
      return;
    }

    setState(() => _isLoading = true);
    final specialties = _specialties.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    final payload = <String, dynamic>{
      'nickname': _nickname.text.trim(),
      'bio': _bio.text.trim(),
      'specialties': specialties,
      'commission_percentage':
          double.tryParse(_commission.text.replaceAll(',', '.'))
                  ?.toStringAsFixed(2) ??
              '40.00',
      'is_active': _isActive,
      'branches': _branchIds.toList(),
      'service_ids': _serviceIds.toList(),
      'user': {
        'first_name': _firstName.text.trim(),
        'last_name': _lastName.text.trim(),
        'email': _email.text.trim().toLowerCase(),
        'phone': _phone.text.replaceAll(RegExp(r'\D'), ''),
      },
    };

    try {
      final repository = ref.read(catalogRepositoryProvider);
      if (_isEditing) {
        final updated = await repository.updateBarber(_current!.id, payload);
        if (!mounted) return;
        setState(() => _saved = updated);
        AppFeedback.success(context, 'Barbeiro atualizado.');
      } else {
        final created = await repository.createBarber(payload);
        if (!mounted) return;
        // Não fecha o formulário: sem isso o proprietário teria que reabrir o
        // barbeiro em "Editar" só para conseguir cadastrar a jornada.
        setState(() => _saved = created);
        AppFeedback.success(
          context,
          'Barbeiro cadastrado. Agora defina a jornada de trabalho.',
        );
      }
      ref.invalidate(allBarbersProvider);
    } on ApiException catch (error) {
      if (mounted) {
        AppFeedback.error(context, error.errorFor('user') ?? error.message);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branches = ref.watch(branchesProvider);
    final services = ref.watch(allServicesProvider);

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
            label: 'Apelido (exibido ao cliente)',
            controller: _nickname,
            hint: 'Ex.: Jota',
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'E-mail de acesso',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            // Na edição o campo é somente leitura e o backend nem o atualiza,
            // então exigi-lo aqui só bloquearia o salvamento sem motivo.
            isRequired: !_isEditing,
            enabled: !_isEditing,
            helper: _isEditing
                ? 'O e-mail de acesso é alterado na gestão de usuários.'
                : 'A senha inicial é a senha padrão definida no ambiente.',
            validator: _isEditing ? null : Validators.email,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Telefone',
            controller: _phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [PhoneInputFormatter()],
            validator: (value) => Validators.phone(value, isRequired: false),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Comissão (%)',
            controller: _commission,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [MoneyInputFormatter()],
            isRequired: true,
            validator: Validators.money,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Especialidades',
            controller: _specialties,
            hint: 'Separadas por vírgula: Degradê, Barba terapia',
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(label: 'Biografia', controller: _bio, maxLines: 3),
          const SizedBox(height: AppSpacing.lg),
          Text('Filiais', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          branches.when(
            loading: () => const AppSkeleton(height: 40),
            error: (_, __) =>
                const Text('Não foi possível carregar as filiais.'),
            data: (items) => Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: items
                  .map(
                    (branch) => FilterChip(
                      label: Text(branch.name),
                      selected: _branchIds.contains(branch.id),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _branchIds.add(branch.id);
                        } else {
                          _branchIds.remove(branch.id);
                        }
                      }),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Serviços que realiza',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          services.when(
            loading: () => const AppSkeleton(height: 40),
            error: (_, __) =>
                const Text('Não foi possível carregar os serviços.'),
            data: (items) => Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: items
                  .map(
                    (service) => FilterChip(
                      label: Text(service.name),
                      selected: _serviceIds.contains(service.id),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _serviceIds.add(service.id);
                        } else {
                          _serviceIds.remove(service.id);
                        }
                      }),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SwitchListTile.adaptive(
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
            title: const Text('Barbeiro ativo'),
            subtitle: const Text('Inativos não aparecem para agendamento.'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: _isEditing ? 'Salvar alterações' : 'Cadastrar barbeiro',
            isLoading: _isLoading,
            onPressed: _submit,
          ),
          if (_isEditing) ...[
            const SizedBox(height: AppSpacing.sm),
            _WorkingHoursSection(
              barber: _current!,
              hasUnsavedBranches: _hasUnsavedBranches,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Concluir'),
            ),
          ],
        ],
      ),
    );
  }
}

const _weekdayNames = [
  'Segunda-feira',
  'Terça-feira',
  'Quarta-feira',
  'Quinta-feira',
  'Sexta-feira',
  'Sábado',
  'Domingo',
];

/// Jornada semanal do barbeiro, editável pelo proprietário.
///
/// A jornada é única por (barbeiro, filial, dia da semana) — por isso a filial
/// é escolhida aqui em vez de assumida: um barbeiro em duas unidades tem duas
/// jornadas, e editar sem escolher sobrescreveria a da filial errada.
class _WorkingHoursSection extends ConsumerStatefulWidget {
  const _WorkingHoursSection({
    required this.barber,
    this.hasUnsavedBranches = false,
  });

  final Barber barber;
  final bool hasUnsavedBranches;

  @override
  ConsumerState<_WorkingHoursSection> createState() =>
      _WorkingHoursSectionState();
}

class _WorkingHoursSectionState extends ConsumerState<_WorkingHoursSection> {
  int? _branchId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hours = ref.watch(workingHoursProvider(widget.barber.id));
    final all = ref.watch(branchesProvider).valueOrNull ?? const <Branch>[];
    final branches = all
        .where((branch) => widget.barber.branchIds.contains(branch.id))
        .toList();
    final selected =
        branches.firstWhereOrNull((branch) => branch.id == _branchId) ??
            branches.firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: AppSpacing.xl),
        const AppSectionHeader(
          title: 'Jornada de trabalho',
          subtitle: 'Define os horários oferecidos ao cliente.',
        ),
        if (widget.hasUnsavedBranches)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              'Você alterou as filiais. Salve as alterações para definir a '
              'jornada nelas.',
              style:
                  theme.textTheme.bodySmall?.copyWith(color: AppColors.warning),
            ),
          ),
        if (selected == null)
          Text(
            'Vincule o barbeiro a uma filial e salve para definir a jornada.',
            style: theme.textTheme.bodySmall,
          )
        else ...[
          if (branches.length > 1) ...[
            AppDropdown<Branch>(
              label: 'Filial',
              items: branches,
              value: selected,
              itemLabel: (branch) => branch.name,
              onChanged: (branch) => setState(() => _branchId = branch?.id),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          hours.when(
            loading: () => const AppSkeleton(height: 80),
            error: (_, __) =>
                const Text('Não foi possível carregar a jornada.'),
            data: (items) => Column(
              children: [
                for (var weekday = 0; weekday < 7; weekday++)
                  _WorkingDayTile(
                    barber: widget.barber,
                    branch: selected,
                    weekday: weekday,
                    existing: items.firstWhereOrNull(
                      (item) =>
                          item.weekday == weekday &&
                          item.branchId == selected.id,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Resumo de um dia da semana. Toca para abrir o editor.
///
/// Compacto de propósito: sete dias com todos os campos abertos deixariam o
/// formulário longo demais para uso no celular.
class _WorkingDayTile extends ConsumerWidget {
  const _WorkingDayTile({
    required this.barber,
    required this.branch,
    required this.weekday,
    required this.existing,
  });

  final Barber barber;
  final Branch branch;
  final int weekday;
  final WorkingHour? existing;

  String get _summary {
    final hour = existing;
    if (hour == null) return 'Não trabalha';
    final shift =
        '${Formatters.clock(hour.startsAt)} às ${Formatters.clock(hour.endsAt)}';
    if (!hour.hasBreak) return shift;
    return '$shift · intervalo '
        '${Formatters.clock(hour.breakStartsAt)}–'
        '${Formatters.clock(hour.breakEndsAt)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final works = existing != null;

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        works ? Icons.event_available_rounded : Icons.event_busy_rounded,
        size: 20,
        color: works ? AppColors.success : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(_weekdayNames[weekday], style: theme.textTheme.bodyMedium),
      subtitle: Text(_summary, style: theme.textTheme.bodySmall),
      trailing: const Icon(Icons.edit_outlined, size: 18),
      onTap: () async {
        final changed = await _WorkingHourEditor.open(
          context,
          barber: barber,
          branch: branch,
          weekday: weekday,
          existing: existing,
        );
        if (changed == true) {
          ref.invalidate(workingHoursProvider(barber.id));
        }
      },
    );
  }
}

/// Editor de um dia da jornada: expediente e intervalo opcional.
class _WorkingHourEditor extends ConsumerStatefulWidget {
  const _WorkingHourEditor({
    required this.barber,
    required this.branch,
    required this.weekday,
    required this.existing,
  });

  final Barber barber;
  final Branch branch;
  final int weekday;
  final WorkingHour? existing;

  static Future<bool?> open(
    BuildContext context, {
    required Barber barber,
    required Branch branch,
    required int weekday,
    required WorkingHour? existing,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => _WorkingHourEditor(
        barber: barber,
        branch: branch,
        weekday: weekday,
        existing: existing,
      ),
    );
  }

  @override
  ConsumerState<_WorkingHourEditor> createState() => _WorkingHourEditorState();
}

class _WorkingHourEditorState extends ConsumerState<_WorkingHourEditor> {
  late String _start;
  late String _end;
  late bool _hasBreak;
  late String _breakStart;
  late String _breakEnd;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final hour = widget.existing;
    _start = Formatters.clock(hour?.startsAt ?? '09:00');
    _end = Formatters.clock(hour?.endsAt ?? '18:00');
    // Um dia novo começa sem intervalo. O padrão fixo de 12h–13h que existia
    // aqui inviabilizava qualquer turno fora do horário comercial: o backend
    // exige que o intervalo caia dentro do expediente.
    _hasBreak = hour?.hasBreak ?? false;
    _breakStart = Formatters.clock(hour?.breakStartsAt ?? '12:00');
    _breakEnd = Formatters.clock(hour?.breakEndsAt ?? '13:00');
  }

  /// Repete as regras do backend para avisar antes de gastar uma requisição.
  String? get _error {
    if (_end.compareTo(_start) <= 0) {
      return 'O fim do expediente deve ser maior que o início.';
    }
    if (_hasBreak) {
      if (_breakEnd.compareTo(_breakStart) <= 0) {
        return 'O fim do intervalo deve ser maior que o início.';
      }
      if (_breakStart.compareTo(_start) < 0 || _breakEnd.compareTo(_end) > 0) {
        return 'O intervalo precisa estar dentro do expediente.';
      }
    }
    return null;
  }

  Future<void> _save() async {
    final error = _error;
    if (error != null) {
      AppFeedback.error(context, error);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(catalogRepositoryProvider).saveWorkingHour(
        {
          'barber': widget.barber.id,
          'branch': widget.branch.id,
          'weekday': widget.weekday,
          'starts_at': '$_start:00',
          'ends_at': '$_end:00',
          'break_starts_at': _hasBreak ? '$_breakStart:00' : null,
          'break_ends_at': _hasBreak ? '$_breakEnd:00' : null,
          'is_active': true,
        },
        id: widget.existing?.id,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      AppFeedback.success(
        context,
        '${_weekdayNames[widget.weekday]} atualizada.',
      );
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppFeedback.error(context, error.message);
      }
    }
  }

  Future<void> _remove() async {
    final id = widget.existing?.id;
    if (id == null) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(catalogRepositoryProvider).deleteWorkingHour(id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      AppFeedback.success(
        context,
        '${_weekdayNames[widget.weekday]} removida da jornada.',
      );
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppFeedback.error(context, error.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_weekdayNames[widget.weekday]),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.branch.name,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AppTimePicker(
                      label: 'Início',
                      value: _start,
                      isRequired: true,
                      onChanged: (value) => setState(() => _start = value),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppTimePicker(
                      label: 'Fim',
                      value: _end,
                      isRequired: true,
                      onChanged: (value) => setState(() => _end = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              SwitchListTile.adaptive(
                value: _hasBreak,
                onChanged: (value) => setState(() => _hasBreak = value),
                title: const Text('Intervalo'),
                subtitle: const Text('Almoço ou pausa dentro do expediente.'),
                contentPadding: EdgeInsets.zero,
              ),
              if (_hasBreak)
                Row(
                  children: [
                    Expanded(
                      child: AppTimePicker(
                        label: 'Saída',
                        value: _breakStart,
                        onChanged: (value) =>
                            setState(() => _breakStart = value),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppTimePicker(
                        label: 'Retorno',
                        value: _breakEnd,
                        onChanged: (value) => setState(() => _breakEnd = value),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.existing != null)
          TextButton(
            onPressed: _isSaving ? null : _remove,
            child: const Text('Não trabalha'),
          ),
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        AppButton(
          label: 'Salvar',
          expanded: false,
          size: AppButtonSize.small,
          isLoading: _isSaving,
          onPressed: _save,
        ),
      ],
    );
  }
}

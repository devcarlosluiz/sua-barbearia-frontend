import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/api_exception.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/branch.dart';
import '../../providers/catalog_providers.dart';
import '../../providers/core_providers.dart';
import '../../widgets/widgets.dart';

class OwnerBranchesPage extends ConsumerWidget {
  const OwnerBranchesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branches = ref.watch(branchesProvider);

    return Scaffold(
      body: AsyncView<List<Branch>>(
        value: branches,
        onRetry: () => ref.invalidate(branchesProvider),
        emptyMessage: 'Nenhuma filial cadastrada.',
        isEmpty: (items) => items.isEmpty,
        emptyIcon: Icons.store_outlined,
        emptyActionLabel: 'Cadastrar filial',
        onEmptyAction: () => _openForm(context, ref),
        builder: (items) => ListView(
          padding: Responsive.pagePadding(context),
          children: [
            ...items.map(
              (branch) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _BranchCard(branch: branch),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Nova filial'),
      ),
    );
  }

  static Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    Branch? branch,
  }) async {
    // O detalhe traz os horários de funcionamento, que a listagem não inclui.
    Branch? full = branch;
    if (branch != null) {
      try {
        full = await ref.read(catalogRepositoryProvider).branch(branch.id);
      } on ApiException catch (error) {
        if (context.mounted) AppFeedback.error(context, error.message);
        return;
      }
    }

    if (!context.mounted) return;
    await AppBottomSheet.show<void>(
      context,
      title: branch == null ? 'Nova filial' : 'Editar filial',
      subtitle: branch?.name,
      child: _BranchForm(branch: full),
    );
  }
}

class _BranchCard extends ConsumerWidget {
  const _BranchCard({required this.branch});

  final Branch branch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: () => OwnerBranchesPage._openForm(context, ref, branch: branch),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Icon(Icons.store_rounded, color: AppColors.gold),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        branch.name,
                        style: theme.textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!branch.isActive) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const AppBadge(
                        label: 'Inativa',
                        color: AppColors.danger,
                        dense: true,
                      ),
                    ],
                  ],
                ),
                Text(
                  branch.fullAddress,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (branch.phone.isNotEmpty)
                  Text(
                    Formatters.phone(branch.phone),
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          if (branch.barbersCount > 0)
            AppBadge(
              label: '${branch.barbersCount} barbeiro(s)',
              color: AppColors.info,
              dense: true,
            ),
        ],
      ),
    );
  }
}

class _BranchForm extends ConsumerStatefulWidget {
  const _BranchForm({this.branch});

  final Branch? branch;

  @override
  ConsumerState<_BranchForm> createState() => _BranchFormState();
}

class _BranchFormState extends ConsumerState<_BranchForm> {
  final _formKey = GlobalKey<FormState>();

  late final Map<String, TextEditingController> _fields = {
    'name': TextEditingController(text: widget.branch?.name ?? ''),
    'cnpj': TextEditingController(text: Formatters.cnpj(widget.branch?.cnpj)),
    'address': TextEditingController(text: widget.branch?.address ?? ''),
    'number': TextEditingController(text: widget.branch?.number ?? ''),
    'complement': TextEditingController(text: widget.branch?.complement ?? ''),
    'district': TextEditingController(text: widget.branch?.district ?? ''),
    'city': TextEditingController(text: widget.branch?.city ?? ''),
    'zip_code': TextEditingController(
      text: Formatters.zipCode(widget.branch?.zipCode),
    ),
    'phone':
        TextEditingController(text: Formatters.phone(widget.branch?.phone)),
    'whatsapp': TextEditingController(
      text: Formatters.phone(widget.branch?.whatsapp),
    ),
    'email': TextEditingController(text: widget.branch?.email ?? ''),
  };

  late String _state =
      widget.branch?.state.isNotEmpty == true ? widget.branch!.state : 'PR';
  late int _slotInterval = widget.branch?.slotIntervalMinutes ?? 30;
  late int _cancellationHours = widget.branch?.cancellationLimitHours ?? 2;
  late int _maxAdvanceDays = widget.branch?.maxAdvanceBookingDays ?? 90;
  late double _pointsPerReal = widget.branch?.loyaltyPointsPerCurrencyUnit ?? 1;
  late bool _isActive = widget.branch?.isActive ?? true;
  bool _isLoading = false;

  bool get _isEditing => widget.branch != null;

  static const _states = [
    'AC',
    'AL',
    'AP',
    'AM',
    'BA',
    'CE',
    'DF',
    'ES',
    'GO',
    'MA',
    'MT',
    'MS',
    'MG',
    'PA',
    'PB',
    'PR',
    'PE',
    'PI',
    'RJ',
    'RN',
    'RS',
    'RO',
    'RR',
    'SC',
    'SP',
    'SE',
    'TO',
  ];

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _digits(String key) =>
      _fields[key]!.text.replaceAll(RegExp(r'\D'), '');

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    final payload = <String, dynamic>{
      'name': _fields['name']!.text.trim(),
      'cnpj': _digits('cnpj'),
      'address': _fields['address']!.text.trim(),
      'number': _fields['number']!.text.trim(),
      'complement': _fields['complement']!.text.trim(),
      'district': _fields['district']!.text.trim(),
      'city': _fields['city']!.text.trim(),
      'state': _state,
      'zip_code': _digits('zip_code'),
      'phone': _digits('phone'),
      'whatsapp': _digits('whatsapp'),
      'email': _fields['email']!.text.trim(),
      'slot_interval_minutes': _slotInterval,
      'cancellation_limit_hours': _cancellationHours,
      'max_advance_booking_days': _maxAdvanceDays,
      'loyalty_points_per_currency_unit': _pointsPerReal.toStringAsFixed(2),
      'is_active': _isActive,
    };

    // Ao criar uma filial, já definimos um funcionamento padrão
    // (segunda a sábado), evitando uma unidade sem horários.
    if (!_isEditing) {
      payload['opening_hours'] = [
        for (var weekday = 0; weekday < 6; weekday++)
          {
            'weekday': weekday,
            'opens_at': '09:00:00',
            'closes_at': weekday < 5 ? '20:00:00' : '18:00:00',
            'is_closed': false,
          },
        {
          'weekday': 6,
          'opens_at': '09:00:00',
          'closes_at': '13:00:00',
          'is_closed': true,
        },
      ];
    }

    try {
      final repository = ref.read(catalogRepositoryProvider);
      if (_isEditing) {
        await repository.updateBranch(widget.branch!.id, payload);
      } else {
        await repository.createBranch(payload);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      AppFeedback.success(
        context,
        _isEditing ? 'Filial atualizada.' : 'Filial criada.',
      );
      ref.invalidate(branchesProvider);
    } on ApiException catch (error) {
      if (mounted) {
        AppFeedback.error(
          context,
          error.errorFor('cnpj') ?? error.errorFor('name') ?? error.message,
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
            label: 'Nome da filial',
            controller: _fields['name'],
            isRequired: true,
            validator: (value) => Validators.required(value, field: 'O nome'),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'CNPJ',
            controller: _fields['cnpj'],
            keyboardType: TextInputType.number,
            validator: Validators.cnpj,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: AppTextField(
                  label: 'Endereço',
                  controller: _fields['address'],
                  isRequired: true,
                  validator: (value) =>
                      Validators.required(value, field: 'O endereço'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(
                  label: 'Número',
                  controller: _fields['number'],
                  isRequired: true,
                  validator: (value) =>
                      Validators.required(value, field: 'O número'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(label: 'Complemento', controller: _fields['complement']),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Bairro',
            controller: _fields['district'],
            isRequired: true,
            validator: (value) => Validators.required(value, field: 'O bairro'),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: AppTextField(
                  label: 'Cidade',
                  controller: _fields['city'],
                  isRequired: true,
                  validator: (value) =>
                      Validators.required(value, field: 'A cidade'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppDropdown<String>(
                  label: 'UF',
                  items: _states,
                  value: _state,
                  isRequired: true,
                  itemLabel: (item) => item,
                  onChanged: (value) => setState(() => _state = value ?? 'PR'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'CEP',
            controller: _fields['zip_code'],
            keyboardType: TextInputType.number,
            isRequired: true,
            validator: Validators.zipCode,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Telefone',
                  controller: _fields['phone'],
                  keyboardType: TextInputType.phone,
                  inputFormatters: [PhoneInputFormatter()],
                  validator: (value) =>
                      Validators.phone(value, isRequired: false),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(
                  label: 'WhatsApp',
                  controller: _fields['whatsapp'],
                  keyboardType: TextInputType.phone,
                  inputFormatters: [PhoneInputFormatter()],
                  validator: (value) =>
                      Validators.phone(value, isRequired: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'E-mail',
            controller: _fields['email'],
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppSpacing.lg),
          const AppSectionHeader(
            title: 'Regras de agendamento',
            subtitle: 'Valem apenas para esta filial.',
          ),
          _SliderField(
            label: 'Intervalo entre horários',
            value: _slotInterval.toDouble(),
            min: 10,
            max: 60,
            divisions: 10,
            suffix: 'min',
            onChanged: (value) => setState(() => _slotInterval = value.round()),
          ),
          _SliderField(
            label: 'Cancelamento pelo cliente até',
            value: _cancellationHours.toDouble(),
            min: 0,
            max: 48,
            divisions: 48,
            suffix: 'h antes',
            onChanged: (value) =>
                setState(() => _cancellationHours = value.round()),
          ),
          _SliderField(
            label: 'Antecedência máxima',
            value: _maxAdvanceDays.toDouble(),
            min: 7,
            max: 180,
            divisions: 25,
            suffix: 'dias',
            onChanged: (value) =>
                setState(() => _maxAdvanceDays = value.round()),
          ),
          _SliderField(
            label: 'Pontos de fidelidade por R\$ 1,00',
            value: _pointsPerReal,
            min: 0,
            max: 5,
            divisions: 20,
            suffix: 'pts',
            decimals: 2,
            onChanged: (value) => setState(() => _pointsPerReal = value),
          ),
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile.adaptive(
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
            title: const Text('Filial ativa'),
            subtitle: const Text('Inativas não recebem novos agendamentos.'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: _isEditing ? 'Salvar alterações' : 'Criar filial',
            isLoading: _isLoading,
            onPressed: _submit,
          ),
          if (_isEditing && widget.branch!.openingHours.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            const AppSectionHeader(title: 'Funcionamento'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var index = 0;
                      index < widget.branch!.openingHours.length;
                      index++) ...[
                    if (index > 0) const Divider(height: 1),
                    ListTile(
                      dense: true,
                      title:
                          Text(widget.branch!.openingHours[index].weekdayLabel),
                      trailing: Text(
                        widget.branch!.openingHours[index].isClosed
                            ? 'Fechado'
                            : '${Formatters.clock(widget.branch!.openingHours[index].opensAt)}'
                                ' - '
                                '${Formatters.clock(widget.branch!.openingHours[index].closesAt)}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SliderField extends StatelessWidget {
  const _SliderField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    this.suffix = '',
    this.decimals = 0,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String suffix;
  final int decimals;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
            Text(
              '${value.toStringAsFixed(decimals)} $suffix',
              style: theme.textTheme.titleSmall,
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/api_exception.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/service.dart';
import '../../providers/catalog_providers.dart';
import '../../providers/core_providers.dart';
import '../../widgets/widgets.dart';

class OwnerServicesPage extends ConsumerWidget {
  const OwnerServicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(allServicesProvider);

    return Scaffold(
      body: AsyncView<List<Service>>(
        value: services,
        onRetry: () => ref.invalidate(allServicesProvider),
        emptyMessage: 'Nenhum serviço cadastrado.',
        isEmpty: (items) => items.isEmpty,
        emptyIcon: Icons.design_services_outlined,
        emptyActionLabel: 'Cadastrar serviço',
        onEmptyAction: () => _openForm(context, ref),
        builder: (items) => ListView(
          padding: Responsive.pagePadding(context),
          children: [
            if (Responsive.isMobile(context))
              ...items.map(
                (service) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _ServiceCard(service: service),
                ),
              )
            else
              AppDataTable(
                columns: const [
                  'Serviço',
                  'Categoria',
                  'Duração',
                  'Preço',
                  'Status',
                ],
                rows: items
                    .map(
                      (service) => AppDataRow(
                        cells: [
                          Text(service.name),
                          Text(service.categoryName ?? '-'),
                          Text(Formatters.duration(service.durationMinutes)),
                          Text(Formatters.currency(service.price)),
                          AppBadge(
                            label: service.isActive ? 'Ativo' : 'Inativo',
                            color: service.isActive
                                ? AppColors.success
                                : AppColors.grey,
                            dense: true,
                          ),
                        ],
                      ),
                    )
                    .toList(),
                onRowTap: (index) =>
                    _openForm(context, ref, service: items[index]),
              ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo serviço'),
      ),
    );
  }

  static Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    Service? service,
  }) async {
    await AppBottomSheet.show<void>(
      context,
      title: service == null ? 'Novo serviço' : 'Editar serviço',
      subtitle: service?.name,
      child: _ServiceForm(service: service),
    );
  }
}

class _ServiceCard extends ConsumerWidget {
  const _ServiceCard({required this.service});

  final Service service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: () => OwnerServicesPage._openForm(context, ref, service: service),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        service.name,
                        style: theme.textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!service.isActive) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const AppBadge(
                        label: 'Inativo',
                        color: AppColors.grey,
                        dense: true,
                      ),
                    ],
                  ],
                ),
                if (service.categoryName != null)
                  Text(service.categoryName!, style: theme.textTheme.bodySmall),
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      Formatters.duration(service.durationMinutes),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            Formatters.currency(service.price),
            style: theme.textTheme.titleMedium?.copyWith(color: AppColors.gold),
          ),
        ],
      ),
    );
  }
}

class _ServiceForm extends ConsumerStatefulWidget {
  const _ServiceForm({this.service});

  final Service? service;

  @override
  ConsumerState<_ServiceForm> createState() => _ServiceFormState();
}

class _ServiceFormState extends ConsumerState<_ServiceForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.service?.name ?? '');
  late final TextEditingController _description =
      TextEditingController(text: widget.service?.description ?? '');
  late final TextEditingController _duration = TextEditingController(
    text: '${widget.service?.durationMinutes ?? 30}',
  );
  late final TextEditingController _price = TextEditingController(
    text: (widget.service?.price ?? 0).toStringAsFixed(2),
  );

  late int? _categoryId = widget.service?.categoryId;
  late bool _isActive = widget.service?.isActive ?? true;
  bool _isLoading = false;

  bool get _isEditing => widget.service != null;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _duration.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    final payload = <String, dynamic>{
      'name': _name.text.trim(),
      'description': _description.text.trim(),
      'category': _categoryId,
      'duration_minutes': int.parse(_duration.text),
      'price':
          double.parse(_price.text.replaceAll(',', '.')).toStringAsFixed(2),
      'is_active': _isActive,
    };

    try {
      final repository = ref.read(catalogRepositoryProvider);
      if (_isEditing) {
        await repository.updateService(widget.service!.id, payload);
      } else {
        await repository.createService(payload);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      AppFeedback.success(
        context,
        _isEditing ? 'Serviço atualizado.' : 'Serviço criado.',
      );
      ref.invalidate(allServicesProvider);
    } on ApiException catch (error) {
      if (mounted) AppFeedback.error(context, error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Excluir serviço',
      message: 'Serviços já usados em agendamentos não podem ser excluídos — '
          'nesse caso, desative-o. Deseja tentar excluir?',
      confirmLabel: 'Excluir',
      isDestructive: true,
    );
    if (!confirmed) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(catalogRepositoryProvider)
          .deleteService(widget.service!.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      AppFeedback.success(context, 'Serviço excluído.');
      ref.invalidate(allServicesProvider);
    } on ApiException catch (error) {
      if (mounted) {
        AppFeedback.error(
          context,
          'Não foi possível excluir: o serviço já tem histórico. Desative-o.',
        );
        debugPrint(error.code);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(serviceCategoriesProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'Nome',
            controller: _name,
            isRequired: true,
            validator: (value) => Validators.required(value, field: 'O nome'),
          ),
          const SizedBox(height: AppSpacing.md),
          categories.when(
            loading: () => const AppSkeleton(height: 64),
            error: (_, __) => const SizedBox.shrink(),
            data: (items) => AppDropdown<ServiceCategory>(
              label: 'Categoria',
              hint: 'Sem categoria',
              items: items,
              value: items.firstWhereOrNull((item) => item.id == _categoryId),
              itemLabel: (item) => item.name,
              onChanged: (item) => setState(() => _categoryId = item?.id),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Duração (min)',
                  controller: _duration,
                  keyboardType: TextInputType.number,
                  isRequired: true,
                  validator: Validators.positiveInteger,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(
                  label: 'Preço',
                  controller: _price,
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
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile.adaptive(
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
            title: const Text('Serviço ativo'),
            subtitle: const Text('Inativos não aparecem no agendamento.'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: _isEditing ? 'Salvar alterações' : 'Criar serviço',
            isLoading: _isLoading,
            onPressed: _submit,
          ),
          if (_isEditing) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton.text(
              label: 'Excluir serviço',
              expanded: true,
              onPressed: _delete,
            ),
          ],
        ],
      ),
    );
  }
}

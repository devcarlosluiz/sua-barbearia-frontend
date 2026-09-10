import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/api_exception.dart';
import '../../core/network/paginated.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../models/appointment.dart';
import '../../models/barber.dart';
import '../../models/branch.dart';
import '../../models/client.dart';
import '../../models/service.dart';
import '../../providers/appointment_providers.dart';
import '../../providers/catalog_providers.dart';
import '../../providers/client_providers.dart';
import '../../providers/core_providers.dart';
import '../../widgets/widgets.dart';
import '../barber/barber_agenda_page.dart';
import '../shared/appointment_card.dart';
import '../shared/attendance_actions.dart';

/// Agenda e listagem completa de agendamentos (visão do proprietário).
class OwnerAppointmentsPage extends ConsumerStatefulWidget {
  const OwnerAppointmentsPage({super.key});

  @override
  ConsumerState<OwnerAppointmentsPage> createState() =>
      _OwnerAppointmentsPageState();
}

class _OwnerAppointmentsPageState extends ConsumerState<OwnerAppointmentsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Agenda do dia'),
              Tab(text: 'Todos os agendamentos'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [_DayAgendaTab(), _AllAppointmentsTab()],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNewAppointment(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo agendamento'),
      ),
    );
  }

  Future<void> _openNewAppointment(BuildContext context, WidgetRef ref) async {
    await AppBottomSheet.show<void>(
      context,
      title: 'Novo agendamento',
      subtitle: 'Marque um horário para um cliente.',
      child: const _NewAppointmentForm(),
    );
  }
}

class _DayAgendaTab extends ConsumerWidget {
  const _DayAgendaTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(agendaDateProvider);
    final agenda = ref.watch(agendaProvider);

    return Column(
      children: [
        DaySelector(
          date: date,
          onChanged: (value) =>
              ref.read(agendaDateProvider.notifier).state = value,
        ),
        Expanded(
          child: AsyncView<DayAgenda>(
            value: agenda,
            onRetry: () => ref.invalidate(agendaProvider),
            emptyMessage: 'Nenhum atendimento marcado para este dia.',
            isEmpty: (data) => data.appointments.isEmpty,
            emptyIcon: Icons.event_available_outlined,
            builder: (data) => ListView.separated(
              padding: Responsive.pagePadding(context),
              itemCount: data.appointments.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) => AppointmentCard(
                appointment: data.appointments[index],
                showDate: false,
                actions: [
                  AttendanceActions(appointment: data.appointments[index]),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AllAppointmentsTab extends ConsumerWidget {
  const _AllAppointmentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointments = ref.watch(appointmentListProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: AppSearchField(
            hint: 'Buscar por cliente, telefone ou serviço',
            onSearch: (value) => ref
                .read(appointmentQueryProvider.notifier)
                .update((state) => state.copyWith(search: value, page: 1)),
          ),
        ),
        Expanded(
          child: AsyncView<Paginated<Appointment>>(
            value: appointments,
            onRetry: () => ref.invalidate(appointmentListProvider),
            emptyMessage: 'Nenhum agendamento encontrado.',
            isEmpty: (page) => page.isEmpty,
            builder: (page) => ListView(
              padding: Responsive.pagePadding(context),
              children: [
                ...page.results.map(
                  (appointment) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppointmentCard(
                      appointment: appointment,
                      actions: [AttendanceActions(appointment: appointment)],
                    ),
                  ),
                ),
                AppPagination(
                  currentPage: page.currentPage,
                  totalPages: page.totalPages,
                  totalCount: page.count,
                  onPageChanged: (value) => ref
                      .read(appointmentQueryProvider.notifier)
                      .update((state) => state.copyWith(page: value)),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Formulário de agendamento manual (balcão/telefone).
class _NewAppointmentForm extends ConsumerStatefulWidget {
  const _NewAppointmentForm();

  @override
  ConsumerState<_NewAppointmentForm> createState() =>
      _NewAppointmentFormState();
}

class _NewAppointmentFormState extends ConsumerState<_NewAppointmentForm> {
  Branch? _branch;
  Service? _service;
  Barber? _barber;
  Client? _client;
  DateTime _date = DateTime.now();
  String? _slot;
  List<String> _slots = const [];
  bool _loadingSlots = false;
  bool _isSubmitting = false;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadSlots() async {
    if (_branch == null || _service == null || _barber == null) return;
    setState(() {
      _loadingSlots = true;
      _slot = null;
    });
    try {
      final result =
          await ref.read(appointmentRepositoryProvider).availableSlots(
                branchId: _branch!.id,
                barberId: _barber!.id,
                serviceId: _service!.id,
                date: _date,
              );
      if (mounted) setState(() => _slots = result.slots);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _slots = const []);
        AppFeedback.error(context, error.message);
      }
    } finally {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  Future<void> _submit() async {
    if (_branch == null ||
        _service == null ||
        _barber == null ||
        _client == null ||
        _slot == null) {
      AppFeedback.error(context, 'Preencha todos os campos obrigatórios.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(appointmentRepositoryProvider).create(
            branchId: _branch!.id,
            barberId: _barber!.id,
            serviceId: _service!.id,
            date: _date,
            startTime: _slot!,
            clientId: _client!.id,
            notes: _notesController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      AppFeedback.success(context, 'Agendamento criado com sucesso.');
      invalidateAppointmentData(ref);
    } on ApiException catch (error) {
      if (mounted) {
        AppFeedback.error(context, error.message);
        await _loadSlots();
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branches = ref.watch(branchesProvider);
    final services =
        ref.watch(servicesProvider(CatalogFilter(branchId: _branch?.id)));
    final barbers = ref.watch(
      barbersProvider(
        CatalogFilter(branchId: _branch?.id, serviceId: _service?.id),
      ),
    );
    final clients = ref.watch(clientsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        branches.when(
          loading: () => const AppSkeleton(height: 64),
          error: (_, __) => const Text('Não foi possível carregar as filiais.'),
          data: (items) => AppDropdown<Branch>(
            label: 'Filial',
            items: items,
            value: _branch,
            isRequired: true,
            itemLabel: (branch) => branch.name,
            onChanged: (branch) => setState(() {
              _branch = branch;
              _service = null;
              _barber = null;
              _slots = const [];
            }),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        services.when(
          loading: () => const AppSkeleton(height: 64),
          error: (_, __) => const SizedBox.shrink(),
          data: (items) => AppDropdown<Service>(
            label: 'Serviço',
            items: items,
            value: _service,
            isRequired: true,
            enabled: _branch != null,
            itemLabel: (service) =>
                '${service.name} · ${Formatters.currency(service.price)}',
            onChanged: (service) => setState(() {
              _service = service;
              _barber = null;
              _slots = const [];
            }),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        barbers.when(
          loading: () => const AppSkeleton(height: 64),
          error: (_, __) => const SizedBox.shrink(),
          data: (items) => AppDropdown<Barber>(
            label: 'Barbeiro',
            items: items,
            value: _barber,
            isRequired: true,
            enabled: _service != null,
            itemLabel: (barber) => barber.name,
            onChanged: (barber) {
              setState(() => _barber = barber);
              _loadSlots();
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        clients.when(
          loading: () => const AppSkeleton(height: 64),
          error: (_, __) => const SizedBox.shrink(),
          data: (page) => AppDropdown<Client>(
            label: 'Cliente',
            items: page.results,
            value: _client,
            isRequired: true,
            itemLabel: (client) =>
                '${client.name} · ${Formatters.phone(client.phone)}',
            onChanged: (client) => setState(() => _client = client),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppDatePicker(
          label: 'Data',
          value: _date,
          isRequired: true,
          firstDate: DateTime.now().subtract(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 90)),
          onChanged: (value) {
            setState(() => _date = value);
            _loadSlots();
          },
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Horário', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        if (_loadingSlots)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: AppLoading(compact: true),
          )
        else if (_slots.isEmpty)
          Text(
            _barber == null
                ? 'Escolha filial, serviço e barbeiro para ver os horários.'
                : 'Sem horários livres nesta data.',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: _slots
                .map(
                  (slot) => ChoiceChip(
                    label: Text(slot),
                    selected: _slot == slot,
                    onSelected: (_) => setState(() => _slot = slot),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Observações',
          controller: _notesController,
          maxLines: 2,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Criar agendamento',
          isLoading: _isSubmitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}

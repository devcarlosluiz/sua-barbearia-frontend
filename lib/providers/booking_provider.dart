import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/api_exception.dart';
import '../models/appointment.dart';
import '../models/barber.dart';
import '../models/branch.dart';
import '../models/service.dart';
import 'core_providers.dart';

/// Etapas do fluxo de agendamento do cliente.
enum BookingStep { branch, service, barber, date, slot, confirm }

@immutable
class BookingState {
  const BookingState({
    this.step = BookingStep.branch,
    this.branch,
    this.service,
    this.barber,
    this.date,
    this.slot,
    this.notes = '',
    this.isSubmitting = false,
    this.createdAppointment,
    this.errorMessage,
  });

  final BookingStep step;
  final Branch? branch;
  final Service? service;
  final Barber? barber;
  final DateTime? date;
  final String? slot;
  final String notes;
  final bool isSubmitting;
  final Appointment? createdAppointment;
  final String? errorMessage;

  bool get isComplete =>
      branch != null &&
      service != null &&
      barber != null &&
      date != null &&
      slot != null;

  bool get isFinished => createdAppointment != null;

  double? get price {
    final link = barber?.services
        .where((item) => item.serviceId == service?.id)
        .firstOrNull;
    return link?.price ?? service?.price;
  }

  int? get durationMinutes {
    final link = barber?.services
        .where((item) => item.serviceId == service?.id)
        .firstOrNull;
    return link?.durationMinutes ?? service?.durationMinutes;
  }

  BookingState copyWith({
    BookingStep? step,
    Branch? branch,
    Service? service,
    Barber? barber,
    DateTime? date,
    String? slot,
    String? notes,
    bool? isSubmitting,
    Appointment? createdAppointment,
    String? errorMessage,
    bool clearService = false,
    bool clearBarber = false,
    bool clearDate = false,
    bool clearSlot = false,
    bool clearError = false,
  }) {
    return BookingState(
      step: step ?? this.step,
      branch: branch ?? this.branch,
      service: clearService ? null : (service ?? this.service),
      barber: clearBarber ? null : (barber ?? this.barber),
      date: clearDate ? null : (date ?? this.date),
      slot: clearSlot ? null : (slot ?? this.slot),
      notes: notes ?? this.notes,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      createdAppointment: createdAppointment ?? this.createdAppointment,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class BookingController extends StateNotifier<BookingState> {
  BookingController(this._ref) : super(const BookingState());

  final Ref _ref;

  void selectBranch(Branch branch) {
    // Trocar de filial invalida serviço/barbeiro/horário já escolhidos.
    final changed = state.branch?.id != branch.id;
    state = state.copyWith(
      branch: branch,
      step: BookingStep.service,
      clearService: changed,
      clearBarber: changed,
      clearSlot: changed,
      clearError: true,
    );
  }

  void selectService(Service service) {
    final changed = state.service?.id != service.id;
    state = state.copyWith(
      service: service,
      step: BookingStep.barber,
      clearBarber: changed,
      clearSlot: changed,
      clearError: true,
    );
  }

  void selectBarber(Barber barber) {
    final changed = state.barber?.id != barber.id;
    state = state.copyWith(
      barber: barber,
      step: BookingStep.date,
      clearSlot: changed,
      clearError: true,
    );
  }

  void selectDate(DateTime date) {
    state = state.copyWith(
      date: DateTime(date.year, date.month, date.day),
      step: BookingStep.slot,
      clearSlot: true,
      clearError: true,
    );
  }

  void selectSlot(String slot) {
    state =
        state.copyWith(slot: slot, step: BookingStep.confirm, clearError: true);
  }

  void setNotes(String notes) => state = state.copyWith(notes: notes);

  void goTo(BookingStep step) =>
      state = state.copyWith(step: step, clearError: true);

  void back() {
    const order = BookingStep.values;
    final index = order.indexOf(state.step);
    if (index > 0) {
      state = state.copyWith(step: order[index - 1], clearError: true);
    }
  }

  void reset() => state = const BookingState();

  /// Envia o agendamento para a API. Retorna `true` em caso de sucesso.
  Future<bool> submit() async {
    if (!state.isComplete) {
      state = state.copyWith(
        errorMessage: 'Complete todas as etapas antes de confirmar.',
      );
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final appointment = await _ref.read(appointmentRepositoryProvider).create(
            branchId: state.branch!.id,
            barberId: state.barber!.id,
            serviceId: state.service!.id,
            date: state.date!,
            startTime: state.slot!,
            notes: state.notes,
          );
      state =
          state.copyWith(isSubmitting: false, createdAppointment: appointment);
      return true;
    } on ApiException catch (error) {
      state = state.copyWith(isSubmitting: false, errorMessage: error.message);
      // O horário sumiu: devolve o cliente para a escolha de horário.
      if (error.code == 'SLOT_NOT_AVAILABLE' ||
          error.code == 'SLOT_ALREADY_TAKEN') {
        state = state.copyWith(step: BookingStep.slot, clearSlot: true);
      }
      return false;
    }
  }
}

final bookingControllerProvider =
    StateNotifierProvider.autoDispose<BookingController, BookingState>(
  BookingController.new,
);

/// Horários livres para a seleção atual do fluxo de agendamento.
final bookingSlotsProvider =
    FutureProvider.autoDispose<AvailableSlots>((ref) async {
  final booking = ref.watch(bookingControllerProvider);
  if (booking.branch == null ||
      booking.barber == null ||
      booking.service == null ||
      booking.date == null) {
    // Seleção incompleta: nada a consultar ainda.
    return AvailableSlots(
      date: DateTime.now(),
      slots: const [],
      durationMinutes: 0,
      price: 0,
    );
  }

  return ref.watch(appointmentRepositoryProvider).availableSlots(
        branchId: booking.branch!.id,
        barberId: booking.barber!.id,
        serviceId: booking.service!.id,
        date: booking.date!,
      );
});

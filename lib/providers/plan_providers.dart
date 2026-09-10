import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/paginated.dart';
import '../models/plan.dart';
import 'core_providers.dart';

/// Planos visíveis ao usuário logado.
///
/// O backend já escopa por papel: o cliente só recebe os públicos e ativos,
/// o proprietário recebe todos com a contagem de assinantes.
final plansProvider = FutureProvider<List<Plan>>((ref) {
  return ref.watch(planRepositoryProvider).plans();
});

/// Detalhe do plano. Necessário para o formulário de edição, que precisa de
/// campos ausentes na listagem.
final planDetailProvider = FutureProvider.family<Plan, int>((ref, id) {
  return ref.watch(planRepositoryProvider).plan(id);
});

final planSubscribersProvider =
    FutureProvider.family<List<Subscription>, int>((ref, planId) {
  return ref.watch(planRepositoryProvider).planSubscribers(planId);
});

/// Todas as assinaturas (visão do proprietário).
final subscriptionsProvider = FutureProvider<List<Subscription>>((ref) {
  return ref.watch(planRepositoryProvider).subscriptions();
});

/// Assinatura do cliente logado — `null` quando ele não tem nenhuma.
final mySubscriptionProvider = FutureProvider<Subscription?>((ref) {
  return ref.watch(planRepositoryProvider).mySubscription();
});

final invoicesPageProvider = StateProvider<int>((ref) => 1);

/// Faturas do usuário logado (as próprias, no caso do cliente).
final myInvoicesProvider =
    FutureProvider<Paginated<SubscriptionInvoice>>((ref) {
  final page = ref.watch(invoicesPageProvider);
  return ref.watch(planRepositoryProvider).invoices(page: page);
});

/// Invalida tudo que depende de assinatura.
///
/// Assinar ou pagar muda a vitrine, a assinatura, as faturas e a cota — usar
/// um único ponto evita telas mostrando estados inconsistentes entre si.
void refreshSubscriptionState(Ref ref) {
  ref.invalidate(mySubscriptionProvider);
  ref.invalidate(myInvoicesProvider);
  ref.invalidate(plansProvider);
  ref.invalidate(subscriptionsProvider);
}

/// Versão para usar de dentro de um widget.
void refreshSubscriptionStateFrom(WidgetRef ref) {
  ref.invalidate(mySubscriptionProvider);
  ref.invalidate(myInvoicesProvider);
  ref.invalidate(plansProvider);
  ref.invalidate(subscriptionsProvider);
}

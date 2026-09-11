import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/errors/api_exception.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../models/plan.dart';
import '../../providers/core_providers.dart';
import '../../providers/plan_providers.dart';
import '../../widgets/widgets.dart';

/// Planos mensais na área do cliente: assinar, pagar e acompanhar a cota.
class ClientPlansPage extends ConsumerWidget {
  const ClientPlansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(mySubscriptionProvider);

    return Scaffold(
      body: AsyncView<Subscription?>(
        value: subscription,
        onRetry: () => ref.invalidate(mySubscriptionProvider),
        builder: (current) => ListView(
          padding: Responsive.pagePadding(context),
          children: [
            if (current != null) ...[
              _SubscriptionCard(subscription: current),
              const SizedBox(height: AppSpacing.lg),
            ],
            // Com assinatura viva, o backend recusa uma segunda — mostrar a
            // vitrine só criaria um botão que sempre falha.
            if (current == null) const _PlanShowcase(),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Vitrine
// ---------------------------------------------------------------------------
class _PlanShowcase extends ConsumerWidget {
  const _PlanShowcase();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(plansProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSectionHeader(
          title: 'Planos mensais',
          subtitle:
              'Pague uma vez no mês e use quantas vezes o plano permitir.',
        ),
        AsyncView<List<Plan>>(
          value: plans,
          onRetry: () => ref.invalidate(plansProvider),
          isEmpty: (items) => items.isEmpty,
          emptyIcon: Icons.card_membership_outlined,
          emptyMessage: 'A barbearia ainda não oferece planos mensais.',
          builder: (items) => Column(
            children: [
              for (final plan in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _PlanCard(plan: plan),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends ConsumerWidget {
  const _PlanCard({required this.plan});

  final Plan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.name, style: theme.textTheme.titleMedium),
                    if (plan.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          plan.description,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.currency(plan.price),
                    style: theme.textTheme.titleLarge
                        ?.copyWith(color: AppColors.gold),
                  ),
                  Text('por mês', style: theme.textTheme.bodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final item in plan.services)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      '${item.serviceName} · ${item.quotaLabel}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          if (plan.hasOverageDiscount) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Icons.local_offer_outlined, size: 16),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Depois da cota: '
                    '${Formatters.percent(plan.overageDiscountPercentage)} '
                    'de desconto',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Assinar plano',
            icon: Icons.card_membership_rounded,
            onPressed: () => _openCheckout(context, ref, plan),
          ),
        ],
      ),
    );
  }

  static Future<void> _openCheckout(
    BuildContext context,
    WidgetRef ref,
    Plan plan,
  ) {
    return AppBottomSheet.show<void>(
      context,
      title: 'Assinar ${plan.name}',
      subtitle: '${Formatters.currency(plan.price)} por mês',
      child: _CheckoutForm(plan: plan),
    );
  }
}

// ---------------------------------------------------------------------------
// Escolha da forma de pagamento
// ---------------------------------------------------------------------------
class _CheckoutForm extends ConsumerStatefulWidget {
  const _CheckoutForm({required this.plan});

  final Plan plan;

  @override
  ConsumerState<_CheckoutForm> createState() => _CheckoutFormState();
}

class _CheckoutFormState extends ConsumerState<_CheckoutForm> {
  BillingType _billingType = BillingType.pixMonthly;
  bool _isLoading = false;

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final subscription = await ref.read(planRepositoryProvider).subscribe(
            planId: widget.plan.id,
            billingType: _billingType,
          );
      if (!mounted) return;
      refreshSubscriptionStateFrom(ref);
      Navigator.of(context).pop();

      // O pagamento é o próximo passo obrigatório: sem ele a assinatura fica
      // pendente e não dá benefício. Levamos o cliente direto para ele.
      final invoice = subscription.openInvoice;
      if (invoice != null) {
        await _showPayment(context, ref, subscription, invoice);
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppFeedback.error(context, error.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Como você quer pagar?', style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        RadioGroup<BillingType>(
          groupValue: _billingType,
          onChanged: (value) {
            // `RadioGroup` não aceita `onChanged` nulo; ignoramos a troca
            // enquanto a assinatura está sendo criada.
            if (_isLoading || value == null) return;
            setState(() => _billingType = value);
          },
          child: Column(
            children: [
              for (final option in [
                BillingType.pixMonthly,
                BillingType.cardRecurring,
              ])
                RadioListTile<BillingType>(
                  value: option,
                  title: Text(option.label),
                  subtitle:
                      Text(option.helper, style: theme.textTheme.bodySmall),
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            const Icon(Icons.lock_outline_rounded, size: 16),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'O pagamento é processado pelo Mercado Pago. Seus dados de '
                'cartão são informados no ambiente deles e não passam pela '
                'barbearia.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Continuar para o pagamento',
          isLoading: _isLoading,
          onPressed: _submit,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pagamento
// ---------------------------------------------------------------------------
Future<void> _showPayment(
  BuildContext context,
  WidgetRef ref,
  Subscription subscription,
  SubscriptionInvoice invoice,
) {
  return AppBottomSheet.show<void>(
    context,
    title: 'Pagamento do plano',
    subtitle: '${invoice.planName} · ${Formatters.currency(invoice.amount)}',
    child: _PaymentPanel(subscription: subscription, invoice: invoice),
  );
}

class _PaymentPanel extends ConsumerStatefulWidget {
  const _PaymentPanel({required this.subscription, required this.invoice});

  final Subscription subscription;
  final SubscriptionInvoice invoice;

  @override
  ConsumerState<_PaymentPanel> createState() => _PaymentPanelState();
}

class _PaymentPanelState extends ConsumerState<_PaymentPanel> {
  late SubscriptionInvoice _invoice = widget.invoice;
  bool _isWorking = false;

  /// Verificação periódica enquanto o PIX está aberto.
  ///
  /// O Mercado Pago confirma o pagamento no backend em segundos (webhook) ou
  /// em até 20 minutos (tarefa de sincronização), mas nada disso chega sozinho
  /// ao app: sem isto o cliente fica olhando um QR Code já pago até sair e
  /// voltar da tela. A promessa de "liberação automática" logo abaixo do QR
  /// depende desta verificação para ser verdade.
  Timer? _acompanhamento;

  /// Teto de segurança para uma aba esquecida aberta.
  ///
  /// A fatura vive 60 minutos por padrão; consultar de 5 em 5 segundos durante
  /// todo esse tempo seriam ~720 requisições por cliente ocioso. Quem demorar
  /// mais que o teto ainda vê o pagamento ao reabrir a tela.
  static const _intervalo = Duration(seconds: 5);
  static const _limite = Duration(minutes: 15);
  DateTime? _inicioDoAcompanhamento;

  @override
  void initState() {
    super.initState();
    _acompanharPagamento();
  }

  @override
  void dispose() {
    _acompanhamento?.cancel();
    super.dispose();
  }

  void _acompanharPagamento() {
    _acompanhamento?.cancel();
    if (!_invoice.isPix || !_invoice.isPending || _invoice.isExpired) return;

    _inicioDoAcompanhamento = DateTime.now();
    _acompanhamento = Timer.periodic(_intervalo, _verificar);
  }

  Future<void> _verificar(Timer timer) async {
    if (!mounted) {
      timer.cancel();
      return;
    }
    final inicio = _inicioDoAcompanhamento;
    if (inicio != null && DateTime.now().difference(inicio) > _limite) {
      timer.cancel();
      return;
    }

    final Subscription? assinatura;
    try {
      assinatura = await ref.read(planRepositoryProvider).mySubscription();
    } on ApiException {
      // Uma falha isolada de rede não interrompe o acompanhamento: a próxima
      // volta do timer tenta de novo.
      return;
    }
    if (!mounted) {
      timer.cancel();
      return;
    }

    final aberta = assinatura?.openInvoice;
    final aindaEsperando = aberta != null &&
        aberta.id == _invoice.id &&
        aberta.isPending &&
        !aberta.isExpired;
    if (aindaEsperando) return;

    timer.cancel();
    refreshSubscriptionStateFrom(ref);

    if (aberta != null && aberta.isPending) {
      // Continua pendente mas expirou: mostra o estado de expirado, com o
      // botão de gerar um novo código.
      setState(() => _invoice = aberta);
      return;
    }

    // Não há mais fatura em aberto — o pagamento foi reconhecido.
    AppFeedback.success(context, 'Pagamento confirmado! Seu plano está ativo.');
    Navigator.of(context).pop();
  }

  Future<void> _copyPixCode() async {
    await Clipboard.setData(ClipboardData(text: _invoice.pixQrCode));
    if (mounted) {
      AppFeedback.success(context, 'Código PIX copiado.');
    }
  }

  Future<void> _renewPix() async {
    setState(() => _isWorking = true);
    try {
      final invoice = await ref
          .read(planRepositoryProvider)
          .renewPix(widget.subscription.id);
      if (!mounted) return;
      setState(() {
        _invoice = invoice;
        _isWorking = false;
      });
      refreshSubscriptionStateFrom(ref);
      // Código novo, acompanhamento novo: o anterior parou quando o PIX
      // expirou.
      _acompanharPagamento();
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _isWorking = false);
        AppFeedback.error(context, error.message);
      }
    }
  }

  Future<void> _openCheckout() async {
    final url = Uri.tryParse(_invoice.checkoutUrl);
    if (url == null) return;
    final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      AppFeedback.error(
        context,
        'Não foi possível abrir a página de pagamento.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_invoice.isPix) ..._pixSection(theme) else ..._cardSection(theme),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'A liberação é automática assim que o Mercado Pago confirmar o '
          'pagamento. Você recebe uma notificação no app.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }

  List<Widget> _pixSection(ThemeData theme) {
    if (_invoice.isExpired || !_invoice.hasPixData) {
      return [
        const _PaymentNotice(
          icon: Icons.timer_off_outlined,
          message: 'Este código PIX expirou. Gere um novo para pagar.',
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Gerar novo código PIX',
          isLoading: _isWorking,
          onPressed: _renewPix,
        ),
      ];
    }

    return [
      Text('Escaneie o QR Code', style: theme.textTheme.labelLarge),
      const SizedBox(height: AppSpacing.sm),
      Center(child: _PixQrImage(base64Data: _invoice.pixQrCodeBase64)),
      const SizedBox(height: AppSpacing.md),
      Text('Ou copie o código', style: theme.textTheme.labelLarge),
      const SizedBox(height: AppSpacing.xs),
      Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Text(
          _invoice.pixQrCode,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      AppButton(
        label: 'Copiar código PIX',
        icon: Icons.copy_rounded,
        onPressed: _copyPixCode,
      ),
      if (_invoice.expiresAt != null) ...[
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Válido até ${Formatters.dateTime(_invoice.expiresAt)}',
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    ];
  }

  List<Widget> _cardSection(ThemeData theme) {
    if (_invoice.checkoutUrl.isEmpty) {
      return [
        const _PaymentNotice(
          icon: Icons.error_outline_rounded,
          message: 'Não recebemos o link de pagamento. Fale com a barbearia.',
        ),
      ];
    }

    return [
      const _PaymentNotice(
        icon: Icons.lock_outline_rounded,
        message: 'Você será levado ao ambiente seguro do Mercado Pago para '
            'informar o cartão. A cobrança se repete automaticamente todo mês.',
      ),
      const SizedBox(height: AppSpacing.md),
      AppButton(
        label: 'Informar cartão no Mercado Pago',
        icon: Icons.open_in_new_rounded,
        onPressed: _openCheckout,
      ),
    ];
  }
}

class _PixQrImage extends StatelessWidget {
  const _PixQrImage({required this.base64Data});

  final String base64Data;

  @override
  Widget build(BuildContext context) {
    if (base64Data.isEmpty) return const SizedBox.shrink();

    // O provedor pode devolver com ou sem o prefixo data-uri.
    final raw =
        base64Data.contains(',') ? base64Data.split(',').last : base64Data;
    try {
      return Image.memory(
        base64Decode(raw),
        width: 220,
        height: 220,
        gaplessPlayback: true,
      );
    } on FormatException {
      // QR ilegível não deve derrubar a tela: o copia e cola segue disponível.
      return const _PaymentNotice(
        icon: Icons.qr_code_2_outlined,
        message: 'Não foi possível exibir o QR. Use o código copia e cola.',
      );
    }
  }
}

class _PaymentNotice extends StatelessWidget {
  const _PaymentNotice({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Assinatura atual
// ---------------------------------------------------------------------------
class _SubscriptionCard extends ConsumerWidget {
  const _SubscriptionCard({required this.subscription});

  final Subscription subscription;

  Color get _statusColor => switch (subscription.status) {
        SubscriptionStatus.active => AppColors.success,
        SubscriptionStatus.pendingPayment => AppColors.warning,
        SubscriptionStatus.pastDue => AppColors.danger,
        _ => AppColors.info,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final invoice = subscription.openInvoice;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Meu plano', style: theme.textTheme.bodySmall),
                    Text(
                      subscription.planName,
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              AppBadge(
                label: subscription.status.label,
                color: _statusColor,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _Info(
                label: 'Mensalidade',
                value: Formatters.currency(subscription.price),
              ),
              _Info(
                label: 'Cobrança',
                value: subscription.billingType.label,
              ),
              if (subscription.currentPeriodEnd != null)
                _Info(
                  label: 'Válido até',
                  value: Formatters.date(subscription.currentPeriodEnd),
                ),
            ],
          ),
          if (subscription.cancelAtPeriodEnd) ...[
            const SizedBox(height: AppSpacing.sm),
            _PaymentNotice(
              icon: Icons.info_outline_rounded,
              message: 'Assinatura cancelada. Você mantém os benefícios até '
                  '${Formatters.date(subscription.currentPeriodEnd)}.',
            ),
          ],
          if (subscription.quotas.isNotEmpty) ...[
            const Divider(height: AppSpacing.xl),
            Text('Seu uso neste mês', style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            for (final quota in subscription.quotas)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            quota.serviceName,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Text(quota.label, style: theme.textTheme.bodySmall),
                      ],
                    ),
                    if (!quota.isUnlimited) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: quota.progress,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
          if (invoice != null && invoice.isPending) ...[
            const Divider(height: AppSpacing.xl),
            _PaymentNotice(
              icon: Icons.pending_actions_rounded,
              message: 'Há um pagamento de '
                  '${Formatters.currency(invoice.amount)} em aberto.',
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Pagar agora',
              icon: Icons.payments_rounded,
              onPressed: () =>
                  _showPayment(context, ref, subscription, invoice),
            ),
          ],
          if (!subscription.status.isFinished &&
              !subscription.cancelAtPeriodEnd) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton.text(
              label: 'Cancelar assinatura',
              onPressed: () => _confirmCancel(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final keepsBenefit = subscription.grantsBenefit;
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Cancelar assinatura?',
      message: keepsBenefit
          ? 'Você continua com os benefícios até '
              '${Formatters.date(subscription.currentPeriodEnd)} e não será '
              'cobrado novamente.'
          : 'A assinatura será encerrada e você deixa de ter os benefícios.',
      confirmLabel: 'Cancelar plano',
      cancelLabel: 'Voltar',
      isDestructive: true,
      icon: Icons.cancel_outlined,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(planRepositoryProvider).cancel(subscription.id);
      if (!context.mounted) return;
      refreshSubscriptionStateFrom(ref);
      AppFeedback.success(context, 'Assinatura cancelada.');
    } on ApiException catch (error) {
      if (context.mounted) AppFeedback.error(context, error.message);
    }
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        Text(value, style: theme.textTheme.titleSmall),
      ],
    );
  }
}

import 'json_utils.dart';

/// Serviço incluído em um plano, com a cota do ciclo.
class PlanServiceItem {
  const PlanServiceItem({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.monthlyQuota,
    this.servicePrice = 0,
    this.serviceDurationMinutes = 0,
  });

  final int id;
  final int serviceId;
  final String serviceName;

  /// Usos por ciclo. `0` significa ilimitado.
  final int monthlyQuota;
  final double servicePrice;
  final int serviceDurationMinutes;

  bool get isUnlimited => monthlyQuota == 0;

  String get quotaLabel =>
      isUnlimited ? 'Ilimitado' : '${monthlyQuota}x por mês';

  factory PlanServiceItem.fromJson(Map<String, dynamic> json) =>
      PlanServiceItem(
        id: Json.asInt(json['id']),
        serviceId: Json.asInt(json['service']),
        serviceName: Json.asString(json['service_name']),
        monthlyQuota: Json.asInt(json['monthly_quota']),
        servicePrice: Json.asDouble(json['service_price']),
        serviceDurationMinutes: Json.asInt(json['service_duration_minutes']),
      );
}

/// Plano mensal oferecido pela barbearia.
class Plan {
  const Plan({
    required this.id,
    required this.name,
    required this.price,
    this.uuid = '',
    this.description = '',
    this.overageDiscountPercentage = 0,
    this.paysBarberCommission = true,
    this.isActive = true,
    this.isPublic = true,
    this.branchIds = const [],
    this.services = const [],
    this.subscribersCount = 0,
  });

  final int id;
  final String uuid;
  final String name;
  final String description;
  final double price;

  /// Desconto aplicado ao serviço depois que a cota do ciclo acabou.
  final double overageDiscountPercentage;

  /// Só vem no detalhe (`GET /plans/{id}/`), não na vitrine.
  final bool paysBarberCommission;
  final bool isActive;
  final bool isPublic;
  final List<int> branchIds;
  final List<PlanServiceItem> services;
  final int subscribersCount;

  bool get hasOverageDiscount => overageDiscountPercentage > 0;

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
        id: Json.asInt(json['id']),
        uuid: Json.asString(json['uuid']),
        name: Json.asString(json['name']),
        description: Json.asString(json['description']),
        price: Json.asDouble(json['price']),
        overageDiscountPercentage:
            Json.asDouble(json['overage_discount_percentage']),
        paysBarberCommission:
            Json.asBool(json['pays_barber_commission'], fallback: true),
        isActive: Json.asBool(json['is_active'], fallback: true),
        isPublic: Json.asBool(json['is_public'], fallback: true),
        branchIds: (json['branch_ids'] as List<dynamic>? ??
                json['branches'] as List<dynamic>? ??
                const [])
            .map(Json.asInt)
            .toList(),
        services: Json.asMapList(json['plan_services'])
            .map(PlanServiceItem.fromJson)
            .toList(),
        subscribersCount: Json.asInt(json['subscribers_count']),
      );
}

/// Como a mensalidade é cobrada.
///
/// O Mercado Pago não faz recorrência automática por PIX: no cartão a cobrança
/// se repete sozinha, no PIX é uma cobrança nova a cada ciclo.
enum BillingType {
  cardRecurring('CARD_RECURRING', 'Cartão de crédito'),
  pixMonthly('PIX_MONTHLY', 'PIX'),
  unknown('', 'Não informado');

  const BillingType(this.wire, this.label);

  final String wire;
  final String label;

  bool get isRecurring => this == BillingType.cardRecurring;

  String get helper => switch (this) {
        BillingType.cardRecurring =>
          'Cobrança automática todo mês. O cartão é informado no ambiente '
              'seguro do Mercado Pago.',
        BillingType.pixMonthly =>
          'Você recebe um QR Code a cada mês para renovar o plano.',
        BillingType.unknown => '',
      };

  static BillingType fromWire(Object? value) {
    final raw = Json.asString(value);
    return BillingType.values.firstWhere(
      (item) => item.wire == raw,
      orElse: () => BillingType.unknown,
    );
  }
}

enum SubscriptionStatus {
  pendingPayment('PENDING_PAYMENT', 'Aguardando pagamento'),
  active('ACTIVE', 'Ativa'),
  pastDue('PAST_DUE', 'Pagamento atrasado'),
  cancelled('CANCELLED', 'Cancelada'),
  expired('EXPIRED', 'Expirada'),
  unknown('', 'Desconhecida');

  const SubscriptionStatus(this.wire, this.label);

  final String wire;
  final String label;

  bool get needsPayment =>
      this == SubscriptionStatus.pendingPayment ||
      this == SubscriptionStatus.pastDue;

  bool get isFinished =>
      this == SubscriptionStatus.cancelled ||
      this == SubscriptionStatus.expired;

  static SubscriptionStatus fromWire(Object? value) {
    final raw = Json.asString(value);
    return SubscriptionStatus.values.firstWhere(
      (item) => item.wire == raw,
      orElse: () => SubscriptionStatus.unknown,
    );
  }
}

enum InvoiceStatus {
  pending('PENDING', 'Aguardando pagamento'),
  paid('PAID', 'Paga'),
  cancelled('CANCELLED', 'Cancelada'),
  expired('EXPIRED', 'Expirada'),
  refunded('REFUNDED', 'Estornada'),
  unknown('', 'Desconhecida');

  const InvoiceStatus(this.wire, this.label);

  final String wire;
  final String label;

  static InvoiceStatus fromWire(Object? value) {
    final raw = Json.asString(value);
    return InvoiceStatus.values.firstWhere(
      (item) => item.wire == raw,
      orElse: () => InvoiceStatus.unknown,
    );
  }
}

/// Cobrança de um ciclo da assinatura.
class SubscriptionInvoice {
  const SubscriptionInvoice({
    required this.id,
    required this.amount,
    required this.status,
    this.uuid = '',
    this.subscriptionId,
    this.planName = '',
    this.clientName = '',
    this.method = '',
    this.periodStart,
    this.periodEnd,
    this.dueDate,
    this.pixQrCode = '',
    this.pixQrCodeBase64 = '',
    this.checkoutUrl = '',
    this.expiresAt,
    this.paidAt,
  });

  final int id;
  final String uuid;
  final int? subscriptionId;
  final String planName;
  final String clientName;
  final double amount;
  final String method;
  final InvoiceStatus status;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime? dueDate;

  /// PIX copia e cola. Não é segredo: existe para ser exibido e copiado.
  final String pixQrCode;

  /// Imagem do QR em base64, pronta para `Image.memory`.
  final String pixQrCodeBase64;

  /// Página de checkout do provedor — usada no cartão.
  final String checkoutUrl;
  final DateTime? expiresAt;
  final DateTime? paidAt;

  bool get isPix => method == 'PIX';
  bool get isPending => status == InvoiceStatus.pending;
  bool get hasPixData => pixQrCode.isNotEmpty;

  bool get isExpired {
    final at = expiresAt;
    if (at == null) return false;
    return DateTime.now().isAfter(at);
  }

  factory SubscriptionInvoice.fromJson(Map<String, dynamic> json) =>
      SubscriptionInvoice(
        id: Json.asInt(json['id']),
        uuid: Json.asString(json['uuid']),
        subscriptionId: Json.asIntOrNull(json['subscription']),
        planName: Json.asString(json['plan_name']),
        clientName: Json.asString(json['client_name']),
        amount: Json.asDouble(json['amount']),
        method: Json.asString(json['method']),
        status: InvoiceStatus.fromWire(json['status']),
        periodStart: Json.asDate(json['period_start']),
        periodEnd: Json.asDate(json['period_end']),
        dueDate: Json.asDate(json['due_date']),
        pixQrCode: Json.asString(json['pix_qr_code']),
        pixQrCodeBase64: Json.asString(json['pix_qr_code_base64']),
        checkoutUrl: Json.asString(json['checkout_url']),
        expiresAt: Json.asDate(json['expires_at']),
        paidAt: Json.asDate(json['paid_at']),
      );
}

/// Cota de um serviço no ciclo atual.
class SubscriptionQuota {
  const SubscriptionQuota({
    required this.serviceId,
    required this.serviceName,
    required this.monthlyQuota,
    required this.used,
    this.isUnlimited = false,
    this.remaining,
  });

  final int serviceId;
  final String serviceName;
  final int monthlyQuota;
  final int used;
  final bool isUnlimited;

  /// `null` quando ilimitado.
  final int? remaining;

  String get label {
    if (isUnlimited) return 'Ilimitado · $used usado(s)';
    return '${remaining ?? 0} de $monthlyQuota restante(s)';
  }

  double get progress {
    if (isUnlimited || monthlyQuota == 0) return 0;
    return (used / monthlyQuota).clamp(0, 1).toDouble();
  }

  factory SubscriptionQuota.fromJson(Map<String, dynamic> json) =>
      SubscriptionQuota(
        serviceId: Json.asInt(json['service']),
        serviceName: Json.asString(json['service_name']),
        monthlyQuota: Json.asInt(json['monthly_quota']),
        used: Json.asInt(json['used']),
        isUnlimited: Json.asBool(json['is_unlimited']),
        remaining: Json.asIntOrNull(json['remaining']),
      );
}

/// Assinatura de um plano por um cliente.
class Subscription {
  const Subscription({
    required this.id,
    required this.planId,
    required this.status,
    required this.billingType,
    required this.price,
    this.uuid = '',
    this.clientId,
    this.clientName = '',
    this.clientPhone = '',
    this.plan,
    this.branchId,
    this.branchName = '',
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.grantsBenefit = false,
    this.cancelAtPeriodEnd = false,
    this.startedAt,
    this.cancelledAt,
    this.quotas = const [],
    this.openInvoice,
  });

  final int id;
  final String uuid;
  final int? clientId;
  final String clientName;
  final String clientPhone;
  final int planId;
  final Plan? plan;
  final int? branchId;
  final String branchName;
  final SubscriptionStatus status;
  final BillingType billingType;
  final double price;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;

  /// Calculado no backend: só é `true` com ciclo pago e dentro da validade.
  final bool grantsBenefit;
  final bool cancelAtPeriodEnd;
  final DateTime? startedAt;
  final DateTime? cancelledAt;
  final List<SubscriptionQuota> quotas;

  /// Cobrança que o cliente precisa pagar agora, se houver.
  final SubscriptionInvoice? openInvoice;

  String get planName => plan?.name ?? 'Plano #$planId';

  bool get needsPayment => openInvoice != null && openInvoice!.isPending;

  factory Subscription.fromJson(Map<String, dynamic> json) {
    final planJson = Json.asMap(json['plan_detail']);
    final invoiceJson = Json.asMap(json['open_invoice']);
    return Subscription(
      id: Json.asInt(json['id']),
      uuid: Json.asString(json['uuid']),
      clientId: Json.asIntOrNull(json['client']),
      clientName: Json.asString(json['client_name']),
      clientPhone: Json.asString(json['client_phone']),
      planId: Json.asInt(json['plan']),
      plan: planJson.isEmpty ? null : Plan.fromJson(planJson),
      branchId: Json.asIntOrNull(json['branch']),
      branchName: Json.asString(json['branch_name']),
      status: SubscriptionStatus.fromWire(json['status']),
      billingType: BillingType.fromWire(json['billing_type']),
      price: Json.asDouble(json['price']),
      currentPeriodStart: Json.asDate(json['current_period_start']),
      currentPeriodEnd: Json.asDate(json['current_period_end']),
      grantsBenefit: Json.asBool(json['grants_benefit']),
      cancelAtPeriodEnd: Json.asBool(json['cancel_at_period_end']),
      startedAt: Json.asDate(json['started_at']),
      cancelledAt: Json.asDate(json['cancelled_at']),
      quotas: Json.asMapList(json['quotas'])
          .map(SubscriptionQuota.fromJson)
          .toList(),
      openInvoice: invoiceJson.isEmpty
          ? null
          : SubscriptionInvoice.fromJson(invoiceJson),
    );
  }
}

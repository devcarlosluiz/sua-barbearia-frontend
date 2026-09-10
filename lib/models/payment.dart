import 'json_utils.dart';

enum PaymentMethod {
  pix('PIX', 'PIX'),
  cash('CASH', 'Dinheiro'),
  creditCard('CREDIT_CARD', 'Cartão de crédito'),
  debitCard('DEBIT_CARD', 'Cartão de débito'),
  loyalty('LOYALTY', 'Pontos de fidelidade'),
  other('OTHER', 'Outro');

  const PaymentMethod(this.value, this.label);

  final String value;
  final String label;

  static PaymentMethod fromValue(String? value) =>
      PaymentMethod.values.firstWhere(
        (method) => method.value == value,
        orElse: () => PaymentMethod.other,
      );

  /// Métodos oferecidos no caixa (fidelidade é aplicada como desconto).
  static List<PaymentMethod> get checkoutOptions => const [
        PaymentMethod.pix,
        PaymentMethod.creditCard,
        PaymentMethod.debitCard,
        PaymentMethod.cash,
        PaymentMethod.other,
      ];
}

enum PaymentStatus {
  pending('PENDING', 'Pendente'),
  paid('PAID', 'Pago'),
  cancelled('CANCELLED', 'Cancelado'),
  refunded('REFUNDED', 'Estornado');

  const PaymentStatus(this.value, this.label);

  final String value;
  final String label;

  static PaymentStatus fromValue(String? value) =>
      PaymentStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => PaymentStatus.pending,
      );
}

class Payment {
  const Payment({
    required this.id,
    required this.uuid,
    required this.branchId,
    required this.amount,
    required this.method,
    required this.status,
    this.branchName = '',
    this.clientName,
    this.appointmentId,
    this.saleId,
    this.discountAmount = 0,
    this.netAmount = 0,
    this.paidAt,
    this.refundedAt,
    this.notes = '',
    this.createdAt,
  });

  final int id;
  final String uuid;
  final int branchId;
  final String branchName;
  final String? clientName;
  final int? appointmentId;
  final int? saleId;
  final double amount;
  final double discountAmount;
  final double netAmount;
  final PaymentMethod method;
  final PaymentStatus status;
  final DateTime? paidAt;
  final DateTime? refundedAt;
  final String notes;
  final DateTime? createdAt;

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: Json.asInt(json['id']),
        uuid: Json.asString(json['uuid']),
        branchId: Json.asInt(json['branch']),
        branchName: Json.asString(json['branch_name']),
        clientName: Json.asStringOrNull(json['client_name']),
        appointmentId: Json.asIntOrNull(json['appointment']),
        saleId: Json.asIntOrNull(json['sale']),
        amount: Json.asDouble(json['amount']),
        discountAmount: Json.asDouble(json['discount_amount']),
        netAmount: Json.asDouble(json['net_amount']),
        method: PaymentMethod.fromValue(json['method'] as String?),
        status: PaymentStatus.fromValue(json['status'] as String?),
        paidAt: Json.asDate(json['paid_at']),
        refundedAt: Json.asDate(json['refunded_at']),
        notes: Json.asString(json['notes']),
        createdAt: Json.asDate(json['created_at']),
      );
}

import 'json_utils.dart';

enum TransactionType {
  income('INCOME', 'Receita'),
  expense('EXPENSE', 'Despesa');

  const TransactionType(this.value, this.label);

  final String value;
  final String label;

  static TransactionType fromValue(String? value) =>
      TransactionType.values.firstWhere(
        (type) => type.value == value,
        orElse: () => TransactionType.income,
      );
}

class FinanceTransaction {
  const FinanceTransaction({
    required this.id,
    required this.uuid,
    required this.branchId,
    required this.type,
    required this.category,
    required this.categoryLabel,
    required this.description,
    required this.amount,
    required this.date,
    this.branchName = '',
    this.barberName,
    this.createdByName,
    this.notes = '',
    this.isAutomatic = false,
  });

  final int id;
  final String uuid;
  final int branchId;
  final String branchName;
  final TransactionType type;
  final String category;
  final String categoryLabel;
  final String description;
  final double amount;
  final DateTime date;
  final String? barberName;
  final String? createdByName;
  final String notes;
  final bool isAutomatic;

  double get signedAmount => type == TransactionType.income ? amount : -amount;

  factory FinanceTransaction.fromJson(Map<String, dynamic> json) =>
      FinanceTransaction(
        id: Json.asInt(json['id']),
        uuid: Json.asString(json['uuid']),
        branchId: Json.asInt(json['branch']),
        branchName: Json.asString(json['branch_name']),
        type: TransactionType.fromValue(json['type'] as String?),
        category: Json.asString(json['category']),
        categoryLabel: Json.asString(json['category_display']),
        description: Json.asString(json['description']),
        amount: Json.asDouble(json['amount']),
        date: Json.asDate(json['date']) ?? DateTime.now(),
        barberName: Json.asStringOrNull(json['barber_name']),
        createdByName: Json.asStringOrNull(json['created_by_name']),
        notes: Json.asString(json['notes']),
        isAutomatic: Json.asBool(json['is_automatic']),
      );
}

class Commission {
  const Commission({
    required this.id,
    required this.barberId,
    required this.barberName,
    required this.amount,
    required this.percentage,
    required this.baseAmount,
    required this.status,
    required this.referenceDate,
    this.branchName = '',
    this.serviceName,
    this.clientName,
    this.paidAt,
  });

  final int id;
  final int barberId;
  final String barberName;
  final String branchName;
  final double baseAmount;
  final double percentage;
  final double amount;
  final String status;
  final DateTime referenceDate;
  final String? serviceName;
  final String? clientName;
  final DateTime? paidAt;

  bool get isPending => status == 'PENDING';
  bool get isPaid => status == 'PAID';

  String get statusLabel {
    switch (status) {
      case 'PENDING':
        return 'Pendente';
      case 'PAID':
        return 'Paga';
      case 'CANCELLED':
        return 'Cancelada';
      default:
        return status;
    }
  }

  factory Commission.fromJson(Map<String, dynamic> json) => Commission(
        id: Json.asInt(json['id']),
        barberId: Json.asInt(json['barber']),
        barberName: Json.asString(json['barber_name']),
        branchName: Json.asString(json['branch_name']),
        baseAmount: Json.asDouble(json['base_amount']),
        percentage: Json.asDouble(json['percentage']),
        amount: Json.asDouble(json['amount']),
        status: Json.asString(json['status']),
        referenceDate: Json.asDate(json['reference_date']) ?? DateTime.now(),
        serviceName: Json.asStringOrNull(json['service_name']),
        clientName: Json.asStringOrNull(json['client_name']),
        paidAt: Json.asDate(json['paid_at']),
      );
}

/// Resumo de caixa por período (`GET /finance/transactions/summary/`).
class CashFlowSummary {
  const CashFlowSummary({
    required this.startDate,
    required this.endDate,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    this.byCategory = const [],
    this.byPaymentMethod = const [],
    this.daily = const [],
  });

  final DateTime startDate;
  final DateTime endDate;
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final List<CategoryTotal> byCategory;
  final List<MethodTotal> byPaymentMethod;
  final List<DailyTotal> daily;

  factory CashFlowSummary.fromJson(Map<String, dynamic> json) =>
      CashFlowSummary(
        startDate: Json.asDate(json['start_date']) ?? DateTime.now(),
        endDate: Json.asDate(json['end_date']) ?? DateTime.now(),
        totalIncome: Json.asDouble(json['total_income']),
        totalExpense: Json.asDouble(json['total_expense']),
        balance: Json.asDouble(json['balance']),
        byCategory: Json.asMapList(json['by_category'])
            .map(CategoryTotal.fromJson)
            .toList(),
        byPaymentMethod: Json.asMapList(json['by_payment_method'])
            .map(MethodTotal.fromJson)
            .toList(),
        daily: Json.asMapList(json['daily']).map(DailyTotal.fromJson).toList(),
      );
}

class CategoryTotal {
  const CategoryTotal({
    required this.category,
    required this.type,
    required this.total,
    required this.count,
  });

  final String category;
  final String type;
  final double total;
  final int count;

  factory CategoryTotal.fromJson(Map<String, dynamic> json) => CategoryTotal(
        category: Json.asString(json['category']),
        type: Json.asString(json['type']),
        total: Json.asDouble(json['total']),
        count: Json.asInt(json['count']),
      );
}

class MethodTotal {
  const MethodTotal({
    required this.method,
    required this.total,
    required this.count,
  });

  final String method;
  final double total;
  final int count;

  factory MethodTotal.fromJson(Map<String, dynamic> json) => MethodTotal(
        method: Json.asString(json['method']),
        total: Json.asDouble(json['total']),
        count: Json.asInt(json['count']),
      );
}

class DailyTotal {
  const DailyTotal({required this.date, required this.total, this.type = ''});

  final DateTime date;
  final double total;
  final String type;

  factory DailyTotal.fromJson(Map<String, dynamic> json) => DailyTotal(
        date: Json.asDate(json['day'] ?? json['date']) ?? DateTime.now(),
        total: Json.asDouble(json['total']),
        type: Json.asString(json['type']),
      );
}

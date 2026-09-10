import 'json_utils.dart';

class LoyaltyAccount {
  const LoyaltyAccount({
    required this.id,
    required this.balance,
    required this.lifetimeEarned,
    required this.lifetimeRedeemed,
    this.clientName = '',
    this.pointsValue = 0,
  });

  final int id;
  final String clientName;
  final int balance;
  final int lifetimeEarned;
  final int lifetimeRedeemed;
  final double pointsValue;

  factory LoyaltyAccount.fromJson(Map<String, dynamic> json) => LoyaltyAccount(
        id: Json.asInt(json['id']),
        clientName: Json.asString(json['client_name']),
        balance: Json.asInt(json['balance']),
        lifetimeEarned: Json.asInt(json['lifetime_earned']),
        lifetimeRedeemed: Json.asInt(json['lifetime_redeemed']),
        pointsValue: Json.asDouble(json['points_value']),
      );
}

class LoyaltyTransaction {
  const LoyaltyTransaction({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.points,
    required this.balanceAfter,
    this.description = '',
    this.rewardName,
    this.createdAt,
  });

  final int id;
  final String type;
  final String typeLabel;
  final int points;
  final int balanceAfter;
  final String description;
  final String? rewardName;
  final DateTime? createdAt;

  bool get isCredit => points > 0;

  factory LoyaltyTransaction.fromJson(Map<String, dynamic> json) =>
      LoyaltyTransaction(
        id: Json.asInt(json['id']),
        type: Json.asString(json['type']),
        typeLabel: Json.asString(json['type_display']),
        points: Json.asInt(json['points']),
        balanceAfter: Json.asInt(json['balance_after']),
        description: Json.asString(json['description']),
        rewardName: Json.asStringOrNull(json['reward_name']),
        createdAt: Json.asDate(json['created_at']),
      );
}

class LoyaltyReward {
  const LoyaltyReward({
    required this.id,
    required this.name,
    required this.pointsCost,
    required this.type,
    this.description = '',
    this.typeLabel = '',
    this.discountValue = 0,
    this.serviceName,
    this.validUntil,
    this.isActive = true,
  });

  final int id;
  final String name;
  final String description;
  final String type;
  final String typeLabel;
  final int pointsCost;
  final double discountValue;
  final String? serviceName;
  final DateTime? validUntil;
  final bool isActive;

  bool canBeRedeemedWith(int balance) => isActive && balance >= pointsCost;

  factory LoyaltyReward.fromJson(Map<String, dynamic> json) => LoyaltyReward(
        id: Json.asInt(json['id']),
        name: Json.asString(json['name']),
        description: Json.asString(json['description']),
        type: Json.asString(json['type']),
        typeLabel: Json.asString(json['type_display']),
        pointsCost: Json.asInt(json['points_cost']),
        discountValue: Json.asDouble(json['discount_value']),
        serviceName: Json.asStringOrNull(json['service_name']),
        validUntil: Json.asDate(json['valid_until']),
        isActive: Json.asBool(json['is_active'], fallback: true),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'type': type,
        'points_cost': pointsCost,
        'discount_value': discountValue.toStringAsFixed(2),
        'is_active': isActive,
      };
}

/// Retorno de `GET /loyalty/accounts/me/`.
class LoyaltySummary {
  const LoyaltySummary({required this.account, required this.transactions});

  final LoyaltyAccount account;
  final List<LoyaltyTransaction> transactions;

  factory LoyaltySummary.fromJson(Map<String, dynamic> json) => LoyaltySummary(
        account: LoyaltyAccount.fromJson(Json.asMap(json['account'])),
        transactions: Json.asMapList(json['transactions'])
            .map(LoyaltyTransaction.fromJson)
            .toList(),
      );
}

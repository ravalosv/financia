import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 3)
class Transaction {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String accountId;

  @HiveField(3)
  final String categoryId;

  @HiveField(4)
  final double amount;

  @HiveField(5)
  final String type; // income, expense

  @HiveField(6)
  final DateTime transactionDate;

  @HiveField(7)
  final String? description;

  @HiveField(8)
  final String? merchant;

  @HiveField(9)
  final bool isRecurring;

  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  final double exchangeRate;

  @HiveField(12)
  final String? installmentPlanId;

  @HiveField(13)
  final int? installmentIndex;

  @HiveField(14)
  final int? installmentCount;

  @HiveField(15)
  final DateTime? purchaseDate;

  Transaction({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.categoryId,
    required this.amount,
    required this.type,
    required this.transactionDate,
    this.description,
    this.merchant,
    this.isRecurring = false,
    required this.createdAt,
    this.exchangeRate = 1.0,
    this.installmentPlanId,
    this.installmentIndex,
    this.installmentCount,
    this.purchaseDate,
  });

  Transaction copyWith({
    String? id,
    String? userId,
    String? accountId,
    String? categoryId,
    double? amount,
    String? type,
    DateTime? transactionDate,
    String? description,
    String? merchant,
    bool? isRecurring,
    DateTime? createdAt,
    double? exchangeRate,
    String? installmentPlanId,
    int? installmentIndex,
    int? installmentCount,
    DateTime? purchaseDate,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      transactionDate: transactionDate ?? this.transactionDate,
      description: description ?? this.description,
      merchant: merchant ?? this.merchant,
      isRecurring: isRecurring ?? this.isRecurring,
      createdAt: createdAt ?? this.createdAt,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      installmentPlanId: installmentPlanId ?? this.installmentPlanId,
      installmentIndex: installmentIndex ?? this.installmentIndex,
      installmentCount: installmentCount ?? this.installmentCount,
      purchaseDate: purchaseDate ?? this.purchaseDate,
    );
  }

  bool get isInstallmentPlan =>
      installmentPlanId != null &&
      installmentPlanId!.isNotEmpty &&
      installmentIndex != null &&
      installmentCount != null;

  String? get installmentLabel =>
      isInstallmentPlan ? 'Mes $installmentIndex de $installmentCount' : null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'account_id': accountId,
      'category_id': categoryId,
      'amount': amount,
      'type': type,
      'transaction_date': transactionDate.toIso8601String(),
      'purchase_date': purchaseDate?.toIso8601String(),
      'description': description,
      'merchant': merchant,
      'is_recurring': isRecurring,
      'created_at': createdAt.toIso8601String(),
      'exchange_rate': exchangeRate,
      'installment_plan_id': installmentPlanId,
      'installment_index': installmentIndex,
      'installment_count': installmentCount,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      userId: json['user_id'],
      accountId: json['account_id'],
      categoryId: json['category_id'],
      amount: json['amount'].toDouble(),
      type: json['type'],
      transactionDate: DateTime.parse(json['transaction_date']),
      purchaseDate: json['purchase_date'] != null
          ? DateTime.parse(json['purchase_date'])
          : null,
      description: json['description'],
      merchant: json['merchant'],
      isRecurring: json['is_recurring'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      exchangeRate: (json['exchange_rate'] ?? 1.0).toDouble(),
      installmentPlanId: json['installment_plan_id'] as String?,
      installmentIndex: (json['installment_index'] as num?)?.toInt(),
      installmentCount: (json['installment_count'] as num?)?.toInt(),
    );
  }
}

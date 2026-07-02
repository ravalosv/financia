import 'package:hive/hive.dart';

part 'budget_model.g.dart';

@HiveType(typeId: 4)
class Budget {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String categoryId;

  @HiveField(3)
  final double amount;

  @HiveField(4)
  final String monthYear; // Format: YYYY-MM

  @HiveField(5)
  final double spent;

  @HiveField(6)
  final double remaining;

  @HiveField(7)
  final double rolloverFromPrevious;

  @HiveField(8)
  final DateTime createdAt;

  Budget({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.monthYear,
    this.spent = 0.0,
    this.remaining = 0.0,
    this.rolloverFromPrevious = 0.0,
    required this.createdAt,
  });

  Budget copyWith({
    String? id,
    String? userId,
    String? categoryId,
    double? amount,
    String? monthYear,
    double? spent,
    double? remaining,
    double? rolloverFromPrevious,
    DateTime? createdAt,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      monthYear: monthYear ?? this.monthYear,
      spent: spent ?? this.spent,
      remaining: remaining ?? this.remaining,
      rolloverFromPrevious: rolloverFromPrevious ?? this.rolloverFromPrevious,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'month_year': monthYear,
      'spent': spent,
      'remaining': remaining,
      'rollover_from_previous': rolloverFromPrevious,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      userId: json['user_id'],
      categoryId: json['category_id'],
      amount: json['amount'].toDouble(),
      monthYear: json['month_year'],
      spent: json['spent']?.toDouble() ?? 0.0,
      remaining: json['remaining']?.toDouble() ?? 0.0,
      rolloverFromPrevious: json['rollover_from_previous']?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

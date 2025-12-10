import 'package:hive/hive.dart';

part 'account_model.g.dart';

@HiveType(typeId: 1)
class Account {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String userId;
  
  @HiveField(2)
  final String name;
  
  @HiveField(3)
  final String type; // cash, checking, savings, credit, investment
  
  @HiveField(4)
  final String currency;
  
  @HiveField(5)
  final double balance;
  
  @HiveField(6)
  final bool isActive;
  
  @HiveField(7)
  final DateTime createdAt;

  Account({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.currency,
    this.balance = 0.0,
    this.isActive = true,
    required this.createdAt,
  });

  Account copyWith({
    String? id,
    String? userId,
    String? name,
    String? type,
    String? currency,
    double? balance,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Account(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      balance: balance ?? this.balance,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'type': type,
      'currency': currency,
      'balance': balance,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      type: json['type'],
      currency: json['currency'],
      balance: json['balance']?.toDouble() ?? 0.0,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
import 'package:hive/hive.dart';

part 'category_model.g.dart';

@HiveType(typeId: 2)
class Category {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String userId;
  
  @HiveField(2)
  final String name;
  
  @HiveField(3)
  final String type; // income, expense
  
  @HiveField(4)
  final String icon;
  
  @HiveField(5)
  final String color;
  
  @HiveField(6)
  final double? budgetLimit;
  
  @HiveField(7)
  final bool isCustom;
  
  @HiveField(8)
  final DateTime createdAt;

  Category({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.icon = 'category',
    this.color = '#6B7280',
    this.budgetLimit,
    this.isCustom = true,
    required this.createdAt,
  });

  Category copyWith({
    String? id,
    String? userId,
    String? name,
    String? type,
    String? icon,
    String? color,
    double? budgetLimit,
    bool? isCustom,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      budgetLimit: budgetLimit ?? this.budgetLimit,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      'budget_limit': budgetLimit,
      'is_custom': isCustom,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      type: json['type'],
      icon: json['icon'] ?? 'category',
      color: json['color'] ?? '#6B7280',
      budgetLimit: json['budget_limit']?.toDouble(),
      isCustom: json['is_custom'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
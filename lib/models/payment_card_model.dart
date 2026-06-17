import 'package:hive/hive.dart';

part 'payment_card_model.g.dart';

@HiveType(typeId: 7)
class PaymentCard {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String cardType; // debit, credit

  @HiveField(4)
  final String encryptedNumber;

  @HiveField(5)
  final String last4;

  @HiveField(6)
  final int expiryMonth;

  @HiveField(7)
  final int expiryYear;

  @HiveField(8)
  final String encryptedCvv;

  @HiveField(9)
  final bool isVirtual;

  @HiveField(10)
  final String? encryptedPin;

  @HiveField(11)
  final int? statementDay;

  @HiveField(12)
  final int? paymentDay;

  @HiveField(13)
  final String? linkedAccountId;

  @HiveField(14)
  final DateTime createdAt;

  @HiveField(15)
  final DateTime updatedAt;

  const PaymentCard({
    required this.id,
    required this.userId,
    required this.name,
    required this.cardType,
    required this.encryptedNumber,
    required this.last4,
    required this.expiryMonth,
    required this.expiryYear,
    required this.encryptedCvv,
    required this.isVirtual,
    this.encryptedPin,
    this.statementDay,
    this.paymentDay,
    this.linkedAccountId,
    required this.createdAt,
    required this.updatedAt,
  });

  PaymentCard copyWith({
    String? id,
    String? userId,
    String? name,
    String? cardType,
    String? encryptedNumber,
    String? last4,
    int? expiryMonth,
    int? expiryYear,
    String? encryptedCvv,
    bool? isVirtual,
    String? encryptedPin,
    bool clearPin = false,
    int? statementDay,
    bool clearStatementDay = false,
    int? paymentDay,
    bool clearPaymentDay = false,
    String? linkedAccountId,
    bool clearLinkedAccountId = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentCard(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      cardType: cardType ?? this.cardType,
      encryptedNumber: encryptedNumber ?? this.encryptedNumber,
      last4: last4 ?? this.last4,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      encryptedCvv: encryptedCvv ?? this.encryptedCvv,
      isVirtual: isVirtual ?? this.isVirtual,
      encryptedPin: clearPin ? null : (encryptedPin ?? this.encryptedPin),
      statementDay: clearStatementDay
          ? null
          : (statementDay ?? this.statementDay),
      paymentDay: clearPaymentDay ? null : (paymentDay ?? this.paymentDay),
      linkedAccountId: clearLinkedAccountId
          ? null
          : (linkedAccountId ?? this.linkedAccountId),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get maskedNumber => '****-****-****-$last4';

  String get expiryLabel =>
      '${expiryMonth.toString().padLeft(2, '0')}/${(expiryYear % 100).toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'card_type': cardType,
      'encrypted_number': encryptedNumber,
      'last4': last4,
      'expiry_month': expiryMonth,
      'expiry_year': expiryYear,
      'encrypted_cvv': encryptedCvv,
      'is_virtual': isVirtual,
      'encrypted_pin': encryptedPin,
      'statement_day': statementDay,
      'payment_day': paymentDay,
      'linked_account_id': linkedAccountId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory PaymentCard.fromJson(Map<String, dynamic> json) {
    return PaymentCard(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      cardType: json['card_type'] as String,
      encryptedNumber: json['encrypted_number'] as String,
      last4: json['last4'] as String,
      expiryMonth: (json['expiry_month'] as num).toInt(),
      expiryYear: (json['expiry_year'] as num).toInt(),
      encryptedCvv: json['encrypted_cvv'] as String,
      isVirtual: json['is_virtual'] as bool? ?? false,
      encryptedPin: json['encrypted_pin'] as String?,
      statementDay: (json['statement_day'] as num?)?.toInt(),
      paymentDay: (json['payment_day'] as num?)?.toInt(),
      linkedAccountId: json['linked_account_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

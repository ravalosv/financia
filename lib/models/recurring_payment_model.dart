class RecurringPayment {
  final String id;
  final String userId;
  final String recipient;
  final double amount;
  final int dayOfMonth;
  final bool requiresReminder;
  final int reminderDays;
  final int? totalPayments;
  final DateTime createdAt;
  final bool isActive;
  final List<String> completedMonthKeys;
  final Map<String, String> linkedTransactionIdsByMonth;

  const RecurringPayment({
    required this.id,
    required this.userId,
    required this.recipient,
    required this.amount,
    required this.dayOfMonth,
    required this.requiresReminder,
    required this.reminderDays,
    required this.createdAt,
    this.totalPayments,
    this.isActive = true,
    this.completedMonthKeys = const [],
    this.linkedTransactionIdsByMonth = const {},
  });

  bool get isIndefinite => totalPayments == null;

  int get completedPaymentsCount => completedMonthKeys.toSet().length;

  RecurringPayment copyWith({
    String? id,
    String? userId,
    String? recipient,
    double? amount,
    int? dayOfMonth,
    bool? requiresReminder,
    int? reminderDays,
    int? totalPayments,
    bool clearTotalPayments = false,
    DateTime? createdAt,
    bool? isActive,
    List<String>? completedMonthKeys,
    Map<String, String>? linkedTransactionIdsByMonth,
  }) {
    return RecurringPayment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      recipient: recipient ?? this.recipient,
      amount: amount ?? this.amount,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      requiresReminder: requiresReminder ?? this.requiresReminder,
      reminderDays: reminderDays ?? this.reminderDays,
      totalPayments: clearTotalPayments
          ? null
          : (totalPayments ?? this.totalPayments),
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      completedMonthKeys: completedMonthKeys ?? this.completedMonthKeys,
      linkedTransactionIdsByMonth:
          linkedTransactionIdsByMonth ?? this.linkedTransactionIdsByMonth,
    );
  }

  int get _startMonthIndex => (createdAt.year * 12) + createdAt.month - 1;

  bool isScheduledForMonth(DateTime month) {
    if (!isActive) return false;
    final monthIndex = (month.year * 12) + month.month - 1;
    if (monthIndex < _startMonthIndex) return false;
    if (totalPayments == null) return true;
    return monthIndex < _startMonthIndex + totalPayments!;
  }

  DateTime occurrenceDateForMonth(DateTime month) {
    final safeDay = dayOfMonth.clamp(1, _daysInMonth(month.year, month.month));
    return DateTime(month.year, month.month, safeDay);
  }

  DateTime reminderStartForMonth(DateTime month) {
    final dueDate = occurrenceDateForMonth(month);
    return DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
    ).subtract(Duration(days: reminderDays.clamp(0, 31)));
  }

  bool isCompletedForMonth(DateTime month) {
    final key = monthKeyFor(month);
    return completedMonthKeys.contains(key) ||
        linkedTransactionIdsByMonth.containsKey(key);
  }

  String? linkedTransactionIdForMonth(DateTime month) {
    return linkedTransactionIdsByMonth[monthKeyFor(month)];
  }

  RecurringPayment markCompletedForMonth(DateTime month) {
    final key = monthKeyFor(month);
    final keys = completedMonthKeys.toSet()..add(key);
    return copyWith(completedMonthKeys: keys.toList()..sort());
  }

  RecurringPayment linkTransactionForMonth(
    DateTime month,
    String transactionId,
  ) {
    final key = monthKeyFor(month);
    final keys = completedMonthKeys.toSet()..add(key);
    final linkedIds = Map<String, String>.from(linkedTransactionIdsByMonth)
      ..[key] = transactionId;
    return copyWith(
      completedMonthKeys: keys.toList()..sort(),
      linkedTransactionIdsByMonth: linkedIds,
    );
  }

  RecurringPayment unmarkCompletedForMonth(DateTime month) {
    final key = monthKeyFor(month);
    final keys = completedMonthKeys.toSet()..remove(key);
    final linkedIds = Map<String, String>.from(linkedTransactionIdsByMonth)
      ..remove(key);
    return copyWith(
      completedMonthKeys: keys.toList()..sort(),
      linkedTransactionIdsByMonth: linkedIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'recipient': recipient,
      'amount': amount,
      'day_of_month': dayOfMonth,
      'requires_reminder': requiresReminder,
      'reminder_days': reminderDays,
      'total_payments': totalPayments,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
      'completed_month_keys': completedMonthKeys,
      'linked_transaction_ids_by_month': linkedTransactionIdsByMonth,
    };
  }

  factory RecurringPayment.fromJson(Map<String, dynamic> json) {
    final completed =
        (json['completed_month_keys'] as List<dynamic>? ?? [])
            .map((item) => item.toString())
            .toSet()
            .toList()
          ..sort();
    final linkedIds = Map<String, String>.from(
      (json['linked_transaction_ids_by_month'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          ) ??
          const {},
    );

    return RecurringPayment(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      recipient: json['recipient'] as String,
      amount: (json['amount'] as num).toDouble(),
      dayOfMonth: (json['day_of_month'] as num).toInt(),
      requiresReminder: json['requires_reminder'] as bool? ?? false,
      reminderDays: (json['reminder_days'] as num?)?.toInt() ?? 0,
      totalPayments: (json['total_payments'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
      completedMonthKeys: completed,
      linkedTransactionIdsByMonth: linkedIds,
    );
  }

  static String monthKeyFor(DateTime month) {
    final mm = month.month.toString().padLeft(2, '0');
    return '${month.year}-$mm';
  }

  static int _daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;
}

class RecurringPaymentOccurrence {
  final RecurringPayment payment;
  final DateTime dueDate;
  final DateTime reminderStartDate;
  final bool isCompleted;
  final String monthKey;

  const RecurringPaymentOccurrence({
    required this.payment,
    required this.dueDate,
    required this.reminderStartDate,
    required this.isCompleted,
    required this.monthKey,
  });

  bool reminderIsActiveOn(DateTime now) {
    if (isCompleted || !payment.requiresReminder) return false;
    final today = DateTime(now.year, now.month, now.day);
    final reminderStart = DateTime(
      reminderStartDate.year,
      reminderStartDate.month,
      reminderStartDate.day,
    );
    final monthEnd = DateTime(dueDate.year, dueDate.month + 1, 0);
    return !today.isBefore(reminderStart) && !today.isAfter(monthEnd);
  }
}

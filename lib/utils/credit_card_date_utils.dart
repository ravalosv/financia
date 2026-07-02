class CreditCardPaymentConfig {
  final String? cardId;
  final String cardName;
  final String accountId;
  final int statementDay;
  final int? paymentGraceDays;
  final int? legacyPaymentDay;
  final bool requiresReminder;
  final int reminderDays;

  const CreditCardPaymentConfig({
    required this.cardId,
    required this.cardName,
    required this.accountId,
    required this.statementDay,
    required this.paymentGraceDays,
    required this.legacyPaymentDay,
    required this.requiresReminder,
    required this.reminderDays,
  });

  bool get hasDueConfig => paymentGraceDays != null || legacyPaymentDay != null;
}

class CreditCardDateUtils {
  static DateTime dueDateForPurchase({
    required DateTime purchaseDate,
    required int statementDay,
    int cycleOffset = 0,
    int? paymentGraceDays,
    int? legacyPaymentDay,
  }) {
    final effectiveStatementDay = statementDay.clamp(
      1,
      _daysInMonth(purchaseDate.year, purchaseDate.month),
    );
    final startOffset = purchaseDate.day > effectiveStatementDay ? 1 : 0;
    final statementMonth = DateTime(
      purchaseDate.year,
      purchaseDate.month + startOffset + cycleOffset,
      1,
    );
    final statementDate = statementDateForMonth(
      month: statementMonth,
      statementDay: statementDay,
    );
    return dueDateForStatementDate(
      statementDate: statementDate,
      statementDay: statementDay,
      paymentGraceDays: paymentGraceDays,
      legacyPaymentDay: legacyPaymentDay,
    );
  }

  static DateTime statementDateForMonth({
    required DateTime month,
    required int statementDay,
  }) {
    final safeDay = statementDay.clamp(
      1,
      _daysInMonth(month.year, month.month),
    );
    return DateTime(month.year, month.month, safeDay);
  }

  static DateTime dueDateForStatementDate({
    required DateTime statementDate,
    required int statementDay,
    int? paymentGraceDays,
    int? legacyPaymentDay,
  }) {
    if (paymentGraceDays != null) {
      return _dateOnly(
        statementDate,
      ).add(Duration(days: paymentGraceDays.clamp(0, 120)));
    }

    if (legacyPaymentDay != null) {
      final sameMonth = legacyPaymentDay > statementDay;
      final dueBaseMonth = sameMonth
          ? DateTime(statementDate.year, statementDate.month, 1)
          : DateTime(statementDate.year, statementDate.month + 1, 1);
      final safeDay = legacyPaymentDay.clamp(
        1,
        _daysInMonth(dueBaseMonth.year, dueBaseMonth.month),
      );
      return DateTime(dueBaseMonth.year, dueBaseMonth.month, safeDay);
    }

    return _dateOnly(statementDate);
  }

  static DateTime reminderStartDate({
    required DateTime dueDate,
    required int reminderDays,
  }) {
    return _dateOnly(
      dueDate,
    ).subtract(Duration(days: reminderDays.clamp(0, 31)));
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static int _daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;
}

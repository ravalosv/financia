import 'payment_card_model.dart';

class CreditCardPaymentOccurrence {
  final PaymentCard card;
  final String accountId;
  final String accountName;
  final String currency;
  final DateTime dueDate;
  final DateTime reminderStartDate;
  final double amount;
  final String monthKey;

  const CreditCardPaymentOccurrence({
    required this.card,
    required this.accountId,
    required this.accountName,
    required this.currency,
    required this.dueDate,
    required this.reminderStartDate,
    required this.amount,
    required this.monthKey,
  });

  bool reminderIsActiveOn(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final reminderStart = DateTime(
      reminderStartDate.year,
      reminderStartDate.month,
      reminderStartDate.day,
    );
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return !today.isBefore(reminderStart) && !today.isAfter(due);
  }
}

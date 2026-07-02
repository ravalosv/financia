import 'package:flutter_test/flutter_test.dart';
import 'package:financia/models/recurring_payment_model.dart';

void main() {
  group('RecurringPayment', () {
    test('respeta limite de pagos finitos por mes', () {
      final payment = RecurringPayment(
        id: '1',
        userId: 'u1',
        recipient: 'Luz',
        amount: 500,
        dayOfMonth: 10,
        requiresReminder: true,
        reminderDays: 3,
        totalPayments: 2,
        createdAt: DateTime(2026, 6, 5),
      );

      expect(payment.isScheduledForMonth(DateTime(2026, 6, 1)), isTrue);
      expect(payment.isScheduledForMonth(DateTime(2026, 7, 1)), isTrue);
      expect(payment.isScheduledForMonth(DateTime(2026, 8, 1)), isFalse);
    });

    test('activa recordatorio diario hasta fin de mes si no se completa', () {
      final payment = RecurringPayment(
        id: '1',
        userId: 'u1',
        recipient: 'Internet',
        amount: 300,
        dayOfMonth: 10,
        requiresReminder: true,
        reminderDays: 3,
        createdAt: DateTime(2026, 6, 1),
      );

      final occurrence = RecurringPaymentOccurrence(
        payment: payment,
        dueDate: payment.occurrenceDateForMonth(DateTime(2026, 6, 1)),
        reminderStartDate: payment.reminderStartForMonth(DateTime(2026, 6, 1)),
        isCompleted: false,
        monthKey: RecurringPayment.monthKeyFor(DateTime(2026, 6, 1)),
      );

      expect(occurrence.reminderIsActiveOn(DateTime(2026, 6, 6)), isFalse);
      expect(occurrence.reminderIsActiveOn(DateTime(2026, 6, 7)), isTrue);
      expect(occurrence.reminderIsActiveOn(DateTime(2026, 6, 25)), isTrue);
      expect(occurrence.reminderIsActiveOn(DateTime(2026, 7, 1)), isFalse);
    });
  });
}

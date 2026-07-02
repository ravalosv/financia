import 'package:get/get.dart';
import '../database/database_service.dart';
import '../models/models.dart';
import '../services/local_notification_service.dart';
import '../utils/helpers.dart';
import 'auth_controller.dart';

class RecurringPaymentController extends GetxController {
  final DatabaseService _databaseService = Get.put(DatabaseService());

  var recurringPayments = <RecurringPayment>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadRecurringPayments();
  }

  Future<void> loadRecurringPayments() async {
    try {
      isLoading(true);
      final items = await _databaseService.getAllRecurringPayments();
      items.sort((a, b) => a.dayOfMonth.compareTo(b.dayOfMonth));
      recurringPayments.assignAll(items);
      await refreshReminderNotifications();
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar los pagos recurrentes: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> addRecurringPayment(RecurringPayment payment) async {
    try {
      isLoading(true);
      final item = payment.id.isEmpty
          ? payment.copyWith(id: Helpers.generateId())
          : payment;
      await _databaseService.insertRecurringPayment(item);
      recurringPayments.add(item);
      recurringPayments.sort((a, b) => a.dayOfMonth.compareTo(b.dayOfMonth));
      recurringPayments.refresh();
      await refreshReminderNotifications();
      Get.snackbar('Exito', 'Pago recurrente agregado correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo agregar el pago recurrente: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateRecurringPayment(RecurringPayment payment) async {
    try {
      isLoading(true);
      await _databaseService.updateRecurringPayment(payment);
      final index = recurringPayments.indexWhere(
        (item) => item.id == payment.id,
      );
      if (index != -1) {
        recurringPayments[index] = payment;
        recurringPayments.sort((a, b) => a.dayOfMonth.compareTo(b.dayOfMonth));
        recurringPayments.refresh();
      }
      await refreshReminderNotifications();
      Get.snackbar('Exito', 'Pago recurrente actualizado correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo actualizar el pago recurrente: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> deleteRecurringPayment(String paymentId) async {
    try {
      isLoading(true);
      await _databaseService.deleteRecurringPayment(paymentId);
      recurringPayments.removeWhere((item) => item.id == paymentId);
      await refreshReminderNotifications();
      Get.snackbar('Exito', 'Pago recurrente eliminado correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo eliminar el pago recurrente: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> markOccurrenceCompleted({
    required String paymentId,
    DateTime? month,
  }) async {
    final targetMonth = month ?? DateTime.now();
    final payment = recurringPayments.firstWhereOrNull(
      (item) => item.id == paymentId,
    );
    if (payment == null) return;

    final updated = payment.markCompletedForMonth(targetMonth);
    await updateRecurringPayment(updated);
  }

  Future<void> markOccurrencePending({
    required String paymentId,
    DateTime? month,
  }) async {
    final targetMonth = month ?? DateTime.now();
    final payment = recurringPayments.firstWhereOrNull(
      (item) => item.id == paymentId,
    );
    if (payment == null) return;

    final updated = payment.unmarkCompletedForMonth(targetMonth);
    await updateRecurringPayment(updated);
  }

  Future<void> linkTransactionToOccurrence({
    required String paymentId,
    required DateTime month,
    required String transactionId,
  }) async {
    final payment = recurringPayments.firstWhereOrNull(
      (item) => item.id == paymentId,
    );
    if (payment == null) return;

    final updated = payment.linkTransactionForMonth(month, transactionId);
    await updateRecurringPayment(updated);
  }

  double getProjectedExpenseForMonth(DateTime month) {
    return recurringPayments.fold<double>(0.0, (sum, payment) {
      if (!payment.isScheduledForMonth(month)) return sum;
      return sum + payment.amount;
    });
  }

  List<RecurringPaymentOccurrence> getUpcomingPayments({
    int days = 30,
    bool includeCompleted = false,
    bool includeOverdue = false,
    DateTime? from,
  }) {
    final now = _dateOnly(from ?? DateTime.now());
    final horizon = now.add(Duration(days: days));
    final occurrences = <RecurringPaymentOccurrence>[];

    for (final payment in recurringPayments) {
      final start = includeOverdue
          ? DateTime(payment.createdAt.year, payment.createdAt.month, 1)
          : now;

      for (final month in _monthsInRange(start, horizon)) {
        if (!payment.isScheduledForMonth(month)) continue;
        final occurrence = _buildOccurrence(payment, month);
        if ((!includeOverdue && occurrence.dueDate.isBefore(now)) ||
            occurrence.dueDate.isAfter(horizon)) {
          continue;
        }
        if (!includeCompleted && occurrence.isCompleted) continue;
        occurrences.add(occurrence);
      }
    }

    occurrences.sort((a, b) {
      final aOverdue = a.dueDate.isBefore(now);
      final bOverdue = b.dueDate.isBefore(now);

      if (aOverdue != bOverdue) {
        return aOverdue ? -1 : 1;
      }

      if (aOverdue && bOverdue) {
        return b.dueDate.compareTo(a.dueDate);
      }

      return a.dueDate.compareTo(b.dueDate);
    });
    return occurrences;
  }

  List<RecurringPaymentOccurrence> getActiveReminderOccurrences({
    DateTime? now,
  }) {
    final current = _dateOnly(now ?? DateTime.now());
    final occurrences = <RecurringPaymentOccurrence>[];

    for (final payment in recurringPayments) {
      for (final month in _monthsInRange(
        current.subtract(const Duration(days: 31)),
        current.add(const Duration(days: 31)),
      )) {
        if (!payment.isScheduledForMonth(month)) continue;
        final occurrence = _buildOccurrence(payment, month);
        if (occurrence.reminderIsActiveOn(current)) {
          occurrences.add(occurrence);
        }
      }
    }

    occurrences.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return occurrences;
  }

  Future<void> refreshReminderNotifications() async {
    final now = _dateOnly(DateTime.now());
    final horizon = now.add(const Duration(days: 45));
    final reminders = <ScheduledLocalReminder>[];
    final auth = Get.find<AuthController>();

    for (final payment in recurringPayments) {
      if (!payment.requiresReminder) continue;

      for (final month in _monthsInRange(now, horizon)) {
        if (!payment.isScheduledForMonth(month)) continue;
        final occurrence = _buildOccurrence(payment, month);
        if (occurrence.isCompleted) continue;

        final reminderStart = _dateOnly(occurrence.reminderStartDate);
        final reminderEnd = _minDate(
          horizon,
          DateTime(occurrence.dueDate.year, occurrence.dueDate.month + 1, 0),
        );
        var day = _maxDate(now, reminderStart);

        while (!day.isAfter(reminderEnd)) {
          reminders.add(
            ScheduledLocalReminder(
              id: _notificationIdFor(payment.id, occurrence.monthKey, day),
              title: 'Recordatorio de pago',
              body:
                  'Pagar ${payment.recipient} por ${Helpers.formatCurrency(payment.amount, auth.currentUserCurrency)}',
              when: DateTime(day.year, day.month, day.day, 9),
            ),
          );
          day = day.add(const Duration(days: 1));
        }
      }
    }

    reminders.sort((a, b) => a.when.compareTo(b.when));
    await LocalNotificationService.scheduleRecurringReminders(
      reminders.take(60).toList(),
    );
  }

  RecurringPaymentOccurrence _buildOccurrence(
    RecurringPayment payment,
    DateTime month,
  ) {
    final dueDate = payment.occurrenceDateForMonth(month);
    return RecurringPaymentOccurrence(
      payment: payment,
      dueDate: dueDate,
      reminderStartDate: payment.reminderStartForMonth(month),
      isCompleted: payment.isCompletedForMonth(month),
      monthKey: RecurringPayment.monthKeyFor(month),
    );
  }

  List<DateTime> _monthsInRange(DateTime start, DateTime end) {
    final months = <DateTime>[];
    var cursor = DateTime(start.year, start.month, 1);
    final last = DateTime(end.year, end.month, 1);

    while (!cursor.isAfter(last)) {
      months.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }

    return months;
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _maxDate(DateTime a, DateTime b) => a.isAfter(b) ? a : b;

  DateTime _minDate(DateTime a, DateTime b) => a.isBefore(b) ? a : b;

  int _notificationIdFor(String paymentId, String monthKey, DateTime day) {
    final key = '$paymentId|$monthKey|${day.toIso8601String()}';
    return key.codeUnits.fold<int>(
      17,
      (hash, item) => ((hash * 31) + item) & 0x7fffffff,
    );
  }
}

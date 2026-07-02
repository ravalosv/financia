import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/controllers.dart';
import '../models/models.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';

class RecurringPaymentsScreen extends StatelessWidget {
  const RecurringPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recurring = Get.find<RecurringPaymentController>();
    final auth = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagos recurrentes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Agregar pago recurrente',
            onPressed: () =>
                _openForm(context, auth: auth, recurring: recurring),
          ),
        ],
      ),
      body: Obx(() {
        if (recurring.isLoading.value && recurring.recurringPayments.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (recurring.recurringPayments.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.autorenew, size: 56),
                  const SizedBox(height: 12),
                  Text(
                    'Sin pagos recurrentes',
                    style: AppTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Agrega pagos domiciliados o compromisos mensuales para ver recordatorios y próximos vencimientos.',
                    style: AppTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: recurring.recurringPayments.length,
          separatorBuilder: (_, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final payment = recurring.recurringPayments[index];
            final currentMonth = DateTime.now();
            final isCurrentMonthScheduled = payment.isScheduledForMonth(
              currentMonth,
            );
            final isCompletedThisMonth = payment.isCompletedForMonth(
              currentMonth,
            );
            final nextOccurrence = _findNextOccurrence(payment);

            return Container(
              decoration: AppTheme.cardDecoration,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              payment.recipient,
                              style: AppTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              Helpers.formatCurrency(
                                payment.amount,
                                auth.currentUserCurrency,
                              ),
                              style: AppTheme.titleSmall.copyWith(
                                color: AppTheme.errorColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await _openForm(
                              context,
                              auth: auth,
                              recurring: recurring,
                              payment: payment,
                            );
                            return;
                          }

                          if (value == 'delete') {
                            await recurring.deleteRecurringPayment(payment.id);
                            await Get.find<DashboardController>()
                                .loadDashboardData();
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('Editar')),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Eliminar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Dia de pago: ${payment.dayOfMonth}',
                    style: AppTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    payment.requiresReminder
                        ? 'Recordatorio: ${payment.reminderDays} dias antes'
                        : 'Recordatorio: no',
                    style: AppTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    payment.totalPayments == null
                        ? 'Cantidad de pagos: indefinido'
                        : 'Cantidad de pagos: ${payment.totalPayments}',
                    style: AppTheme.bodyMedium,
                  ),
                  if (nextOccurrence != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Proximo pago: ${_formatDate(nextOccurrence.dueDate)}',
                      style: AppTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (isCurrentMonthScheduled)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            isCompletedThisMonth
                                ? 'Mes actual completado'
                                : 'Pendiente mes actual',
                          ),
                          backgroundColor: isCompletedThisMonth
                              ? AppTheme.successColor.withValues(alpha: 0.15)
                              : AppTheme.warningColor.withValues(alpha: 0.15),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            if (isCompletedThisMonth) {
                              await recurring.markOccurrencePending(
                                paymentId: payment.id,
                              );
                            } else {
                              await Get.toNamed(
                                AppRoutes.transactionList,
                                arguments: {
                                  'recurringPaymentPrefill': {
                                    'paymentId': payment.id,
                                    'recipient': payment.recipient,
                                    'amount': payment.amount,
                                    'dueDate': DateTime(
                                      currentMonth.year,
                                      currentMonth.month,
                                      payment
                                          .occurrenceDateForMonth(currentMonth)
                                          .day,
                                    ).toIso8601String(),
                                    'description': payment.recipient,
                                    'type': 'expense',
                                  },
                                },
                              );
                            }
                            await Get.find<DashboardController>()
                                .loadDashboardData();
                          },
                          icon: Icon(
                            isCompletedThisMonth
                                ? Icons.undo
                                : Icons.check_circle_outline,
                          ),
                          label: Text(
                            isCompletedThisMonth
                                ? 'Marcar pendiente'
                                : 'Registrar pago',
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, auth: auth, recurring: recurring),
        child: const Icon(Icons.add),
      ),
    );
  }

  RecurringPaymentOccurrence? _findNextOccurrence(RecurringPayment payment) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var i = 0; i < 24; i++) {
      final month = DateTime(today.year, today.month + i, 1);
      if (!payment.isScheduledForMonth(month)) continue;
      final dueDate = payment.occurrenceDateForMonth(month);
      if (!dueDate.isBefore(today)) {
        return RecurringPaymentOccurrence(
          payment: payment,
          dueDate: dueDate,
          reminderStartDate: payment.reminderStartForMonth(month),
          isCompleted: payment.isCompletedForMonth(month),
          monthKey: RecurringPayment.monthKeyFor(month),
        );
      }
    }

    return null;
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd/$mm/${date.year}';
  }

  Future<void> _openForm(
    BuildContext context, {
    required AuthController auth,
    required RecurringPaymentController recurring,
    RecurringPayment? payment,
  }) async {
    final recipientController = TextEditingController(
      text: payment?.recipient ?? '',
    );
    final amountController = TextEditingController(
      text: payment?.amount.toStringAsFixed(2) ?? '',
    );
    final dayController = TextEditingController(
      text: payment?.dayOfMonth.toString() ?? '',
    );
    final reminderDaysController = TextEditingController(
      text: payment?.reminderDays.toString() ?? '3',
    );
    final totalPaymentsController = TextEditingController(
      text: payment?.totalPayments?.toString() ?? '',
    );

    var requiresReminder = payment?.requiresReminder ?? true;
    var indefinite = payment?.totalPayments == null;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      payment == null
                          ? 'Nuevo pago recurrente'
                          : 'Editar pago recurrente',
                      style: AppTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: recipientController,
                      decoration: const InputDecoration(
                        labelText: 'Destinatario',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Monto a pagar',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dayController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Dia de pago',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Requiere recordatorio'),
                      value: requiresReminder,
                      onChanged: (value) {
                        setModalState(() => requiresReminder = value);
                      },
                    ),
                    if (requiresReminder) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: reminderDaysController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Dias para recordatorio',
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Sin fecha de finalizacion'),
                      value: indefinite,
                      onChanged: (value) {
                        setModalState(() => indefinite = value);
                      },
                    ),
                    if (!indefinite) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: totalPaymentsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cantidad de pagos a realizar',
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final recipient = recipientController.text.trim();
                        final amount =
                            double.tryParse(amountController.text.trim()) ?? 0;
                        final dayOfMonth =
                            int.tryParse(dayController.text.trim()) ?? 0;
                        final reminderDays =
                            int.tryParse(reminderDaysController.text.trim()) ??
                            0;
                        final totalPayments = int.tryParse(
                          totalPaymentsController.text.trim(),
                        );

                        if (recipient.isEmpty ||
                            amount <= 0 ||
                            dayOfMonth < 1 ||
                            dayOfMonth > 31) {
                          Get.snackbar(
                            'Validacion',
                            'Captura destinatario, monto y un dia valido',
                          );
                          return;
                        }

                        if (requiresReminder && reminderDays < 0) {
                          Get.snackbar(
                            'Validacion',
                            'Los dias para recordatorio deben ser 0 o mayores',
                          );
                          return;
                        }

                        if (!indefinite &&
                            (totalPayments == null || totalPayments <= 0)) {
                          Get.snackbar(
                            'Validacion',
                            'Captura una cantidad valida de pagos',
                          );
                          return;
                        }

                        final item = RecurringPayment(
                          id: payment?.id ?? '',
                          userId: payment?.userId ?? auth.currentUserId,
                          recipient: recipient,
                          amount: amount,
                          dayOfMonth: dayOfMonth,
                          requiresReminder: requiresReminder,
                          reminderDays: requiresReminder ? reminderDays : 0,
                          totalPayments: indefinite ? null : totalPayments,
                          createdAt: payment?.createdAt ?? DateTime.now(),
                          isActive: payment?.isActive ?? true,
                          completedMonthKeys:
                              payment?.completedMonthKeys ?? const [],
                        );

                        if (payment == null) {
                          await recurring.addRecurringPayment(item);
                        } else {
                          await recurring.updateRecurringPayment(item);
                        }

                        await Get.find<DashboardController>()
                            .loadDashboardData();

                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

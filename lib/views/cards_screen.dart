import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/account_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/card_controller.dart';
import '../models/payment_card_model.dart';
import '../theme/app_theme.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final accountController = Get.find<AccountController>();
  final cardController = Get.find<CardController>();
  final authController = Get.find<AuthController>();

  bool _isAuthorizing = true;
  bool _hasAccess = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authorizeEntry();
    });
  }

  Future<void> _authorizeEntry() async {
    final allowed = await cardController.authenticateAccess(
      'Autentica para entrar al modulo de tarjetas',
    );
    if (!mounted) return;

    if (!allowed) {
      Get.snackbar(
        'Acceso denegado',
        'No se pudo validar la seguridad del dispositivo',
      );
      Navigator.of(context).maybePop();
      return;
    }

    setState(() {
      _hasAccess = true;
      _isAuthorizing = false;
    });
  }

  Future<void> _openCardForm({PaymentCard? initial}) async {
    Map<String, String?>? sensitive;
    if (initial != null) {
      final allowed = await cardController.authenticateAccess(
        'Confirma tu identidad para editar la tarjeta',
      );
      if (!allowed) {
        Get.snackbar('Acceso denegado', 'No se pudo abrir la edicion segura');
        return;
      }
      sensitive = await cardController.revealSensitiveData(initial);
    }

    final nameController = TextEditingController(text: initial?.name ?? '');
    final numberText = sensitive?['number'] ?? '';
    final numberController = TextEditingController(
      text: _formatCardNumberForDisplay(numberText),
    );
    final cvvController = TextEditingController(text: sensitive?['cvv'] ?? '');
    final pinController = TextEditingController(text: sensitive?['pin'] ?? '');
    final expiryMonthController = TextEditingController(
      text: initial != null
          ? initial.expiryMonth.toString().padLeft(2, '0')
          : '',
    );
    final expiryYearController = TextEditingController(
      text: initial != null
          ? (initial.expiryYear % 100).toString().padLeft(2, '0')
          : '',
    );
    final statementDayController = TextEditingController(
      text: initial?.statementDay?.toString() ?? '',
    );
    final paymentGraceDaysController = TextEditingController(
      text: initial?.paymentGraceDays?.toString() ?? '',
    );
    final paymentReminderDaysController = TextEditingController(
      text: initial?.paymentReminderDays.toString() ?? '3',
    );

    final formKey = GlobalKey<FormState>();
    String cardType = initial?.cardType ?? 'debit';
    String? linkedAccountId = initial?.linkedAccountId;
    bool isVirtual = initial?.isVirtual ?? false;
    bool requiresPaymentReminder = initial?.requiresPaymentReminder ?? true;

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final availableAccountsById = <String, dynamic>{};
            for (final account in accountController.accounts) {
              final matchesType = cardType == 'credit'
                  ? account.type == 'credit'
                  : account.type != 'credit';
              if (!matchesType) continue;
              final linkedCard = cardController.getCardByLinkedAccountId(
                account.id,
              );
              if (linkedCard == null || linkedCard.id == initial?.id) {
                availableAccountsById.putIfAbsent(account.id, () => account);
              }
            }
            final availableAccounts = availableAccountsById.values.toList();
            final effectiveLinkedAccountId =
                linkedAccountId != null &&
                    availableAccounts.any(
                      (account) => account.id == linkedAccountId,
                    )
                ? linkedAccountId
                : null;
            linkedAccountId = effectiveLinkedAccountId;
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        initial == null ? 'Nueva tarjeta' : 'Editar tarjeta',
                        style: AppTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de la tarjeta',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa un nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: cardType,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de tarjeta',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'debit',
                            child: Text('Debito'),
                          ),
                          DropdownMenuItem(
                            value: 'credit',
                            child: Text('Credito'),
                          ),
                        ],
                        onChanged: (value) {
                          setModalState(() {
                            cardType = value ?? 'debit';
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        initialValue: effectiveLinkedAccountId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Cuenta ligada',
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Sin cuenta ligada'),
                          ),
                          ...availableAccounts.map(
                            (account) => DropdownMenuItem<String?>(
                              value: account.id,
                              child: Text(account.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setModalState(() {
                            linkedAccountId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: numberController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(19),
                          const CardNumberInputFormatter(),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Número de tarjeta',
                        ),
                        validator: (value) {
                          final digits = _digitsOnly(value ?? '');
                          if (digits.length != 16) {
                            return 'Debe tener 16 digitos';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: expiryMonthController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Mes venc.',
                              ),
                              validator: (value) {
                                final month = int.tryParse(value ?? '');
                                if (month == null || month < 1 || month > 12) {
                                  return 'Mes invalido';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: expiryYearController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(2),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Año venc. (YY)',
                              ),
                              validator: (value) {
                                final yearText = _digitsOnly(value ?? '');
                                if (yearText.length != 2) {
                                  return 'Usa 2 digitos';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: cvvController,
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'CVV',
                              ),
                              validator: (value) {
                                final digits = _digitsOnly(value ?? '');
                                if (digits.length < 3 || digits.length > 4) {
                                  return 'CVV invalido';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Tarjeta virtual'),
                        subtitle: Text(
                          isVirtual ? 'Virtual' : 'Fisica',
                          style: AppTheme.bodyMedium,
                        ),
                        value: isVirtual,
                        onChanged: (value) {
                          setModalState(() {
                            isVirtual = value;
                            if (isVirtual) {
                              pinController.clear();
                            }
                          });
                        },
                      ),
                      if (!isVirtual) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: pinController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'NIP',
                            helperText: 'Opcional',
                          ),
                          validator: (value) {
                            if (isVirtual) return null;
                            final digits = _digitsOnly(value ?? '');
                            if (digits.isEmpty) return null;
                            if (digits.length < 4) {
                              return 'Ingresa un NIP valido';
                            }
                            return null;
                          },
                        ),
                      ],
                      if (cardType == 'credit') ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: statementDayController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Día de corte',
                                  helperText: 'Día del mes',
                                ),
                                validator: (value) {
                                  final day = int.tryParse(value ?? '');
                                  if (cardType == 'credit' &&
                                      (day == null || day < 1 || day > 31)) {
                                    return 'Dia invalido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: paymentGraceDaysController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Días para pagar',
                                  helperText: 'Después de fecha de corte',
                                ),
                                validator: (value) {
                                  final days = int.tryParse(value ?? '');
                                  if (cardType == 'credit' &&
                                      (days == null ||
                                          days < 0 ||
                                          days > 120)) {
                                    return 'Valor invalido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Alerta antes del vencimiento'),
                          value: requiresPaymentReminder,
                          onChanged: (value) {
                            setModalState(() {
                              requiresPaymentReminder = value;
                            });
                          },
                        ),
                        if (requiresPaymentReminder)
                          TextFormField(
                            controller: paymentReminderDaysController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Días de alerta',
                              helperText: 'Antes de fecha límite',
                            ),
                            validator: (value) {
                              final days = int.tryParse(value ?? '');
                              if (cardType == 'credit' &&
                                  requiresPaymentReminder &&
                                  (days == null || days < 0 || days > 31)) {
                                return 'Valor invalido';
                              }
                              return null;
                            },
                          ),
                      ],
                      const SizedBox(height: 16),
                      Obx(
                        () => ElevatedButton(
                          onPressed: cardController.isLoading.value
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }

                                  final month = int.parse(
                                    expiryMonthController.text.trim(),
                                  );
                                  final year =
                                      int.parse(
                                        expiryYearController.text.trim(),
                                      ) +
                                      2000;
                                  final statementDay = cardType == 'credit'
                                      ? int.parse(
                                          statementDayController.text.trim(),
                                        )
                                      : null;
                                  final paymentGraceDays = cardType == 'credit'
                                      ? int.parse(
                                          paymentGraceDaysController.text
                                              .trim(),
                                        )
                                      : null;
                                  final paymentReminderDays =
                                      cardType == 'credit'
                                      ? (requiresPaymentReminder
                                            ? int.parse(
                                                paymentReminderDaysController
                                                    .text
                                                    .trim(),
                                              )
                                            : 0)
                                      : 0;
                                  final effectivePaymentReminder =
                                      cardType == 'credit' &&
                                      requiresPaymentReminder;

                                  if (initial == null) {
                                    await cardController.createCard(
                                      userId: authController.currentUserId,
                                      name: nameController.text.trim(),
                                      cardType: cardType,
                                      cardNumber: numberController.text.trim(),
                                      expiryMonth: month,
                                      expiryYear: year,
                                      cvv: cvvController.text.trim(),
                                      isVirtual: isVirtual,
                                      pin: isVirtual
                                          ? null
                                          : pinController.text.trim(),
                                      statementDay: statementDay,
                                      paymentGraceDays: paymentGraceDays,
                                      requiresPaymentReminder:
                                          effectivePaymentReminder,
                                      paymentReminderDays: paymentReminderDays,
                                      linkedAccountId: linkedAccountId,
                                    );
                                  } else {
                                    await cardController.updateCard(
                                      existing: initial,
                                      name: nameController.text.trim(),
                                      cardType: cardType,
                                      cardNumber: numberController.text.trim(),
                                      expiryMonth: month,
                                      expiryYear: year,
                                      cvv: cvvController.text.trim(),
                                      isVirtual: isVirtual,
                                      pin: isVirtual
                                          ? null
                                          : pinController.text.trim(),
                                      statementDay: statementDay,
                                      paymentGraceDays: paymentGraceDays,
                                      requiresPaymentReminder:
                                          effectivePaymentReminder,
                                      paymentReminderDays: paymentReminderDays,
                                      linkedAccountId: linkedAccountId,
                                    );
                                  }

                                  if (ctx.mounted) {
                                    Navigator.of(ctx).pop();
                                  }
                                },
                          child: Text(
                            initial == null ? 'Guardar' : 'Actualizar',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openCardDetail(PaymentCard card) async {
    String? revealedNumber;
    String? revealedCvv;
    String? revealedPin;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            Future<void> revealField(String field) async {
              final allowed = await cardController.authenticateAccess(
                'Confirma tu identidad para ver informacion sensible',
              );
              if (!allowed) {
                Get.snackbar(
                  'Acceso denegado',
                  'No se pudo mostrar el dato sensible',
                );
                return;
              }

              final data = await cardController.revealSensitiveData(card);
              setModalState(() {
                if (field == 'number') {
                  revealedNumber = _formatCardNumberForDisplay(
                    data['number'] ?? '',
                  );
                }
                if (field == 'cvv') {
                  revealedCvv = data['cvv'];
                }
                if (field == 'pin') {
                  revealedPin = data['pin'];
                }
              });
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          card.cardType == 'credit'
                              ? Icons.credit_card
                              : Icons.payments_outlined,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(card.name, style: AppTheme.titleMedium),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) async {
                            Navigator.of(ctx).pop();
                            if (value == 'edit') {
                              await _openCardForm(initial: card);
                            }
                            if (value == 'delete') {
                              final confirm = await _confirmDelete(card);
                              if (confirm) {
                                await cardController.deleteCard(card.id);
                              }
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Editar')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Eliminar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      label: 'Tipo',
                      value: card.cardType == 'credit' ? 'Credito' : 'Debito',
                    ),
                    _DetailRow(
                      label: 'Presentacion',
                      value: card.isVirtual ? 'Virtual' : 'Fisica',
                    ),
                    _DetailRow(
                      label: 'Cuenta ligada',
                      value:
                          card.linkedAccountId != null &&
                              card.linkedAccountId!.isNotEmpty
                          ? (accountController
                                    .getAccountById(card.linkedAccountId!)
                                    ?.name ??
                                'Cuenta no encontrada')
                          : 'Sin cuenta ligada',
                    ),
                    _DetailRow(label: 'Vencimiento', value: card.expiryLabel),
                    _SecretRow(
                      label: 'Número',
                      value: revealedNumber ?? card.maskedNumber,
                      actionLabel: revealedNumber == null
                          ? 'Ver completo'
                          : 'Visible',
                      onPressed: revealedNumber == null
                          ? () => revealField('number')
                          : null,
                    ),
                    _SecretRow(
                      label: 'CVV',
                      value: revealedCvv ?? '***',
                      actionLabel: revealedCvv == null ? 'Ver CVV' : 'Visible',
                      onPressed: revealedCvv == null
                          ? () => revealField('cvv')
                          : null,
                    ),
                    if (!card.isVirtual &&
                        card.encryptedPin != null &&
                        card.encryptedPin!.isNotEmpty)
                      _SecretRow(
                        label: 'NIP',
                        value: revealedPin ?? '****',
                        actionLabel: revealedPin == null
                            ? 'Ver NIP'
                            : 'Visible',
                        onPressed: revealedPin == null
                            ? () => revealField('pin')
                            : null,
                      ),
                    if (!card.isVirtual &&
                        (card.encryptedPin == null ||
                            card.encryptedPin!.isEmpty))
                      const _DetailRow(label: 'NIP', value: 'No configurado'),
                    if (card.cardType == 'credit') ...[
                      _DetailRow(
                        label: 'Día de corte',
                        value: 'Día ${card.statementDay ?? '-'}',
                      ),
                      _DetailRow(
                        label: 'Días para pagar',
                        value: card.paymentGraceDays != null
                            ? '${card.paymentGraceDays} día(s)'
                            : card.paymentDay != null
                            ? 'Legado: día ${card.paymentDay}'
                            : '-',
                      ),
                      _DetailRow(
                        label: 'Alerta',
                        value: card.requiresPaymentReminder
                            ? '${card.paymentReminderDays} día(s) antes'
                            : 'No',
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'CVV y NIP permanecen ocultos hasta reautenticar.',
                      style: AppTheme.bodySmall,
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

  Future<bool> _confirmDelete(PaymentCard card) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Eliminar tarjeta'),
          content: Text('¿Eliminar la tarjeta "${card.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  String _digitsOnly(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String _formatCardNumberForDisplay(String value) {
    final digits = _digitsOnly(value);
    final truncated = digits.length > 16 ? digits.substring(0, 16) : digits;
    final groups = <String>[];
    for (int i = 0; i < truncated.length; i += 4) {
      final end = (i + 4) > truncated.length ? truncated.length : (i + 4);
      groups.add(truncated.substring(i, end));
    }
    return groups.join('-');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tarjetas')),
      floatingActionButton: _hasAccess
          ? FloatingActionButton(
              onPressed: () => _openCardForm(),
              child: const Icon(Icons.add),
            )
          : null,
      body: _isAuthorizing
          ? const Center(child: CircularProgressIndicator())
          : !_hasAccess
          ? Center(
              child: Text(
                'No se pudo validar el acceso seguro',
                style: AppTheme.bodyMedium,
              ),
            )
          : Obx(() {
              if (cardController.isLoading.value &&
                  cardController.cards.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (cardController.cards.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Sin tarjetas guardadas',
                      style: AppTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: cardController.cards.length,
                separatorBuilder: (_, index) => const SizedBox(height: 12),
                itemBuilder: (ctx, index) {
                  final card = cardController.cards[index];
                  return InkWell(
                    onTap: () => _openCardDetail(card),
                    borderRadius: BorderRadius.circular(
                      AppTheme.cardBorderRadius,
                    ),
                    child: Container(
                      decoration: AppTheme.cardDecoration,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                card.cardType == 'credit'
                                    ? Icons.credit_card
                                    : Icons.payments_outlined,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  card.name,
                                  style: AppTheme.titleSmall,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  card.cardType == 'credit'
                                      ? 'Credito'
                                      : 'Debito',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(card.maskedNumber, style: AppTheme.bodyLarge),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Vence ${card.expiryLabel}',
                                  style: AppTheme.bodyMedium,
                                ),
                              ),
                              Text(
                                card.isVirtual ? 'Virtual' : 'Fisica',
                                style: AppTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            card.linkedAccountId != null &&
                                    card.linkedAccountId!.isNotEmpty
                                ? 'Cuenta: ${accountController.getAccountById(card.linkedAccountId!)?.name ?? 'No encontrada'}'
                                : 'Sin cuenta ligada',
                            style: AppTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label, style: AppTheme.bodyMedium)),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.primaryText),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecretRow extends StatelessWidget {
  final String label;
  final String value;
  final String actionLabel;
  final VoidCallback? onPressed;

  const _SecretRow({
    required this.label,
    required this.value,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: AppTheme.bodyMedium)),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.primaryText),
            ),
          ),
          TextButton(onPressed: onPressed, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class CardNumberInputFormatter extends TextInputFormatter {
  const CardNumberInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final truncated = digits.length > 16 ? digits.substring(0, 16) : digits;

    final groups = <String>[];
    for (int i = 0; i < truncated.length; i += 4) {
      final end = (i + 4) > truncated.length ? truncated.length : (i + 4);
      groups.add(truncated.substring(i, end));
    }
    final formatted = groups.join('-');

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/transaction_controller.dart';
import '../controllers/account_controller.dart';
import '../controllers/category_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/card_controller.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final auth = Get.find<AuthController>();
  final tx = Get.find<TransactionController>();
  final accounts = Get.find<AccountController>();
  final categories = Get.find<CategoryController>();
  final cards = Get.find<CardController>();

  String? _filterAccount;
  String? _filterCategory;
  String _filterType = 'all';
  DateTime _filterStart = DateTime.now().subtract(const Duration(days: 30));
  DateTime _filterEnd = DateTime.now();

  String _formatShortDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = (d.year % 100).toString().padLeft(2, '0');
    return '$dd/$mm/$yy';
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _addMonthsKeepingDay(DateTime date, int monthsToAdd) {
    final totalMonths = (date.year * 12) + date.month - 1 + monthsToAdd;
    final year = totalMonths ~/ 12;
    final month = (totalMonths % 12) + 1;
    final day = date.day.clamp(1, _daysInMonth(year, month));
    return DateTime(
      year,
      month,
      day,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  @override
  void initState() {
    super.initState();
    _applyFilters();
  }

  void _applyFilters() {
    if (_filterAccount != null) tx.setAccountFilter(_filterAccount!);
    if (_filterCategory != null) tx.setCategoryFilter(_filterCategory!);
    tx.setTypeFilter(_filterType);
    tx.setDateFilter(_filterStart, _filterEnd);
  }

  bool _isCreditAccount(String? accountId) =>
      accountId != null && accounts.getAccountById(accountId)?.type == 'credit';

  int _resolveCreditCutoffDay(String accountId) {
    final linkedCard = cards.getCardByLinkedAccountId(accountId);
    final cardCutoffDay = (linkedCard?.cardType == 'credit')
        ? linkedCard?.statementDay
        : null;
    final accountCutoffDay = accounts
        .getAccountById(accountId)
        ?.creditCutoffDay;
    return (cardCutoffDay ?? accountCutoffDay ?? 31).clamp(1, 31);
  }

  Future<String?> _confirmDelete(Transaction transaction) async {
    final isTransfer =
        transaction.categoryId == 'transfer_in' ||
        transaction.categoryId == 'transfer_out';
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Confirmación'),
          content: Text(
            isTransfer
                ? 'Se eliminarán ambas transacciones del traspaso. ¿Deseas continuar?'
                : transaction.isInstallmentPlan
                ? 'Esta mensualidad pertenece a un plan MSI. ¿Qué deseas borrar?'
                : '¿Deseas eliminar esta transacción?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            if (transaction.isInstallmentPlan && !isTransfer)
              TextButton(
                onPressed: () => Navigator.of(ctx).pop('plan'),
                child: const Text('Cancelar plan MSI'),
              ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('single'),
              child: Text(isTransfer ? 'Eliminar' : 'Solo este mes'),
            ),
          ],
        );
      },
    );
    return result;
  }

  Future<void> _pickDateRange() async {
    final start = await showDatePicker(
      context: context,
      initialDate: _filterStart,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (start == null) return;
    if (!mounted) return;
    final effectiveEnd = _filterEnd.isBefore(start) ? start : _filterEnd;
    final end = await showDatePicker(
      context: context,
      initialDate: effectiveEnd,
      firstDate: start,
      lastDate: DateTime(2100),
    );
    if (end == null) return;
    setState(() {
      _filterStart = start;
      _filterEnd = end;
    });
    _applyFilters();
  }

  Future<void> _openTransactionForm({Transaction? initial}) async {
    final amountController = TextEditingController(
      text: initial != null ? initial.amount.toStringAsFixed(2) : '',
    );
    final descriptionController = TextEditingController(
      text: initial?.description ?? '',
    );
    final tcController = TextEditingController(
      text: initial != null ? initial.exchangeRate.toStringAsFixed(6) : '1.0',
    );
    final msiMonthsController = TextEditingController(
      text: (initial?.installmentCount ?? 3).toString(),
    );
    String type = initial?.type ?? 'expense';
    String? accountId = initial?.accountId ?? _filterAccount;
    String? categoryId = initial?.categoryId ?? _filterCategory;
    DateTime purchaseDate =
        initial?.purchaseDate ?? initial?.transactionDate ?? DateTime.now();
    bool isMsi = initial?.isInstallmentPlan ?? false;
    int msiMonths = initial?.installmentCount ?? 3;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      initial == null
                          ? 'Nueva transacción'
                          : 'Editar transacción',
                      style: AppTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Gasto'),
                          selected: type == 'expense',
                          onSelected: (_) =>
                              setModalState(() => type = 'expense'),
                          selectedColor: AppTheme.errorColor.withValues(
                            alpha: 0.12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Ingreso'),
                          selected: type == 'income',
                          onSelected: (_) =>
                              setModalState(() => type = 'income'),
                          selectedColor: AppTheme.successColor.withValues(
                            alpha: 0.12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Monto'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: accountId,
                      items: accounts.accounts
                          .map(
                            (a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(a.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setModalState(() => accountId = v),
                      decoration: const InputDecoration(labelText: 'Cuenta'),
                    ),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (ctx) {
                        final acc = accountId != null
                            ? accounts.getAccountById(accountId!)
                            : null;
                        final base = auth.currentUserCurrency;
                        final needsTc = acc != null && acc.currency != base;
                        if (!needsTc || type == 'transfer') {
                          return const SizedBox.shrink();
                        }
                        return TextField(
                          controller: tcController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Tipo de cambio a $base',
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    if (type == 'expense' &&
                        _isCreditAccount(accountId) &&
                        initial == null) ...[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Compra a Meses Sin Intereses'),
                        value: isMsi,
                        onChanged: (value) =>
                            setModalState(() => isMsi = value),
                      ),
                      if (isMsi)
                        TextField(
                          controller: msiMonthsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Plazo MSI (meses)',
                          ),
                        ),
                      const SizedBox(height: 12),
                    ],
                    DropdownButtonFormField<String>(
                      initialValue: categoryId,
                      items: categories.categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setModalState(() => categoryId = v),
                      decoration: const InputDecoration(labelText: 'Categoría'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: purchaseDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) setModalState(() => purchaseDate = d);
                      },
                      child: Text(
                        '${purchaseDate.year}-${purchaseDate.month.toString().padLeft(2, '0')}-${purchaseDate.day.toString().padLeft(2, '0')}',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final amount =
                            double.tryParse(amountController.text.trim()) ??
                            0.0;
                        final acc = accountId != null
                            ? accounts.getAccountById(accountId!)
                            : null;
                        final base = auth.currentUserCurrency;
                        final needsTc = acc != null && acc.currency != base;
                        final tc = needsTc
                            ? (double.tryParse(tcController.text.trim()) ?? 0.0)
                            : 1.0;
                        final parsedMsiMonths =
                            int.tryParse(msiMonthsController.text.trim()) ?? 0;
                        if (isMsi && parsedMsiMonths <= 1) {
                          Get.snackbar(
                            'Validación',
                            'Ingresa un plazo MSI mayor a 1 mes',
                          );
                          return;
                        }
                        msiMonths = parsedMsiMonths > 1
                            ? parsedMsiMonths
                            : msiMonths;
                        if (amount <= 0 ||
                            (needsTc && tc <= 0) ||
                            accountId == null ||
                            categoryId == null) {
                          Get.snackbar(
                            'Validación',
                            'Completa monto, cuenta y categoría${needsTc ? ' y TC' : ''}',
                          );
                          return;
                        }
                        if (initial == null) {
                          final t = Transaction(
                            id: '',
                            userId: auth.currentUserId,
                            accountId: accountId!,
                            categoryId: categoryId!,
                            amount: amount,
                            type: type,
                            transactionDate: purchaseDate,
                            purchaseDate: purchaseDate,
                            description:
                                descriptionController.text.trim().isEmpty
                                ? null
                                : descriptionController.text.trim(),
                            merchant: null,
                            isRecurring: false,
                            createdAt: DateTime.now(),
                            exchangeRate: tc,
                          );
                          final cutoffDay = _resolveCreditCutoffDay(accountId!);
                          if (isMsi &&
                              type == 'expense' &&
                              _isCreditAccount(accountId)) {
                            await tx.addInstallmentPlan(
                              baseTransaction: t,
                              months: msiMonths,
                              cutoffDay: cutoffDay,
                            );
                          } else if (type == 'expense' &&
                              _isCreditAccount(accountId)) {
                            await tx.addCreditExpenseWithCutoff(
                              purchaseTransaction: t,
                              cutoffDay: cutoffDay,
                            );
                          } else {
                            await tx.addTransaction(t);
                          }
                        } else {
                          final isCreditExpense =
                              type == 'expense' && _isCreditAccount(accountId);
                          final cutoffDayClamped = accountId != null
                              ? _resolveCreditCutoffDay(accountId!)
                              : 31;
                          final transactionDate =
                              isCreditExpense &&
                                  !initial.isInstallmentPlan &&
                                  purchaseDate.day > cutoffDayClamped
                              ? _addMonthsKeepingDay(purchaseDate, 1)
                              : purchaseDate;
                          final updated = initial.copyWith(
                            accountId: accountId,
                            categoryId: categoryId,
                            amount: amount,
                            type: type,
                            transactionDate: transactionDate,
                            purchaseDate: purchaseDate,
                            description:
                                descriptionController.text.trim().isEmpty
                                ? null
                                : descriptionController.text.trim(),
                            exchangeRate: tc,
                          );
                          await tx.updateTransaction(updated);
                        }
                        _applyFilters();
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transacciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openTransactionForm(),
          ),
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            tooltip: 'Traspaso entre cuentas',
            onPressed: _openTransferForm,
          ),
        ],
      ),
      body: Obx(() {
        final list = tx.filteredTransactions;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _filterAccount,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Todas las cuentas'),
                        ),
                        ...accounts.accounts.map(
                          (a) => DropdownMenuItem<String>(
                            value: a.id,
                            child: Text(a.name),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() {
                        _filterAccount = v;
                        if (v == null) tx.setAccountFilter('');
                        _applyFilters();
                      }),
                      decoration: const InputDecoration(labelText: 'Cuenta'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _filterCategory,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Todas las categorías'),
                        ),
                        ...categories.categories.map(
                          (c) => DropdownMenuItem<String>(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() {
                        _filterCategory = v;
                        if (v == null) tx.setCategoryFilter('');
                        _applyFilters();
                      }),
                      decoration: const InputDecoration(labelText: 'Categoría'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Todos'),
                    selected: _filterType == 'all',
                    onSelected: (_) => setState(() {
                      _filterType = 'all';
                      _applyFilters();
                    }),
                  ),
                  ChoiceChip(
                    label: const Text('Ingresos'),
                    selected: _filterType == 'income',
                    onSelected: (_) => setState(() {
                      _filterType = 'income';
                      _applyFilters();
                    }),
                  ),
                  ChoiceChip(
                    label: const Text('Egresos'),
                    selected: _filterType == 'expense',
                    onSelected: (_) => setState(() {
                      _filterType = 'expense';
                      _applyFilters();
                    }),
                  ),
                  OutlinedButton(
                    onPressed: _pickDateRange,
                    child: Text(
                      '${_formatShortDate(_filterStart)}  →  ${_formatShortDate(_filterEnd)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (list.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.cardDecoration,
                  child: Text(
                    'Sin transacciones',
                    style: AppTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (ctx, i) {
                    final t = list[i];
                    return Dismissible(
                      key: Key('tx_${t.id}'),
                      background: Container(
                        color: AppTheme.successColor.withValues(alpha: 0.12),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: const [
                            Icon(Icons.edit, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      secondaryBackground: Container(
                        color: AppTheme.errorColor.withValues(alpha: 0.12),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: const [
                            Text('Eliminar'),
                            SizedBox(width: 8),
                            Icon(Icons.delete, color: Colors.red),
                          ],
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        final isTransfer =
                            t.categoryId == 'transfer_in' ||
                            t.categoryId == 'transfer_out';
                        if (direction == DismissDirection.startToEnd) {
                          if (isTransfer) return false;
                          await _openTransactionForm(initial: t);
                          return false;
                        } else {
                          final action = await _confirmDelete(t);
                          if (action == null) return false;
                          if (isTransfer) {
                            await tx.deleteTransferPair(t);
                          } else if (action == 'plan' && t.isInstallmentPlan) {
                            await tx.deleteInstallmentPlan(
                              t.installmentPlanId!,
                            );
                          } else {
                            await tx.deleteTransaction(t.id);
                          }
                          return true;
                        }
                      },
                      child: ListTile(
                        leading: Icon(
                          t.type == 'income'
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: t.type == 'income'
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                        ),
                        title: Text(
                          Helpers.formatCurrency(
                            t.amount,
                            auth.currentUserCurrency,
                          ),
                        ),
                        subtitle: Text(() {
                          final parts = <String>[
                            t.categoryId,
                            _formatShortDate(t.transactionDate.toLocal()),
                          ];
                          final realPurchase =
                              (t.purchaseDate ?? t.transactionDate).toLocal();
                          if (!_sameDay(
                            realPurchase,
                            t.transactionDate.toLocal(),
                          )) {
                            parts.add(
                              'Compra ${_formatShortDate(realPurchase)}',
                            );
                          }
                          if (t.installmentLabel != null) {
                            parts.add(t.installmentLabel!);
                          }
                          if (t.description != null) {
                            parts.add(t.description!);
                          }
                          return parts.join(' • ');
                        }()),
                        onTap:
                            (t.categoryId == 'transfer_in' ||
                                t.categoryId == 'transfer_out')
                            ? null
                            : () => _openTransactionForm(initial: t),
                      ),
                    );
                  },
                  separatorBuilder: (_, index) => const Divider(height: 1),
                  itemCount: list.length,
                ),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _openTransferForm() async {
    String? fromAccountId;
    String? toAccountId;
    final amountController = TextEditingController();
    final amountToController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime date = DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Traspaso entre cuentas', style: AppTheme.titleMedium),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: fromAccountId,
                      items: accounts.accounts
                          .map(
                            (a) => DropdownMenuItem<String>(
                              value: a.id,
                              child: Text(a.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setModalState(() => fromAccountId = v),
                      decoration: const InputDecoration(
                        labelText: 'Desde la cuenta',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: toAccountId,
                      items: accounts.accounts
                          .map(
                            (a) => DropdownMenuItem<String>(
                              value: a.id,
                              child: Text(a.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setModalState(() => toAccountId = v),
                      decoration: const InputDecoration(
                        labelText: 'Hacia la cuenta',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (ctx) {
                        final from = fromAccountId != null
                            ? accounts.getAccountById(fromAccountId!)
                            : null;
                        final to = toAccountId != null
                            ? accounts.getAccountById(toAccountId!)
                            : null;
                        final differentCurrency =
                            from != null &&
                            to != null &&
                            from.currency != to.currency;
                        if (differentCurrency) {
                          return Column(
                            children: [
                              TextField(
                                controller: amountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: InputDecoration(
                                  labelText:
                                      'Monto en origen (${from.currency})',
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: amountToController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: InputDecoration(
                                  labelText:
                                      'Monto en destino (${to.currency})',
                                ),
                              ),
                            ],
                          );
                        }
                        return TextField(
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(labelText: 'Monto'),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción (opcional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) setModalState(() => date = d);
                      },
                      child: Text(
                        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final from = fromAccountId != null
                            ? accounts.getAccountById(fromAccountId!)
                            : null;
                        final to = toAccountId != null
                            ? accounts.getAccountById(toAccountId!)
                            : null;
                        final differentCurrency =
                            from != null &&
                            to != null &&
                            from.currency != to.currency;
                        final amountFrom =
                            double.tryParse(amountController.text.trim()) ??
                            0.0;
                        final amountTo = differentCurrency
                            ? (double.tryParse(
                                    amountToController.text.trim(),
                                  ) ??
                                  0.0)
                            : amountFrom;
                        if (amountFrom <= 0 ||
                            amountTo <= 0 ||
                            fromAccountId == null ||
                            toAccountId == null) {
                          Get.snackbar(
                            'Validación',
                            'Completa monto, cuenta origen y cuenta destino',
                          );
                          return;
                        }
                        if (fromAccountId == toAccountId) {
                          Get.snackbar(
                            'Validación',
                            'Selecciona cuentas distintas',
                          );
                          return;
                        }
                        await accounts.transferMoney(
                          fromAccountId: fromAccountId!,
                          toAccountId: toAccountId!,
                          amountFrom: amountFrom,
                          amountTo: amountTo,
                          description: descriptionController.text.trim(),
                          date: date,
                        );
                        _applyFilters();
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                        }
                      },
                      child: const Text('Transferir'),
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

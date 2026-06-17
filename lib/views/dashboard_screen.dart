import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/transaction_controller.dart';
import '../controllers/account_controller.dart';
import '../controllers/category_controller.dart';
import '../controllers/card_controller.dart';
import '../database/database_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';
import 'package:fl_chart/fl_chart.dart';
import '../routes/app_routes.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final auth = Get.find<AuthController>();
  final dashboard = Get.find<DashboardController>();
  final transactions = Get.find<TransactionController>();
  final accounts = Get.find<AccountController>();
  final categories = Get.find<CategoryController>();
  final cards = Get.find<CardController>();

  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  Color _randomColorForKey(String key) {
    final hash = key.codeUnits.fold<int>(
      0,
      (acc, c) => (acc * 31 + c) & 0xFFFFFFFF,
    );
    final hue = (hash % 360).toDouble();
    final saturation = 0.7;
    final lightness = 0.55;
    return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
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

  Future<void> _openQuickEntry() async {
    String type = 'expense';
    String? accountId;
    String? categoryId;
    String? fromAccountId;
    String? toAccountId;
    DateTime date = DateTime.now();
    bool isMsi = false;
    int msiMonths = 3;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final fromAmountController = TextEditingController();
            final toAmountController = TextEditingController();
            final tcController = TextEditingController(text: '1.0');
            final msiMonthsController = TextEditingController(
              text: msiMonths.toString(),
            );
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
                    Text('Registro rápido', style: AppTheme.titleMedium),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Gasto'),
                          selected: type == 'expense',
                          onSelected: (_) => setModalState(() {
                            type = 'expense';
                            categoryId = null;
                            fromAccountId = null;
                            toAccountId = null;
                            isMsi = false;
                          }),
                          selectedColor: AppTheme.errorColor.withValues(
                            alpha: 0.12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Ingreso'),
                          selected: type == 'income',
                          onSelected: (_) => setModalState(() {
                            type = 'income';
                            categoryId = null;
                            fromAccountId = null;
                            toAccountId = null;
                            isMsi = false;
                          }),
                          selectedColor: AppTheme.successColor.withValues(
                            alpha: 0.12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Traspaso'),
                          selected: type == 'transfer',
                          onSelected: (_) => setModalState(() {
                            type = 'transfer';
                            categoryId = null;
                            accountId = null;
                            isMsi = false;
                          }),
                          selectedColor: AppTheme.primaryColor.withValues(
                            alpha: 0.12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (type != 'transfer')
                      TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Monto'),
                      ),

                    const SizedBox(height: 12),
                    if (type != 'transfer')
                      DropdownButtonFormField<String>(
                        initialValue: accountId,
                        items: accounts.accounts
                            .map(
                              (a) => DropdownMenuItem<String>(
                                value: a.id,
                                child: Text(a.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setModalState(() {
                          accountId = v;
                          if (!_isCreditAccount(accountId)) {
                            isMsi = false;
                          }
                        }),
                        decoration: const InputDecoration(labelText: 'Cuenta'),
                      ),
                    if (type != 'transfer') ...[
                      const SizedBox(height: 12),
                      Builder(
                        builder: (ctx) {
                          final acc = accountId != null
                              ? accounts.getAccountById(accountId!)
                              : null;
                          final base = auth.currentUserCurrency;
                          final needsTc = acc != null && acc.currency != base;
                          if (!needsTc) return const SizedBox.shrink();
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
                    ],
                    if (type == 'transfer') ...[
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
                        onChanged: (v) =>
                            setModalState(() => fromAccountId = v),
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
                                  controller: fromAmountController,
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
                                  controller: toAmountController,
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
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Monto',
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (type != 'transfer' &&
                        type == 'expense' &&
                        _isCreditAccount(accountId)) ...[
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
                    if (type != 'transfer')
                      DropdownButtonFormField<String>(
                        initialValue: categoryId,
                        items:
                            (type == 'income'
                                    ? categories.getIncomeCategories()
                                    : categories.getExpenseCategories())
                                .map(
                                  (c) => DropdownMenuItem<String>(
                                    value: c.id,
                                    child: Text(c.name),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setModalState(() => categoryId = v),
                        decoration: const InputDecoration(
                          labelText: 'Categoría',
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
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
                        final amount =
                            double.tryParse(_amountController.text.trim()) ??
                            0.0;
                        if (type == 'transfer') {
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
                          final amountFrom = differentCurrency
                              ? (double.tryParse(
                                      fromAmountController.text.trim(),
                                    ) ??
                                    0.0)
                              : (double.tryParse(
                                      _amountController.text.trim(),
                                    ) ??
                                    0.0);
                          final amountTo = differentCurrency
                              ? (double.tryParse(
                                      toAmountController.text.trim(),
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
                            description: _descriptionController.text.trim(),
                            date: date,
                          );
                        } else {
                          if (amount <= 0 ||
                              accountId == null ||
                              categoryId == null) {
                            Get.snackbar(
                              'Validación',
                              'Completa monto, cuenta y categoría',
                            );
                            return;
                          }
                          final acc = accountId != null
                              ? accounts.getAccountById(accountId!)
                              : null;
                          final base = auth.currentUserCurrency;
                          final needsTc = acc != null && acc.currency != base;
                          final tc = needsTc
                              ? (double.tryParse(tcController.text.trim()) ??
                                    0.0)
                              : 1.0;
                          final parsedMsiMonths =
                              int.tryParse(msiMonthsController.text.trim()) ??
                              0;
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
                          if (needsTc && tc <= 0) {
                            Get.snackbar('Validación', 'Ingresa un TC válido');
                            return;
                          }
                          final t = Transaction(
                            id: '',
                            userId: auth.currentUserId,
                            accountId: accountId!,
                            categoryId: categoryId!,
                            amount: amount,
                            type: type,
                            transactionDate: date,
                            purchaseDate: date,
                            description:
                                _descriptionController.text.trim().isEmpty
                                ? null
                                : _descriptionController.text.trim(),
                            merchant: null,
                            isRecurring: false,
                            createdAt: DateTime.now(),
                            exchangeRate: tc,
                          );
                          if (type == 'expense' &&
                              _isCreditAccount(accountId)) {
                            final cutoffDay = _resolveCreditCutoffDay(
                              accountId!,
                            );
                            if (isMsi) {
                              await transactions.addInstallmentPlan(
                                baseTransaction: t,
                                months: msiMonths,
                                cutoffDay: cutoffDay,
                              );
                            } else {
                              await transactions.addCreditExpenseWithCutoff(
                                purchaseTransaction: t,
                                cutoffDay: cutoffDay,
                              );
                            }
                          } else {
                            await transactions.addTransaction(t);
                          }
                        }
                        _amountController.clear();
                        _descriptionController.clear();
                        await dashboard.loadDashboardData();
                        if (ctx.mounted) Navigator.of(ctx).pop();
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
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _scanReceipt() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;
    final file = File(xfile.path);
    final inputImage = InputImage.fromFile(file);
    final recognizer = TextRecognizer();
    final result = await recognizer.processImage(inputImage);
    await recognizer.close();
    final text = result.text;
    final receipt = Receipt(
      id: Helpers.generateId(),
      transactionId: null,
      imagePath: xfile.path,
      extractedText: text,
      confidenceScore: null,
      processedAt: DateTime.now(),
    );
    await DatabaseService.getReceiptsBox().put(receipt.id, receipt);
    Get.snackbar('OCR', 'Texto extraído guardado');
  }

  String _monthName(int m) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return months[m - 1];
  }

  String _formatShortDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = (d.year % 100).toString().padLeft(2, '0');
    return '$dd/$mm/$yy';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Registro rápido',
            onPressed: _openQuickEntry,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppTheme.primaryColor),
              child: Text(
                auth.currentUser.value != null
                    ? 'Hola, ${auth.currentUser.value!.name}'
                    : 'Menú',
                style: AppTheme.titleMedium.copyWith(color: Colors.white),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: const Text('Cuentas'),
              onTap: () {
                Get.back();
                Get.toNamed('/accounts');
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Categorías'),
              onTap: () {
                Get.back();
                Get.toNamed('/categories');
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Transacciones'),
              onTap: () {
                Get.back();
                Get.toNamed('/transaction/list');
              },
            ),
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: const Text('Tarjetas'),
              onTap: () {
                Get.back();
                Get.toNamed(AppRoutes.cards);
              },
            ),
            ListTile(
              leading: const Icon(Icons.document_scanner),
              title: const Text('Escanear recibo'),
              onTap: () async {
                Get.back();
                await _scanReceipt();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configuraciones'),
              onTap: () {
                Get.back();
                Get.toNamed('/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () {
                Get.back();
                auth.logout();
              },
            ),
          ],
        ),
      ),
      body: Obx(() {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                auth.currentUser.value != null
                    ? 'Hola, ${auth.currentUser.value!.name}'
                    : 'Bienvenido a Financia',
                style: AppTheme.titleLarge,
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: dashboard.selectedAccountId.value.isEmpty
                    ? null
                    : dashboard.selectedAccountId.value,
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Todos'),
                  ),
                  ...accounts.accounts.map(
                    (a) => DropdownMenuItem<String>(
                      value: a.id,
                      child: Text(a.name),
                    ),
                  ),
                ],
                onChanged: (v) => dashboard.setAccountFilter(v ?? ''),
                decoration: const InputDecoration(labelText: 'Cuenta'),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    tooltip: 'Mes anterior',
                    onPressed: dashboard.prevMonth,
                  ),
                  Text(
                    '${_monthName(dashboard.selectedMonth.value.month)} ${dashboard.selectedMonth.value.year}',
                    style: AppTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    tooltip: 'Mes siguiente',
                    onPressed: dashboard.nextMonth,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (_) {
                  final selectedId = dashboard.selectedAccountId.value;
                  final displayCurrency = selectedId.isEmpty
                      ? auth.currentUserCurrency
                      : (accounts.getAccountById(selectedId)?.currency ??
                            auth.currentUserCurrency);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Moneda: $displayCurrency',
                      style: AppTheme.bodySmall,
                    ),
                  );
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Saldo inicial',
                      value: (() {
                        final selectedId = dashboard.selectedAccountId.value;
                        final displayCurrency = selectedId.isEmpty
                            ? auth.currentUserCurrency
                            : (accounts.getAccountById(selectedId)?.currency ??
                                  auth.currentUserCurrency);
                        return Helpers.formatCurrency(
                          dashboard.monthOpeningBalance,
                          displayCurrency,
                        );
                      })(),
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Saldo final',
                      value: (() {
                        final selectedId = dashboard.selectedAccountId.value;
                        final displayCurrency = selectedId.isEmpty
                            ? auth.currentUserCurrency
                            : (accounts.getAccountById(selectedId)?.currency ??
                                  auth.currentUserCurrency);
                        return Helpers.formatCurrency(
                          dashboard.monthClosingBalance,
                          displayCurrency,
                        );
                      })(),
                      color: AppTheme.accentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Gastos',
                      value: (() {
                        final selectedId = dashboard.selectedAccountId.value;
                        final displayCurrency = selectedId.isEmpty
                            ? auth.currentUserCurrency
                            : (accounts.getAccountById(selectedId)?.currency ??
                                  auth.currentUserCurrency);
                        return Helpers.formatCurrency(
                          dashboard.totalExpense.value,
                          displayCurrency,
                        );
                      })(),
                      color: AppTheme.errorColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Ingresos',
                      value: (() {
                        final selectedId = dashboard.selectedAccountId.value;
                        final displayCurrency = selectedId.isEmpty
                            ? auth.currentUserCurrency
                            : (accounts.getAccountById(selectedId)?.currency ??
                                  auth.currentUserCurrency);
                        return Helpers.formatCurrency(
                          dashboard.totalIncome.value,
                          displayCurrency,
                        );
                      })(),
                      color: AppTheme.successColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Traspasos (entrada)',
                      value: (() {
                        final selectedId = dashboard.selectedAccountId.value;
                        final displayCurrency = selectedId.isEmpty
                            ? auth.currentUserCurrency
                            : (accounts.getAccountById(selectedId)?.currency ??
                                  auth.currentUserCurrency);
                        return Helpers.formatCurrency(
                          dashboard.transfersIn.value,
                          displayCurrency,
                        );
                      })(),
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Traspasos (salida)',
                      value: (() {
                        final selectedId = dashboard.selectedAccountId.value;
                        final displayCurrency = selectedId.isEmpty
                            ? auth.currentUserCurrency
                            : (accounts.getAccountById(selectedId)?.currency ??
                                  auth.currentUserCurrency);
                        return Helpers.formatCurrency(
                          dashboard.transfersOut.value,
                          displayCurrency,
                        );
                      })(),
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Flujo neto',
                      value: (() {
                        final selectedId = dashboard.selectedAccountId.value;
                        final displayCurrency = selectedId.isEmpty
                            ? auth.currentUserCurrency
                            : (accounts.getAccountById(selectedId)?.currency ??
                                  auth.currentUserCurrency);
                        return Helpers.formatCurrency(
                          dashboard.netCashFlow.value,
                          displayCurrency,
                        );
                      })(),
                      color: AppTheme.warningColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                decoration: AppTheme.cardDecoration,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Gasto por categoría', style: AppTheme.titleMedium),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: Builder(
                        builder: (ctx) {
                          final data = dashboard.categoryExpenseData;
                          if (data.isEmpty) {
                            return Center(
                              child: Text(
                                'Sin datos de gasto',
                                style: AppTheme.bodyMedium,
                              ),
                            );
                          }
                          final total = data.fold<double>(
                            0.0,
                            (s, e) => s + (e['amount'] as double),
                          );
                          final List<Map<String, dynamic>> top = [];
                          double acc = 0.0;
                          for (final e in data) {
                            if (total > 0 && acc / total >= 0.8) break;
                            top.add(e);
                            acc += (e['amount'] as double);
                          }
                          final double others = (total - acc).clamp(
                            0.0,
                            double.infinity,
                          );
                          final sections = [
                            ...top.map((e) {
                              final amount = e['amount'] as double;
                              final pct = total > 0
                                  ? (amount / total) * 100
                                  : 0.0;
                              return PieChartSectionData(
                                color: _randomColorForKey(
                                  e['categoryId'] as String,
                                ),
                                value: amount,
                                title: '${pct.toStringAsFixed(0)}%',
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                radius: 70,
                              );
                            }),
                            if (others > 0)
                              PieChartSectionData(
                                color: _randomColorForKey('otros'),
                                value: others,
                                title: 'Otros',
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                radius: 70,
                              ),
                          ];
                          return GestureDetector(
                            onTap: () =>
                                Get.toNamed(AppRoutes.categoryExpenseDetail),
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                                sections: sections,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (ctx) {
                        final data = dashboard.categoryExpenseData;
                        final total = data.fold<double>(
                          0.0,
                          (s, e) => s + (e['amount'] as double),
                        );
                        final List<Map<String, dynamic>> top = [];
                        double acc = 0.0;
                        for (final e in data) {
                          if (total > 0 && acc / total >= 0.8) break;
                          top.add(e);
                          acc += (e['amount'] as double);
                        }
                        final double others = (total - acc).clamp(
                          0.0,
                          double.infinity,
                        );
                        final List<Map<String, dynamic>> items = [
                          ...top,
                          if (others > 0)
                            {
                              'categoryId': 'otros',
                              'categoryName': 'Otros',
                              'amount': others,
                            },
                        ];
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (_, index) =>
                              const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final e = items[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _randomColorForKey(
                                  e['categoryId'] as String,
                                ),
                                radius: 8,
                              ),
                              title: Text(e['categoryName'] as String),
                              trailing: Text(
                                Helpers.formatCurrency(
                                  e['amount'] as double,
                                  auth.currentUserCurrency,
                                ),
                                style: AppTheme.titleSmall,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              /*               const SizedBox(height: 24),
              Container(
                decoration: AppTheme.cardDecoration,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Presupuesto y metas', style: AppTheme.titleMedium),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value:
                          (dashboard.budgetUtilization.value.clamp(
                            0.0,
                            100.0,
                          )) /
                          100.0,
                      color: AppTheme.accentColor,
                      backgroundColor: Colors.grey[300],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${dashboard.budgetUtilization.value.toStringAsFixed(1)}% utilizado',
                      style: AppTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value:
                          (dashboard.goalsProgress.value.clamp(0.0, 100.0)) /
                          100.0,
                      color: AppTheme.successColor,
                      backgroundColor: Colors.grey[300],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Progreso de metas: ${dashboard.goalsProgress.value.toStringAsFixed(1)}%',
                      style: AppTheme.bodyMedium,
                    ),
                  ],
                ),
              ), */
              const SizedBox(height: 24),
              Container(
                decoration: AppTheme.cardDecoration,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Resumen por cuenta', style: AppTheme.titleMedium),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        IconData iconForType(String type) {
                          switch (type) {
                            case 'cash':
                              return Icons.account_balance_wallet;
                            case 'checking':
                              return Icons.account_balance;
                            case 'savings':
                              return Icons.savings;
                            case 'credit':
                              return Icons.credit_card;
                            case 'investment':
                              return Icons.trending_up;
                            default:
                              return Icons.account_balance;
                          }
                        }

                        String typeLabel(String type) {
                          switch (type) {
                            case 'cash':
                              return 'Efectivo';
                            case 'checking':
                              return 'Cuenta corriente';
                            case 'savings':
                              return 'Caja de ahorro';
                            case 'credit':
                              return 'Tarjeta de crédito';
                            case 'investment':
                              return 'Inversión';
                            default:
                              return type;
                          }
                        }

                        final accs = accounts.accounts
                            .where(
                              (a) =>
                                  accounts.computeBalanceForAccount(a.id) != 0,
                            )
                            .toList();
                        if (accs.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Sin cuentas con saldo',
                              style: AppTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: accs.length,
                          separatorBuilder: (_, index) =>
                              const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final a = accs[i];
                            final bal = accounts.computeBalanceForAccount(a.id);
                            return ListTile(
                              leading: Icon(iconForType(a.type)),
                              title: Text(a.name),
                              subtitle: Text(typeLabel(a.type)),
                              trailing: Text(
                                Helpers.formatCurrency(bal, a.currency),
                                style: AppTheme.titleSmall,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: AppTheme.cardDecoration,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Tendencias e insights', style: AppTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...dashboard.getFinancialInsights().map(
                      (s) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.insights,
                              color: Colors.orange,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(s, style: AppTheme.bodyMedium),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: AppTheme.cardDecoration,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Transacciones recientes',
                      style: AppTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...dashboard.recentTransactions
                        .take(5)
                        .map(
                          (t) => ListTile(
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
                            subtitle: Text(
                              '${t.categoryId} • ${_formatShortDate(t.transactionDate.toLocal())}',
                            ),
                          ),
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              /*               Container(
                decoration: AppTheme.cardDecoration,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Simulación What-If', style: AppTheme.titleMedium),
                    const SizedBox(height: 8),
                    Slider(
                      value: _deltaSimulation,
                      min: -1000,
                      max: 1000,
                      divisions: 40,
                      label: _deltaSimulation.toStringAsFixed(0),
                      onChanged: (v) => setState(() => _deltaSimulation = v),
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final projectedNet =
                            dashboard.netCashFlow.value + _deltaSimulation;
                        final text =
                            'Flujo neto proyectado: ${Helpers.formatCurrency(projectedNet, auth.currentUserCurrency)}';
                        return Text(text, style: AppTheme.bodyLarge);
                      },
                    ),
                  ],
                ),
              ), */
            ],
          ),
        );
      }),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(value, style: AppTheme.titleMedium.copyWith(color: color)),
        ],
      ),
    );
  }
}

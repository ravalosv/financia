import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/account_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/category_controller.dart';
import '../controllers/transaction_controller.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';

class AccountStatementScreen extends StatefulWidget {
  const AccountStatementScreen({super.key});

  @override
  State<AccountStatementScreen> createState() => _AccountStatementScreenState();
}

class _AccountStatementScreenState extends State<AccountStatementScreen> {
  final auth = Get.find<AuthController>();
  final accounts = Get.find<AccountController>();
  final categories = Get.find<CategoryController>();
  final transactions = Get.find<TransactionController>();

  String? _accountId;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    final initialAccountId = args is Map<String, dynamic>
        ? args['accountId'] as String?
        : null;
    final availableAccounts = _availableAccounts;
    if (initialAccountId != null &&
        availableAccounts.any((account) => account.id == initialAccountId)) {
      _accountId = initialAccountId;
    } else if (availableAccounts.isNotEmpty) {
      _accountId = availableAccounts.first.id;
    }
  }

  List<Account> get _availableAccounts =>
      accounts.getActiveAccounts()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  Future<void> _pickDateRange() async {
    final start = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (start == null || !mounted) return;

    final effectiveEnd = _endDate.isBefore(start) ? start : _endDate;
    final end = await showDatePicker(
      context: context,
      initialDate: effectiveEnd,
      firstDate: start,
      lastDate: DateTime(2100),
    );
    if (end == null) return;

    setState(() {
      _startDate = start;
      _endDate = end;
    });
  }

  double _signedAmount(Transaction transaction) =>
      transaction.type == 'income' ? transaction.amount : -transaction.amount;

  double _openingBalance(String accountId) {
    final start = _dateOnly(_startDate);
    return transactions.transactions
        .where((transaction) => transaction.accountId == accountId)
        .where(
          (transaction) =>
              _dateOnly(transaction.transactionDate).isBefore(start),
        )
        .fold(0.0, (sum, transaction) => sum + _signedAmount(transaction));
  }

  List<_StatementEntry> _entriesFor(String accountId) {
    final start = _dateOnly(_startDate);
    final end = _dateOnly(_endDate);
    final items =
        transactions.transactions
            .where((transaction) => transaction.accountId == accountId)
            .where((transaction) {
              final date = _dateOnly(transaction.transactionDate);
              return !date.isBefore(start) && !date.isAfter(end);
            })
            .toList()
          ..sort((a, b) {
            final byDate = a.transactionDate.compareTo(b.transactionDate);
            if (byDate != 0) return byDate;
            return a.createdAt.compareTo(b.createdAt);
          });

    var runningBalance = _openingBalance(accountId);
    return items
        .map((transaction) {
          runningBalance += _signedAmount(transaction);
          return _StatementEntry(
            transaction: transaction,
            balanceAfter: runningBalance,
          );
        })
        .toList(growable: false);
  }

  String _formatShortDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yy = (date.year % 100).toString().padLeft(2, '0');
    return '$dd/$mm/$yy';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estado de cuenta')),
      body: Obx(() {
        final availableAccounts = _availableAccounts;
        if (_accountId == null &&
            availableAccounts.isNotEmpty &&
            !availableAccounts.any((account) => account.id == _accountId)) {
          _accountId = availableAccounts.first.id;
        }
        final selectedAccount = _accountId == null
            ? null
            : accounts.getAccountById(_accountId!);
        final currency = selectedAccount?.currency ?? auth.currentUserCurrency;
        final openingBalance = selectedAccount == null
            ? 0.0
            : _openingBalance(selectedAccount.id);
        final entries = selectedAccount == null
            ? const <_StatementEntry>[]
            : _entriesFor(selectedAccount.id);
        final closingBalance = entries.isEmpty
            ? openingBalance
            : entries.last.balanceAfter;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: AppTheme.cardDecoration,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _accountId,
                      items: availableAccounts
                          .map(
                            (account) => DropdownMenuItem<String>(
                              value: account.id,
                              child: Text(account.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _accountId = value),
                      decoration: const InputDecoration(labelText: 'Cuenta'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _pickDateRange,
                      child: Text(
                        '${_formatShortDate(_startDate)}  →  ${_formatShortDate(_endDate)}',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: AppTheme.cardDecoration,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Saldo inicial', style: AppTheme.bodyMedium),
                          const SizedBox(height: 4),
                          Text(
                            Helpers.formatCurrency(openingBalance, currency),
                            style: AppTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Saldo final', style: AppTheme.bodyMedium),
                          const SizedBox(height: 4),
                          Text(
                            Helpers.formatCurrency(closingBalance, currency),
                            style: AppTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (selectedAccount == null)
                Container(
                  decoration: AppTheme.cardDecoration,
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No hay cuentas disponibles',
                    style: AppTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                )
              else if (entries.isEmpty)
                Container(
                  decoration: AppTheme.cardDecoration,
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Sin movimientos en el periodo',
                    style: AppTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Container(
                  decoration: AppTheme.cardDecoration,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: entries.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final transaction = entry.transaction;
                      final category = categories.getCategoryById(
                        transaction.categoryId,
                      );
                      final signedAmount = _signedAmount(transaction);
                      final amountColor = signedAmount >= 0
                          ? AppTheme.successColor
                          : AppTheme.errorColor;
                      final subtitleParts = <String>[
                        category?.name ?? transaction.categoryId,
                        _formatShortDate(transaction.transactionDate),
                        if ((transaction.description ?? '').trim().isNotEmpty)
                          transaction.description!.trim(),
                      ];

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        title: Text(
                          Helpers.formatCurrency(signedAmount, currency),
                          style: AppTheme.titleSmall.copyWith(
                            color: amountColor,
                          ),
                        ),
                        subtitle: Text(
                          subtitleParts.join(' • '),
                          style: AppTheme.bodyMedium,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Saldo', style: AppTheme.bodySmall),
                            const SizedBox(height: 2),
                            Text(
                              Helpers.formatCurrency(
                                entry.balanceAfter,
                                currency,
                              ),
                              style: AppTheme.labelLarge,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _StatementEntry {
  final Transaction transaction;
  final double balanceAfter;

  const _StatementEntry({
    required this.transaction,
    required this.balanceAfter,
  });
}

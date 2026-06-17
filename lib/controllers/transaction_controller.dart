import 'package:get/get.dart';
import '../models/transaction_model.dart';
import '../database/database_service.dart';
import '../utils/helpers.dart';

class TransactionController extends GetxController {
  final DatabaseService _databaseService = Get.put(DatabaseService());

  var transactions = <Transaction>[].obs;
  var filteredTransactions = <Transaction>[].obs;
  var isLoading = false.obs;

  // Filter parameters
  var selectedAccountId = ''.obs;
  var selectedCategoryId = ''.obs;
  var startDate = DateTime.now().subtract(const Duration(days: 30)).obs;
  var endDate = DateTime.now().obs;
  var transactionType = 'all'.obs; // 'all', 'income', 'expense'

  @override
  void onInit() {
    super.onInit();
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    try {
      isLoading(true);
      final loadedTransactions = await _databaseService.getAllTransactions();
      transactions.assignAll(loadedTransactions);
      applyFilters();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load transactions: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    try {
      isLoading(true);
      if (transaction.id.isEmpty) {
        transaction = transaction.copyWith(id: Helpers.generateId());
      }
      await _databaseService.insertTransaction(transaction);
      transactions.add(transaction);
      applyFilters();
      Get.snackbar('Exito', 'Transaccion agregada correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo agregar la transaccion: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> addInstallmentPlan({
    required Transaction baseTransaction,
    required int months,
    required int cutoffDay,
  }) async {
    try {
      isLoading(true);
      final planId = Helpers.generateId();
      final monthlyBase = _roundAmount(baseTransaction.amount / months);
      double assignedAmount = 0;
      final createdTransactions = <Transaction>[];
      final purchaseDate =
          baseTransaction.purchaseDate ?? baseTransaction.transactionDate;
      final startOffset = purchaseDate.day > cutoffDay ? 1 : 0;

      for (var i = 0; i < months; i++) {
        final installmentAmount = i == months - 1
            ? _roundAmount(baseTransaction.amount - assignedAmount)
            : monthlyBase;
        assignedAmount = _roundAmount(assignedAmount + installmentAmount);

        final installment = baseTransaction.copyWith(
          id: Helpers.generateId(),
          amount: installmentAmount,
          transactionDate: _addMonthsKeepingDay(purchaseDate, startOffset + i),
          purchaseDate: purchaseDate,
          createdAt: DateTime.now(),
          installmentPlanId: planId,
          installmentIndex: i + 1,
          installmentCount: months,
        );

        await _databaseService.insertTransaction(installment);
        createdTransactions.add(installment);
      }

      transactions.addAll(createdTransactions);
      applyFilters();
      Get.snackbar('Exito', 'Compra MSI guardada correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo guardar el plan MSI: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> addCreditExpenseWithCutoff({
    required Transaction purchaseTransaction,
    required int cutoffDay,
  }) async {
    final purchaseDate =
        purchaseTransaction.purchaseDate ?? purchaseTransaction.transactionDate;
    final startOffset = purchaseDate.day > cutoffDay ? 1 : 0;
    final paymentTransaction = purchaseTransaction.copyWith(
      transactionDate: _addMonthsKeepingDay(purchaseDate, startOffset),
      purchaseDate: purchaseDate,
    );
    await addTransaction(paymentTransaction);
  }

  Future<void> updateTransaction(Transaction transaction) async {
    try {
      isLoading(true);

      // Update only the transaction record; balances are derived from transactions

      // Update in database
      await _databaseService.updateTransaction(transaction);

      // Update local list
      final index = transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        transactions[index] = transaction;
      }
      applyFilters();

      Get.snackbar('Success', 'Transaction updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update transaction: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    try {
      isLoading(true);
      await _databaseService.deleteTransaction(transactionId);
      transactions.removeWhere((t) => t.id == transactionId);
      applyFilters();
      Get.snackbar('Exito', 'Transaccion eliminada correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo eliminar la transaccion: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> deleteInstallmentPlan(String planId) async {
    try {
      isLoading(true);
      final transactionsToDelete = transactions
          .where((item) => item.installmentPlanId == planId)
          .toList();

      for (final item in transactionsToDelete) {
        await _databaseService.deleteTransaction(item.id);
      }

      final ids = transactionsToDelete.map((item) => item.id).toSet();
      transactions.removeWhere((item) => ids.contains(item.id));
      applyFilters();
      Get.snackbar('Exito', 'Plan MSI cancelado correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo cancelar el plan MSI: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> deleteTransferPair(Transaction t) async {
    try {
      isLoading(true);
      Transaction? other;
      try {
        other = transactions.firstWhere(
          (o) =>
              o.userId == t.userId &&
              o.createdAt == t.createdAt &&
              o.transactionDate == t.transactionDate &&
              o.merchant == 'Traspaso' &&
              o.accountId != t.accountId &&
              ((t.categoryId == 'transfer_in' &&
                      o.categoryId == 'transfer_out') ||
                  (t.categoryId == 'transfer_out' &&
                      o.categoryId == 'transfer_in')),
        );
      } catch (_) {
        other = null;
      }

      await _databaseService.deleteTransaction(t.id);
      transactions.removeWhere((x) => x.id == t.id);

      if (other != null) {
        await _databaseService.deleteTransaction(other.id);
        transactions.removeWhere((x) => x.id == other!.id);
      }

      applyFilters();
      Get.snackbar('Success', 'Transfer deleted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete transfer: $e');
    } finally {
      isLoading(false);
    }
  }

  // Removed balance updating; balances are computed on demand from transactions

  void applyFilters() {
    filteredTransactions.assignAll(
      transactions.where((transaction) {
        // Account filter
        if (selectedAccountId.isNotEmpty &&
            transaction.accountId != selectedAccountId.value) {
          return false;
        }

        // Category filter
        if (selectedCategoryId.isNotEmpty &&
            transaction.categoryId != selectedCategoryId.value) {
          return false;
        }

        // Date filter
        if (transaction.transactionDate.isBefore(startDate.value) ||
            transaction.transactionDate.isAfter(endDate.value)) {
          return false;
        }

        // Type filter
        if (transactionType.value != 'all' &&
            transaction.type != transactionType.value) {
          return false;
        }

        return true;
      }).toList(),
    );
  }

  void setAccountFilter(String accountId) {
    selectedAccountId.value = accountId;
    applyFilters();
  }

  void setCategoryFilter(String categoryId) {
    selectedCategoryId.value = categoryId;
    applyFilters();
  }

  void setDateFilter(DateTime start, DateTime end) {
    startDate.value = start;
    endDate.value = end;
    applyFilters();
  }

  void setTypeFilter(String type) {
    transactionType.value = type;
    applyFilters();
  }

  void clearFilters() {
    selectedAccountId.value = '';
    selectedCategoryId.value = '';
    startDate.value = DateTime.now().subtract(const Duration(days: 30));
    endDate.value = DateTime.now();
    transactionType.value = 'all';
    applyFilters();
  }

  // Statistics calculations
  double get totalIncome {
    return transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpense {
    return transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get netBalance {
    return totalIncome - totalExpense;
  }

  Map<String, double> get expensesByCategory {
    final expenses = <String, double>{};
    for (final transaction in transactions.where((t) => t.type == 'expense')) {
      expenses[transaction.categoryId] =
          (expenses[transaction.categoryId] ?? 0) + transaction.amount;
    }
    return expenses;
  }

  List<Transaction> getRecentTransactions({int limit = 10}) {
    final sorted = List<Transaction>.from(transactions)
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return sorted.take(limit).toList();
  }

  List<Transaction> getTransactionsByDateRange(DateTime start, DateTime end) {
    return transactions
        .where(
          (t) =>
              t.transactionDate.isAfter(start) &&
              t.transactionDate.isBefore(end.add(const Duration(days: 1))),
        )
        .toList();
  }

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

  double _roundAmount(double value) => double.parse(value.toStringAsFixed(2));
}

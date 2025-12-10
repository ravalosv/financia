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

      // Generate ID if not provided
      if (transaction.id.isEmpty) {
        transaction = transaction.copyWith(id: Helpers.generateId());
      }

      // Do not update account balance field; balances are derived from transactions

      // Add to database
      await _databaseService.insertTransaction(transaction);

      // Update local list
      transactions.add(transaction);
      applyFilters();

      Get.snackbar('Success', 'Transaction added successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add transaction: $e');
    } finally {
      isLoading(false);
    }
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

      // Remove only the transaction; balances are derived from transactions

      // Delete from database
      await _databaseService.deleteTransaction(transactionId);

      // Update local list
      transactions.removeWhere((t) => t.id == transactionId);
      applyFilters();

      Get.snackbar('Success', 'Transaction deleted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete transaction: $e');
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
}

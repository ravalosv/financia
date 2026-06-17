import 'package:get/get.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../database/database_service.dart';
import 'auth_controller.dart';
import 'card_controller.dart';
import 'transaction_controller.dart';
import '../utils/helpers.dart';

class AccountController extends GetxController {
  final DatabaseService _databaseService = Get.put(DatabaseService());

  var accounts = <Account>[].obs;
  var isLoading = false.obs;

  // Default account types to create on first run
  final List<Map<String, String>> _defaultAccounts = const [
    {'id': 'cash', 'name': 'Cash', 'type': 'cash'},
    {'id': 'checking', 'name': 'Checking Account', 'type': 'checking'},
    {'id': 'savings', 'name': 'Savings Account', 'type': 'savings'},
    {'id': 'credit', 'name': 'Credit Card', 'type': 'credit'},
  ];

  @override
  void onInit() {
    super.onInit();
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    try {
      isLoading(true);

      // Check if accounts exist, if not create default ones
      final existingAccounts = await _databaseService.getAllAccounts();

      if (existingAccounts.isEmpty) {
        // Create default accounts
        await _createDefaultAccounts();
      }

      final loadedAccounts = await _databaseService.getAllAccounts();
      accounts.assignAll(loadedAccounts);
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar las cuentas: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> _createDefaultAccounts() async {
    try {
      final userId = Get.find<AuthController>().currentUserId;
      for (final data in _defaultAccounts) {
        final account = Account(
          id: data['id']!,
          userId: userId,
          name: data['name']!,
          type: data['type']!,
          currency: 'USD',
          isActive: true,
          createdAt: DateTime.now(),
        );
        await _databaseService.insertAccount(account);
      }
    } catch (e) {
      throw Exception('Failed to create default accounts: $e');
    }
  }

  Future<void> addAccount(Account account) async {
    try {
      isLoading(true);

      // Generate ID if not provided
      if (account.id.isEmpty) {
        account = account.copyWith(id: Helpers.generateId());
      }

      // Set default values if not provided
      if (account.currency.isEmpty) {
        account = account.copyWith(currency: 'USD');
      }

      // No color/icon fields in model; keep minimal data

      // Add to database
      await _databaseService.insertAccount(account);

      // Update local list
      accounts.add(account);

      Get.snackbar('Éxito', 'Cuenta agregada correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo agregar la cuenta: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateAccount(Account account) async {
    try {
      isLoading(true);

      // Update in database
      await _databaseService.updateAccount(account);

      // Update local list
      final index = accounts.indexWhere((a) => a.id == account.id);
      if (index != -1) {
        accounts[index] = account;
      }

      Get.snackbar('Éxito', 'Cuenta actualizada correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo actualizar la cuenta: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> deleteAccount(String accountId) async {
    try {
      isLoading(true);

      // Check if account has transactions
      final transactionController = Get.find<TransactionController>();
      final hasTransactions = transactionController.transactions.any(
        (t) => t.accountId == accountId,
      );

      if (hasTransactions) {
        Get.snackbar(
          'Aviso',
          'No es posible eliminar la cuenta con transacciones existentes',
        );
        return;
      }

      final cardController = Get.find<CardController>();
      final linkedCard = cardController.getCardByLinkedAccountId(accountId);
      if (linkedCard != null) {
        Get.snackbar(
          'Aviso',
          'No es posible eliminar la cuenta porque tiene una tarjeta ligada',
        );
        return;
      }

      // Delete from database
      await _databaseService.deleteAccount(accountId);

      // Update local list
      accounts.removeWhere((a) => a.id == accountId);

      Get.snackbar('Éxito', 'Cuenta eliminada correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo eliminar la cuenta: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateAccountBalance(String accountId, double newBalance) async {
    try {
      // Deprecated: balances are derived from transactions; no direct updates
    } catch (e) {
      throw Exception('No se pudo actualizar el saldo de la cuenta: $e');
    }
  }

  // Get accounts by type
  List<Account> getAccountsByType(String type) {
    return accounts.where((a) => a.type == type).toList();
  }

  // Get account by ID
  Account? getAccountById(String accountId) {
    try {
      return accounts.firstWhere((a) => a.id == accountId);
    } catch (e) {
      return null;
    }
  }

  // Get active accounts
  List<Account> getActiveAccounts() {
    return accounts.where((a) => a.isActive).toList();
  }

  // Search accounts
  List<Account> searchAccounts(String query) {
    if (query.isEmpty) return accounts;

    return accounts
        .where((a) => a.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Get account statistics
  Map<String, double> getAccountBalances() {
    final balances = <String, double>{};
    for (final account in accounts) {
      balances[account.id] = computeBalanceForAccount(account.id);
    }
    return balances;
  }

  // Get total balance (excluding credit cards)
  double get totalBalance {
    return accounts
        .where((a) => a.type != 'credit')
        .fold(0.0, (sum, a) => sum + computeBalanceForAccount(a.id));
  }

  // Get total credit card balance
  double get totalCreditBalance {
    return accounts
        .where((a) => a.type == 'credit')
        .fold(0.0, (sum, a) => sum + computeBalanceForAccount(a.id));
  }

  // Get total assets (cash, checking, savings, investment)
  double get totalAssets {
    return accounts
        .where(
          (a) => ['cash', 'checking', 'savings', 'investment'].contains(a.type),
        )
        .fold(0.0, (sum, a) => sum + computeBalanceForAccount(a.id));
  }

  // Get total liabilities (credit cards)
  double get totalLiabilities {
    return accounts
        .where((a) => a.type == 'credit')
        .fold(0.0, (sum, a) => sum + computeBalanceForAccount(a.id));
  }

  // Get net worth (assets - liabilities)
  double get netWorth {
    return totalAssets - totalLiabilities;
  }

  // Toggle account active status
  Future<void> toggleAccountActive(String accountId) async {
    try {
      final account = getAccountById(accountId);
      if (account != null) {
        final updatedAccount = account.copyWith(isActive: !account.isActive);
        await updateAccount(updatedAccount);
      }
    } catch (e) {
      Get.snackbar('Error', 'No se pudo cambiar el estado de la cuenta: $e');
    }
  }

  // Transfer money between accounts
  Future<void> transferMoney({
    required String fromAccountId,
    required String toAccountId,
    required double amountFrom,
    required double amountTo,
    required String description,
    DateTime? date,
  }) async {
    try {
      if (amountFrom <= 0 || amountTo <= 0) {
        throw Exception('El monto debe ser positivo');
      }

      if (fromAccountId == toAccountId) {
        throw Exception('No se puede transferir a la misma cuenta');
      }

      final fromAccount = getAccountById(fromAccountId);
      final toAccount = getAccountById(toAccountId);

      if (fromAccount == null || toAccount == null) {
        throw Exception('Cuenta origen o destino no encontrada');
      }

      if (computeBalanceForAccount(fromAccountId) < amountFrom) {
        throw Exception('Fondos insuficientes en la cuenta origen');
      }

      isLoading(true);

      // No direct balance updates; create transfer transactions only

      // Create transfer transactions
      final transactionController = Get.find<TransactionController>();

      // Expense transaction from source account
      final userId = Get.find<AuthController>().currentUserId;
      final baseCurrency = Get.find<AuthController>().currentUserCurrency;
      final now = date ?? DateTime.now();
      double expenseExchangeRate = 1.0;
      double incomeExchangeRate = 1.0;
      if (fromAccount.currency == baseCurrency &&
          toAccount.currency != baseCurrency) {
        incomeExchangeRate = amountFrom / amountTo;
        expenseExchangeRate = 1.0;
      } else if (toAccount.currency == baseCurrency &&
          fromAccount.currency != baseCurrency) {
        expenseExchangeRate = amountTo / amountFrom;
        incomeExchangeRate = 1.0;
      } else if (toAccount.currency == baseCurrency &&
          fromAccount.currency == baseCurrency) {
        expenseExchangeRate = 1.0;
        incomeExchangeRate = 1.0;
      } else {
        expenseExchangeRate = 1.0;
        incomeExchangeRate = 1.0;
      }
      final expenseTransaction = Transaction(
        id: Helpers.generateId(),
        userId: userId,
        accountId: fromAccountId,
        categoryId: 'transfer_out',
        amount: amountFrom,
        type: 'expense',
        transactionDate: now,
        description: 'Traspaso a ${toAccount.name}: $description',
        merchant: 'Traspaso',
        isRecurring: false,
        createdAt: now,
        exchangeRate: expenseExchangeRate,
      );

      // Income transaction to destination account
      final incomeTransaction = Transaction(
        id: Helpers.generateId(),
        userId: userId,
        accountId: toAccountId,
        categoryId: 'transfer_in',
        amount: amountTo,
        type: 'income',
        transactionDate: now,
        description: 'Traspaso desde ${fromAccount.name}: $description',
        merchant: 'Traspaso',
        isRecurring: false,
        createdAt: now,
        exchangeRate: incomeExchangeRate,
      );

      await transactionController.addTransaction(expenseTransaction);
      await transactionController.addTransaction(incomeTransaction);

      Get.snackbar('Éxito', 'Traspaso completado');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo completar el traspaso: $e');
    } finally {
      isLoading(false);
    }
  }

  // Create custom account
  Future<Account> createCustomAccount({
    required String name,
    required String type,
    String currency = 'USD',
  }) async {
    try {
      final userId = Get.find<AuthController>().currentUserId;
      final customAccount = Account(
        id: Helpers.generateId(),
        userId: userId,
        name: name,
        type: type,
        currency: currency,
        isActive: true,
        createdAt: DateTime.now(),
      );
      await addAccount(customAccount);
      return customAccount;
    } catch (e) {
      throw Exception('Failed to create custom account: $e');
    }
  }

  double computeBalanceForAccount(String accountId) {
    final transactionController = Get.find<TransactionController>();
    double balance = 0.0;
    for (final t in transactionController.transactions) {
      if (t.accountId == accountId) {
        balance += t.type == 'income' ? t.amount : -t.amount;
      }
    }
    return balance;
  }

  // Removed color/icon utilities; keep controller focused on balances
}

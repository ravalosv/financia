import 'package:get/get.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import '../database/database_service.dart';
import '../utils/helpers.dart';
import 'transaction_controller.dart';
import 'account_controller.dart';
import 'budget_controller.dart';
import 'goal_controller.dart';
import 'category_controller.dart';

class DashboardController extends GetxController {
  final DatabaseService _databaseService = Get.put(DatabaseService());

  var isLoading = false.obs;
  var selectedTimeRange = 'month'.obs; // 'week', 'month', 'quarter', 'year'
  var selectedAccountId = ''.obs;
  var selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  ).obs;

  // Dashboard data
  var totalBalance = 0.0.obs;
  var totalIncome = 0.0.obs;
  var totalExpense = 0.0.obs;
  var netCashFlow = 0.0.obs;
  var budgetUtilization = 0.0.obs;
  var goalsProgress = 0.0.obs;
  var transfersIn = 0.0.obs;
  var transfersOut = 0.0.obs;

  // Charts data
  var incomeExpenseData = <Map<String, dynamic>>[].obs;
  var categoryExpenseData = <Map<String, dynamic>>[].obs;
  var accountBalanceData = <Map<String, dynamic>>[].obs;
  var monthlyTrendData = <Map<String, dynamic>>[].obs;

  // Recent data
  var recentTransactions = <Transaction>[].obs;
  var budgetAlerts = <Budget>[].obs;
  var goalsNeedingAttention = <Goal>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
    final transactionController = Get.find<TransactionController>();
    final accountController = Get.find<AccountController>();
    final budgetController = Get.find<BudgetController>();
    final goalController = Get.find<GoalController>();
    ever(transactionController.transactions, (_) => loadDashboardData());
    ever(accountController.accounts, (_) => loadDashboardData());
    ever(budgetController.budgets, (_) => loadDashboardData());
    ever(goalController.goals, (_) => loadDashboardData());
  }

  Future<void> loadDashboardData() async {
    try {
      isLoading(true);

      // Load all necessary data
      await _loadFinancialSummary();
      await _loadChartsData();
      await _loadRecentData();
      await _loadAlerts();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load dashboard data: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> _loadFinancialSummary() async {
    try {
      final transactionController = Get.find<TransactionController>();
      final accountController = Get.find<AccountController>();
      final budgetController = Get.find<BudgetController>();
      final goalController = Get.find<GoalController>();

      // Calculate time range
      final dateRange = _getDateRangeForTimeRange(selectedTimeRange.value);

      final inScopeTransactions = transactionController.transactions.where((t) {
        final inTimeRange =
            t.transactionDate.isAfter(dateRange['start']!) &&
            t.transactionDate.isBefore(
              dateRange['end']!.add(const Duration(days: 1)),
            );
        final inAccount =
            selectedAccountId.value.isEmpty ||
            t.accountId == selectedAccountId.value;
        return inTimeRange && inAccount;
      }).toList();

      // Calculate totals
      double income = 0.0;
      double expense = 0.0;
      double tIn = 0.0;
      double tOut = 0.0;

      for (final transaction in inScopeTransactions) {
        final amt = selectedAccountId.value.isEmpty
            ? (transaction.amount * transaction.exchangeRate)
            : transaction.amount;
        if (transaction.categoryId == 'transfer_in') {
          tIn += amt;
        } else if (transaction.categoryId == 'transfer_out') {
          tOut += amt;
        }
      }

      final nonTransferTransactions = inScopeTransactions.where((t) {
        return !(t.categoryId == 'transfer_in' ||
            t.categoryId == 'transfer_out');
      });

      for (final transaction in nonTransferTransactions) {
        final amt = selectedAccountId.value.isEmpty
            ? (transaction.amount * transaction.exchangeRate)
            : transaction.amount;
        if (transaction.type == 'income') {
          income += amt;
        } else if (transaction.type == 'expense') {
          expense += amt;
        }
      }

      totalIncome(income);
      totalExpense(expense);
      netCashFlow(income - expense);
      transfersIn(tIn);
      transfersOut(tOut);

      // Calculate total balance
      if (selectedAccountId.value.isEmpty) {
        final nonCreditAccountIds = accountController.accounts
            .where((a) => a.type != 'credit')
            .map((a) => a.id)
            .toSet();
        double baseTotal = 0.0;
        for (final t in transactionController.transactions) {
          if (nonCreditAccountIds.contains(t.accountId)) {
            final amt = t.amount * t.exchangeRate;
            baseTotal += t.type == 'income' ? amt : -amt;
          }
        }
        totalBalance(baseTotal);
      } else {
        totalBalance(
          accountController.computeBalanceForAccount(selectedAccountId.value),
        );
      }

      // Calculate budget utilization
      budgetUtilization(budgetController.getOverallMonthlyUtilization());

      // Calculate goals progress (percentage of savings vs target)
      final totalTarget = goalController.getTotalTarget();
      final totalSavings = goalController.getTotalSavings();
      final gp = totalTarget > 0 ? (totalSavings / totalTarget) * 100 : 0.0;
      goalsProgress(gp);
    } catch (e) {
      throw Exception('Failed to load financial summary: $e');
    }
  }

  Future<void> _loadChartsData() async {
    try {
      await _loadIncomeExpenseChart();
      await _loadCategoryExpenseChart();
      await _loadAccountBalanceChart();
      await _loadMonthlyTrendChart();
    } catch (e) {
      throw Exception('Failed to load charts data: $e');
    }
  }

  Future<void> _loadIncomeExpenseChart() async {
    try {
      final transactionController = Get.find<TransactionController>();
      final dateRange = _getDateRangeForTimeRange(selectedTimeRange.value);

      // Group transactions by date
      final Map<DateTime, Map<String, double>> dailyData = {};

      for (final transaction in transactionController.transactions) {
        if (transaction.transactionDate.isAfter(dateRange['start']!) &&
            transaction.transactionDate.isBefore(
              dateRange['end']!.add(const Duration(days: 1)),
            )) {
          if (transaction.categoryId == 'transfer_in' ||
              transaction.categoryId == 'transfer_out') {
            continue;
          }
          final date = DateTime(
            transaction.transactionDate.year,
            transaction.transactionDate.month,
            transaction.transactionDate.day,
          );

          dailyData.putIfAbsent(date, () => {'income': 0.0, 'expense': 0.0});

          if (transaction.type == 'income') {
            dailyData[date]!['income'] =
                dailyData[date]!['income']! + transaction.amount;
          } else if (transaction.type == 'expense') {
            dailyData[date]!['expense'] =
                dailyData[date]!['expense']! + transaction.amount;
          }
        }
      }

      // Convert to chart format
      final chartData = dailyData.entries
          .map(
            (entry) => {
              'date': entry.key,
              'income': entry.value['income'],
              'expense': entry.value['expense'],
              'net': entry.value['income']! - entry.value['expense']!,
            },
          )
          .toList();

      // Sort by date
      chartData.sort(
        (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
      );

      incomeExpenseData.assignAll(chartData);
    } catch (e) {
      throw Exception('Failed to load income/expense chart: $e');
    }
  }

  Future<void> _loadCategoryExpenseChart() async {
    try {
      final transactionController = Get.find<TransactionController>();
      final categoryController = Get.find<CategoryController>();
      final dateRange = _getDateRangeForTimeRange(selectedTimeRange.value);

      // Group expenses by category
      final Map<String, double> categoryExpenses = {};

      for (final transaction in transactionController.transactions) {
        if (transaction.type == 'expense' &&
            transaction.transactionDate.isAfter(dateRange['start']!) &&
            transaction.transactionDate.isBefore(
              dateRange['end']!.add(const Duration(days: 1)),
            )) {
          if (transaction.categoryId == 'transfer_out') {
            continue;
          }
          categoryExpenses[transaction.categoryId] =
              (categoryExpenses[transaction.categoryId] ?? 0.0) +
              transaction.amount;
        }
      }

      // Convert to chart format with category details
      final chartData = categoryExpenses.entries.map((entry) {
        final category = categoryController.getCategoryById(entry.key);
        return {
          'categoryId': entry.key,
          'categoryName': category?.name ?? 'Unknown',
          'amount': entry.value,
          'color': category?.color ?? '#6B7280',
          'icon': category?.icon ?? 'category',
        };
      }).toList();

      // Sort by amount (highest first)
      chartData.sort(
        (a, b) => (b['amount'] as double).compareTo(a['amount'] as double),
      );

      categoryExpenseData.assignAll(chartData);
    } catch (e) {
      throw Exception('Failed to load category expense chart: $e');
    }
  }

  Future<void> _loadAccountBalanceChart() async {
    try {
      final accountController = Get.find<AccountController>();

      // Get all active accounts
      final activeAccounts = accountController.getActiveAccounts();

      // Convert to chart format
      final chartData = activeAccounts
          .map(
            (account) => {
              'accountId': account.id,
              'accountName': account.name,
              'balance': accountController.computeBalanceForAccount(account.id),
              'type': account.type,
            },
          )
          .toList();

      // Sort by balance (highest first)
      chartData.sort(
        (a, b) => (b['balance'] as double).compareTo(a['balance'] as double),
      );

      accountBalanceData.assignAll(chartData);
    } catch (e) {
      throw Exception('Failed to load account balance chart: $e');
    }
  }

  Future<void> _loadMonthlyTrendChart() async {
    try {
      final transactionController = Get.find<TransactionController>();

      // Get last 12 months of data
      final now = DateTime.now();
      final chartData = <Map<String, dynamic>>[];

      for (int i = 11; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final monthStart = DateTime(monthDate.year, monthDate.month, 1);
        final monthEnd = DateTime(
          monthDate.year,
          monthDate.month + 1,
          1,
        ).subtract(const Duration(days: 1));

        double income = 0.0;
        double expense = 0.0;

        for (final transaction in transactionController.transactions) {
          if (transaction.transactionDate.isAfter(
                monthStart.subtract(const Duration(days: 1)),
              ) &&
              transaction.transactionDate.isBefore(
                monthEnd.add(const Duration(days: 1)),
              )) {
            if (transaction.categoryId == 'transfer_in' ||
                transaction.categoryId == 'transfer_out') {
              continue;
            }
            if (transaction.type == 'income') {
              income += transaction.amount;
            } else if (transaction.type == 'expense') {
              expense += transaction.amount;
            }
          }
        }

        chartData.add({
          'month': monthDate,
          'monthName': _getMonthName(monthDate.month),
          'income': income,
          'expense': expense,
          'net': income - expense,
        });
      }

      monthlyTrendData.assignAll(chartData);
    } catch (e) {
      throw Exception('Failed to load monthly trend chart: $e');
    }
  }

  Future<void> _loadRecentData() async {
    try {
      final transactionController = Get.find<TransactionController>();

      // Get recent transactions
      final recent = transactionController.getRecentTransactions(limit: 10);
      recentTransactions.assignAll(recent);
    } catch (e) {
      throw Exception('Failed to load recent data: $e');
    }
  }

  Future<void> _loadAlerts() async {
    try {
      final budgetController = Get.find<BudgetController>();
      final goalController = Get.find<GoalController>();

      // Get budget alerts
      final budgetAlertsList = budgetController.getBudgetAlerts();
      budgetAlerts.assignAll(budgetAlertsList);

      // Get goals needing attention
      goalsNeedingAttention.assignAll([]);
    } catch (e) {
      throw Exception('Failed to load alerts: $e');
    }
  }

  Map<String, DateTime> _getDateRangeForTimeRange(String timeRange) {
    final now = DateTime.now();
    final sel = selectedMonth.value;

    switch (timeRange) {
      case 'week':
        return {'start': now.subtract(const Duration(days: 7)), 'end': now};
      case 'month':
        final start = DateTime(sel.year, sel.month, 1);
        final end = DateTime(
          sel.year,
          sel.month + 1,
          1,
        ).subtract(const Duration(days: 1));
        return {'start': start, 'end': end};
      case 'quarter':
        final quarterStartMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        return {'start': DateTime(now.year, quarterStartMonth, 1), 'end': now};
      case 'year':
        return {'start': DateTime(now.year, 1, 1), 'end': now};
      default:
        return {'start': DateTime(now.year, now.month, 1), 'end': now};
    }
  }

  String _getMonthName(int month) {
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
    return months[month - 1];
  }

  // Set time range and reload data
  void setTimeRange(String range) {
    selectedTimeRange(range);
    loadDashboardData();
  }

  // Set account filter and reload data
  void setAccountFilter(String accountId) {
    selectedAccountId(accountId);
    loadDashboardData();
  }

  // Clear all filters
  void clearFilters() {
    selectedTimeRange('month');
    selectedAccountId('');
    selectedMonth(DateTime(DateTime.now().year, DateTime.now().month, 1));
    loadDashboardData();
  }

  // Get top spending categories
  List<Map<String, dynamic>> getTopSpendingCategories({int limit = 5}) {
    final sortedData = List<Map<String, dynamic>>.from(categoryExpenseData)
      ..sort((a, b) => b['amount'].compareTo(a['amount']));
    return sortedData.take(limit).toList();
  }

  // Get spending by account
  Map<String, double> getSpendingByAccount() {
    final spending = <String, double>{};

    for (final data in incomeExpenseData) {
      if (data['expense'] > 0) {
        // This would need account-specific tracking in a real implementation
        spending['Total'] = (spending['Total'] ?? 0.0) + data['expense'];
      }
    }

    return spending;
  }

  // Get daily average spending
  double getDailyAverageSpending() {
    if (incomeExpenseData.isEmpty) return 0.0;

    final totalExpense = incomeExpenseData.fold(
      0.0,
      (sum, data) => sum + data['expense'],
    );
    return totalExpense / incomeExpenseData.length;
  }

  // Get highest spending day
  Map<String, dynamic>? getHighestSpendingDay() {
    if (incomeExpenseData.isEmpty) return null;

    return incomeExpenseData.reduce(
      (a, b) => a['expense'] > b['expense'] ? a : b,
    );
  }

  // Get budget vs actual spending
  Map<String, double> getBudgetVsActual() {
    final budgetController = Get.find<BudgetController>();
    final currentBudgets = budgetController.getCurrentMonthBudgets();

    double totalBudget = 0.0;
    double totalSpent = 0.0;

    for (final budget in currentBudgets) {
      totalBudget += budget.amount;
      totalSpent += budget.spent;
    }

    return {
      'budget': totalBudget,
      'spent': totalSpent,
      'remaining': totalBudget - totalSpent,
      'utilization': totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0.0,
    };
  }

  void prevMonth() {
    final current = selectedMonth.value;
    final prev = DateTime(current.year, current.month - 1, 1);
    selectedMonth(prev);
    loadDashboardData();
  }

  void nextMonth() {
    final current = selectedMonth.value;
    final next = DateTime(current.year, current.month + 1, 1);
    selectedMonth(next);
    loadDashboardData();
  }

  double get monthOpeningBalance {
    final transactionController = Get.find<TransactionController>();
    final accountController = Get.find<AccountController>();
    final start = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month,
      1,
    );
    double opening = 0.0;
    for (final t in transactionController.transactions) {
      final inAccount =
          selectedAccountId.value.isEmpty ||
          t.accountId == selectedAccountId.value;
      if (inAccount && t.transactionDate.isBefore(start)) {
        if (selectedAccountId.value.isEmpty) {
          final acc = accountController.getAccountById(t.accountId);
          if (acc != null && acc.type == 'credit') {
            continue;
          }
        }
        final amt = selectedAccountId.value.isEmpty
            ? (t.amount * t.exchangeRate)
            : t.amount;
        opening += t.type == 'income' ? amt : -amt;
      }
    }
    return opening;
  }

  double get monthClosingBalance {
    final transactionController = Get.find<TransactionController>();
    final accountController = Get.find<AccountController>();
    final start = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month,
      1,
    );
    final end = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month + 1,
      1,
    ).subtract(const Duration(days: 1));

    double delta = 0.0;
    for (final t in transactionController.transactions) {
      final inAccount =
          selectedAccountId.value.isEmpty ||
          t.accountId == selectedAccountId.value;
      final inRange =
          !t.transactionDate.isBefore(start) && !t.transactionDate.isAfter(end);
      if (inAccount && inRange) {
        if (selectedAccountId.value.isEmpty) {
          final acc = accountController.getAccountById(t.accountId);
          if (acc != null && acc.type == 'credit') {
            continue;
          }
        }
        final amt = selectedAccountId.value.isEmpty
            ? (t.amount * t.exchangeRate)
            : t.amount;
        delta += t.type == 'income' ? amt : -amt;
      }
    }
    return monthOpeningBalance + delta;
  }

  // Get financial health score (0-100)
  double getFinancialHealthScore() {
    double score = 50.0; // Base score

    // Budget utilization factor (0-20 points)
    final budgetData = getBudgetVsActual();
    final budgetUtilization = budgetData['utilization'] ?? 0.0;
    if (budgetUtilization <= 80) {
      score += 20;
    } else if (budgetUtilization <= 100) {
      score += 10;
    }

    // Savings rate factor (0-20 points)
    if (totalIncome.value > 0) {
      final savingsRate = (netCashFlow.value / totalIncome.value) * 100;
      if (savingsRate >= 20) {
        score += 20;
      } else if (savingsRate >= 10) {
        score += 10;
      }
    }

    // Debt-to-income ratio factor (0-10 points)
    final accountController = Get.find<AccountController>();
    final totalDebt = accountController.totalCreditBalance;
    if (totalIncome.value > 0) {
      final debtRatio = (totalDebt / totalIncome.value) * 100;
      if (debtRatio <= 30) {
        score += 10;
      } else if (debtRatio <= 50) {
        score += 5;
      }
    }

    return score.clamp(0.0, 100.0);
  }

  // Get financial insights
  List<String> getFinancialInsights() {
    final insights = <String>[];

    // Budget insights
    final budgetData = getBudgetVsActual();
    final budgetUtilization = budgetData['utilization'] ?? 0.0;

    if (budgetUtilization > 100) {
      insights.add(
        'Has excedido tu presupuesto mensual por ${Helpers.formatCurrency(budgetData['spent']! - budgetData['budget']!, 'USD')}',
      );
    } else if (budgetUtilization > 80) {
      insights.add(
        'Estás cerca de alcanzar tu límite de presupuesto mensual (${budgetUtilization.toStringAsFixed(1)}% utilizado)',
      );
    }

    // Cash flow insights
    if (netCashFlow.value < 0) {
      insights.add(
        'Tus gastos superan tus ingresos este mes. Considera reducir gastos discrecionales.',
      );
    } else if (netCashFlow.value > 0 && totalIncome.value > 0) {
      final savingsRate = (netCashFlow.value / totalIncome.value) * 100;
      if (savingsRate >= 20) {
        insights.add(
          '¡Buen trabajo! Estás ahorrando el ${savingsRate.toStringAsFixed(1)}% de tus ingresos.',
        );
      }
    }

    // Spending insights
    final topCategories = getTopSpendingCategories(limit: 3);
    if (topCategories.isNotEmpty) {
      insights.add(
        'Tu categoría con mayor gasto es ${topCategories[0]['categoryName']} (${Helpers.formatCurrency(topCategories[0]['amount']!, 'USD')}).',
      );
    }

    // Goal insights
    // Goal insights placeholder

    return insights;
  }

  // Export dashboard data
  Future<Map<String, dynamic>> exportDashboardData() async {
    try {
      final dashboardData = <String, dynamic>{};

      // Summary statistics
      dashboardData['summary'] = {
        'totalBalance': totalBalance.value,
        'totalIncome': totalIncome.value,
        'totalExpense': totalExpense.value,
        'netCashFlow': netCashFlow.value,
        'budgetUtilization': budgetUtilization.value,
        'goalsProgress': goalsProgress.value,
        'financialHealthScore': getFinancialHealthScore(),
        'timeRange': selectedTimeRange.value,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      // Charts data
      dashboardData['charts'] = {
        'incomeExpense': incomeExpenseData,
        'categoryExpenses': categoryExpenseData,
        'accountBalances': accountBalanceData,
        'monthlyTrend': monthlyTrendData,
      };

      // Recent data
      dashboardData['recent'] = {
        'transactions': recentTransactions.map((t) => t.toJson()).toList(),
        'budgetAlerts': budgetAlerts.map((b) => b.toJson()).toList(),
        'goalsNeedingAttention': goalsNeedingAttention
            .map((g) => g.toJson())
            .toList(),
      };

      // Insights
      dashboardData['insights'] = getFinancialInsights();

      return dashboardData;
    } catch (e) {
      return {};
    }
  }
}

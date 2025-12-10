import 'package:get/get.dart';
import '../models/budget_model.dart';
import '../database/database_service.dart';
import '../utils/helpers.dart';
import 'transaction_controller.dart';
import 'auth_controller.dart';
import 'category_controller.dart';

class BudgetController extends GetxController {
  final DatabaseService _databaseService = Get.put(DatabaseService());

  var budgets = <Budget>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadBudgets();
  }

  Future<void> loadBudgets() async {
    try {
      isLoading(true);
      final loadedBudgets = await _databaseService.getAllBudgets();
      budgets.assignAll(loadedBudgets);

      // Calculate spent amounts for each budget
      await _calculateSpentAmounts();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load budgets: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> addBudget(Budget budget) async {
    try {
      isLoading(true);

      // Generate ID if not provided
      if (budget.id.isEmpty) {
        budget = budget.copyWith(id: Helpers.generateId());
      }

      // Set current month/year if not provided
      // Ensure monthYear is set
      if (budget.monthYear.isEmpty) {
        final now = DateTime.now();
        budget = budget.copyWith(monthYear: Helpers.formatMonthYear(now));
      }

      // Calculate spent amount
      final spentAmount = await _calculateSpentForCategory(
        budget.categoryId,
        budget.monthYear,
      );
      budget = budget.copyWith(spent: spentAmount);

      // Add to database
      await _databaseService.insertBudget(budget);

      // Update local list
      budgets.add(budget);

      Get.snackbar('Success', 'Budget added successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add budget: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateBudget(Budget budget) async {
    try {
      isLoading(true);

      // Calculate spent amount
      final spentAmount = await _calculateSpentForCategory(
        budget.categoryId,
        budget.monthYear,
      );
      budget = budget.copyWith(spent: spentAmount);

      // Update in database
      await _databaseService.updateBudget(budget);

      // Update local list
      final index = budgets.indexWhere((b) => b.id == budget.id);
      if (index != -1) {
        budgets[index] = budget;
      }

      Get.snackbar('Success', 'Budget updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update budget: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> deleteBudget(String budgetId) async {
    try {
      isLoading(true);

      // Delete from database
      await _databaseService.deleteBudget(budgetId);

      // Update local list
      budgets.removeWhere((b) => b.id == budgetId);

      Get.snackbar('Success', 'Budget deleted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete budget: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<double> _calculateSpentForCategory(
    String categoryId,
    String monthYear,
  ) async {
    try {
      final transactionController = Get.find<TransactionController>();

      // Get all expense transactions for this category in the specified month/year
      final categoryTransactions = transactionController.transactions.where((
        t,
      ) {
        final m = Helpers.formatMonthYear(t.transactionDate);
        return t.categoryId == categoryId &&
            t.type == 'expense' &&
            m == monthYear;
      }).toList();

      // Sum up all expenses
      double total = 0.0;
      for (final t in categoryTransactions) {
        total += t.amount;
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  Future<void> _calculateSpentAmounts() async {
    try {
      for (int i = 0; i < budgets.length; i++) {
        final budget = budgets[i];
        final spentAmount = await _calculateSpentForCategory(
          budget.categoryId,
          budget.monthYear,
        );

        if (spentAmount != budget.spent) {
          final updatedBudget = budget.copyWith(spent: spentAmount);
          budgets[i] = updatedBudget;

          // Update in database
          await _databaseService.updateBudget(updatedBudget);
        }
      }
    } catch (e) {
      // Silently handle calculation errors
    }
  }

  // Get budget by ID
  Budget? getBudgetById(String budgetId) {
    try {
      return budgets.firstWhere((b) => b.id == budgetId);
    } catch (e) {
      return null;
    }
  }

  // Get budget by category and month/year
  Budget? getBudgetByCategoryAndMonth(String categoryId, int month, int year) {
    try {
      final monthYear = Helpers.formatMonthYear(DateTime(year, month));
      return budgets.firstWhere(
        (b) => b.categoryId == categoryId && b.monthYear == monthYear,
      );
    } catch (e) {
      return null;
    }
  }

  // Get budgets for current month
  List<Budget> getCurrentMonthBudgets() {
    final now = DateTime.now();
    final my = Helpers.formatMonthYear(now);
    return budgets.where((b) => b.monthYear == my).toList();
  }

  // Get budgets for specific month/year
  List<Budget> getBudgetsForMonth(int month, int year) {
    final my = Helpers.formatMonthYear(DateTime(year, month));
    return budgets.where((b) => b.monthYear == my).toList();
  }

  // Get budgets by category
  List<Budget> getBudgetsByCategory(String categoryId) {
    return budgets.where((b) => b.categoryId == categoryId).toList();
  }

  // Calculate budget utilization percentage
  double getBudgetUtilization(Budget budget) {
    if (budget.amount <= 0) return 0.0;
    return (budget.spent / budget.amount) * 100;
  }

  // Check if budget is exceeded
  bool isBudgetExceeded(Budget budget) {
    return budget.spent > budget.amount;
  }

  // Get remaining budget amount
  double getRemainingBudget(Budget budget) {
    return budget.amount - budget.spent;
  }

  // Get budget status color based on utilization
  String getBudgetStatusColor(Budget budget) {
    final utilization = getBudgetUtilization(budget);

    if (utilization >= 100) {
      return '#EF4444'; // Red - exceeded
    } else if (utilization >= 80) {
      return '#F59E0B'; // Yellow - warning
    } else {
      return '#10B981'; // Green - on track
    }
  }

  // Get total budget for current month
  double getTotalMonthlyBudget() {
    final currentBudgets = getCurrentMonthBudgets();
    return currentBudgets.fold(0.0, (sum, b) => sum + b.amount);
  }

  // Get total spent for current month
  double getTotalMonthlySpent() {
    final currentBudgets = getCurrentMonthBudgets();
    return currentBudgets.fold(0.0, (sum, b) => sum + b.spent);
  }

  // Get overall budget utilization for current month
  double getOverallMonthlyUtilization() {
    final totalBudget = getTotalMonthlyBudget();
    if (totalBudget <= 0) return 0.0;

    final totalSpent = getTotalMonthlySpent();
    return (totalSpent / totalBudget) * 100;
  }

  // Create budget for current month
  Future<void> createCurrentMonthBudget({
    required String categoryId,
    required double amount,
    bool rollover = false,
  }) async {
    try {
      final now = DateTime.now();

      // Check if budget already exists for this category and month
      final existingBudget = getBudgetByCategoryAndMonth(
        categoryId,
        now.month,
        now.year,
      );
      if (existingBudget != null) {
        Get.snackbar(
          'Warning',
          'Budget already exists for this category and month',
        );
        return;
      }

      final budget = Budget(
        id: Helpers.generateId(),
        userId: Get.find<AuthController>().currentUserId,
        categoryId: categoryId,
        amount: amount,
        monthYear: Helpers.formatMonthYear(now),
        spent: 0.0,
        remaining: 0.0,
        rolloverFromPrevious: 0.0,
        createdAt: now,
      );

      await addBudget(budget);
    } catch (e) {
      throw Exception('Failed to create current month budget: $e');
    }
  }

  // Copy budget to next month
  Future<void> copyBudgetToNextMonth(String budgetId) async {
    try {
      final budget = getBudgetById(budgetId);
      if (budget == null) {
        throw Exception('Budget not found');
      }

      // Calculate next month/year
      final parts = budget.monthYear.split('-');
      int month = int.parse(parts[1]);
      int year = int.parse(parts[0]);
      int nextMonth = month + 1;
      int nextYear = year;

      if (nextMonth > 12) {
        nextMonth = 1;
        nextYear++;
      }

      // Check if budget already exists for next month
      final existingBudget = getBudgetByCategoryAndMonth(
        budget.categoryId,
        nextMonth,
        nextYear,
      );
      if (existingBudget != null) {
        Get.snackbar('Warning', 'Budget already exists for next month');
        return;
      }

      // Calculate rollover amount if enabled
      double rolloverAmount = 0.0;
      // Using remaining field as rollover base
      if (budget.rolloverFromPrevious > 0) {
        rolloverAmount = budget.rolloverFromPrevious;
      }

      final newBudget = Budget(
        id: Helpers.generateId(),
        userId: Get.find<AuthController>().currentUserId,
        categoryId: budget.categoryId,
        amount: budget.amount + rolloverAmount,
        monthYear: Helpers.formatMonthYear(DateTime(nextYear, nextMonth)),
        spent: 0.0,
        remaining: 0.0,
        rolloverFromPrevious: rolloverAmount,
        createdAt: DateTime.now(),
      );

      await addBudget(newBudget);

      Get.snackbar('Success', 'Budget copied to next month');
    } catch (e) {
      Get.snackbar('Error', 'Failed to copy budget to next month: $e');
    }
  }

  // Get budget alerts (exceeded or near limit)
  List<Budget> getBudgetAlerts() {
    final currentBudgets = getCurrentMonthBudgets();
    return currentBudgets.where((b) {
      final utilization = getBudgetUtilization(b);
      return utilization >= 80; // Alert if 80% or more utilized
    }).toList();
  }

  // Get budget recommendations based on spending history
  Future<Map<String, double>> getBudgetRecommendations() async {
    try {
      final recommendations = <String, double>{};
      final categoryController = Get.find<CategoryController>();
      final expenseCategories = categoryController.getExpenseCategories();

      for (final category in expenseCategories) {
        // Calculate average spending for this category over last 3 months
        final now = DateTime.now();
        double totalSpent = 0.0;
        int monthsCounted = 0;

        for (int i = 1; i <= 3; i++) {
          final checkDate = now.subtract(Duration(days: 30 * i));
          final spentInMonth = await _calculateSpentForCategory(
            category.id,
            Helpers.formatMonthYear(checkDate),
          );

          if (spentInMonth > 0) {
            totalSpent += spentInMonth;
            monthsCounted++;
          }
        }

        if (monthsCounted > 0) {
          final averageSpent = totalSpent / monthsCounted;
          // Recommend 10% buffer above average
          recommendations[category.id] = averageSpent * 1.1;
        }
      }

      return recommendations;
    } catch (e) {
      return {};
    }
  }

  // Export budget data
  Future<Map<String, dynamic>> exportBudgetData() async {
    try {
      final budgetData = <String, dynamic>{};

      // Current month summary
      budgetData['currentMonth'] = {
        'month': DateTime.now().month,
        'year': DateTime.now().year,
        'totalBudget': getTotalMonthlyBudget(),
        'totalSpent': getTotalMonthlySpent(),
        'remaining': getTotalMonthlyBudget() - getTotalMonthlySpent(),
        'utilization': getOverallMonthlyUtilization(),
      };

      // Individual budgets
      budgetData['budgets'] = budgets.map((budget) {
        final categoryController = Get.find<CategoryController>();
        final category = categoryController.getCategoryById(budget.categoryId);

        return {
          'id': budget.id,
          'categoryId': budget.categoryId,
          'categoryName': category?.name ?? 'Unknown',
          'amount': budget.amount,
          'spent': budget.spent,
          'remaining': getRemainingBudget(budget),
          'utilization': getBudgetUtilization(budget),
          'monthYear': budget.monthYear,
          'rollover_from_previous': budget.rolloverFromPrevious,
          'statusColor': getBudgetStatusColor(budget),
        };
      }).toList();

      return budgetData;
    } catch (e) {
      return {};
    }
  }
}

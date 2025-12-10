import 'package:get/get.dart';
import '../models/category_model.dart';
import '../database/database_service.dart';
import 'auth_controller.dart';
import 'transaction_controller.dart';
import '../utils/helpers.dart';

class CategoryController extends GetxController {
  final DatabaseService _databaseService = Get.put(DatabaseService());

  var categories = <Category>[].obs;
  var isLoading = false.obs;

  // Predefined categories for income and expenses
  final List<Map<String, String>> predefinedIncome = [
    {
      'id': 'salary',
      'name': 'Salary',
      'icon': 'attach_money',
      'color': '#10B981',
    },
    {
      'id': 'freelance',
      'name': 'Freelance',
      'icon': 'work',
      'color': '#10B981',
    },
    {
      'id': 'investment',
      'name': 'Investment',
      'icon': 'trending_up',
      'color': '#10B981',
    },
    {
      'id': 'business',
      'name': 'Business',
      'icon': 'business',
      'color': '#10B981',
    },
    {'id': 'gift', 'name': 'Gift', 'icon': 'card_giftcard', 'color': '#10B981'},
    {
      'id': 'other_income',
      'name': 'Other Income',
      'icon': 'more_horiz',
      'color': '#10B981',
    },
    {
      'id': 'transfer_in',
      'name': 'Traspaso (Entrada)',
      'icon': 'compare_arrows',
      'color': '#6B7280',
    },
  ];

  final List<Map<String, String>> predefinedExpense = [
    {
      'id': 'food',
      'name': 'Food & Dining',
      'icon': 'restaurant',
      'color': '#EF4444',
    },
    {
      'id': 'transport',
      'name': 'Transportation',
      'icon': 'directions_car',
      'color': '#EF4444',
    },
    {
      'id': 'shopping',
      'name': 'Shopping',
      'icon': 'shopping_cart',
      'color': '#EF4444',
    },
    {
      'id': 'entertainment',
      'name': 'Entertainment',
      'icon': 'movie',
      'color': '#EF4444',
    },
    {
      'id': 'bills',
      'name': 'Bills & Utilities',
      'icon': 'receipt',
      'color': '#EF4444',
    },
    {
      'id': 'healthcare',
      'name': 'Healthcare',
      'icon': 'local_hospital',
      'color': '#EF4444',
    },
    {
      'id': 'education',
      'name': 'Education',
      'icon': 'school',
      'color': '#EF4444',
    },
    {'id': 'travel', 'name': 'Travel', 'icon': 'flight', 'color': '#EF4444'},
    {'id': 'home', 'name': 'Home & Garden', 'icon': 'home', 'color': '#EF4444'},
    {
      'id': 'personal',
      'name': 'Personal Care',
      'icon': 'spa',
      'color': '#EF4444',
    },
    {
      'id': 'other_expense',
      'name': 'Other Expense',
      'icon': 'more_horiz',
      'color': '#EF4444',
    },
    {
      'id': 'transfer_out',
      'name': 'Traspaso (Salida)',
      'icon': 'compare_arrows',
      'color': '#6B7280',
    },
  ];

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      isLoading(true);

      // Check if categories exist, if not create predefined ones
      final existingCategories = await _databaseService.getAllCategories();

      if (existingCategories.isEmpty) {
        // Create predefined categories
        await _createPredefinedCategories();
      }

      final loadedCategories = await _databaseService.getAllCategories();
      categories.assignAll(loadedCategories);
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar las categorías: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> _createPredefinedCategories() async {
    try {
      final userId = Get.find<AuthController>().currentUserId;
      for (final data in [...predefinedIncome, ...predefinedExpense]) {
        final isIncome = predefinedIncome.contains(data);
        final category = Category(
          id: data['id']!,
          userId: userId,
          name: data['name']!,
          type: isIncome ? 'income' : 'expense',
          icon: data['icon'] ?? 'category',
          color: data['color'] ?? '#6B7280',
          isCustom: false,
          createdAt: DateTime.now(),
        );
        await _databaseService.insertCategory(category);
      }
    } catch (e) {
      throw Exception('Failed to create predefined categories: $e');
    }
  }

  Future<void> addCategory(Category category) async {
    try {
      isLoading(true);

      // Generate ID if not provided
      if (category.id.isEmpty) {
        category = category.copyWith(id: Helpers.generateId());
      }

      // Add to database
      await _databaseService.insertCategory(category);

      // Update local list
      categories.add(category);

      Get.snackbar('Éxito', 'Categoría agregada correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo agregar la categoría: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      isLoading(true);

      // Update in database
      await _databaseService.updateCategory(category);

      // Update local list
      final index = categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        categories[index] = category;
      }

      Get.snackbar('Éxito', 'Categoría actualizada correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo actualizar la categoría: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      isLoading(true);

      // Check if category is used in transactions
      final transactionController = Get.find<TransactionController>();
      final hasTransactions = transactionController.transactions.any(
        (t) => t.categoryId == categoryId,
      );

      if (hasTransactions) {
        Get.snackbar(
          'Aviso',
          'No es posible eliminar la categoría con transacciones existentes',
        );
        return;
      }

      // Delete from database
      await _databaseService.deleteCategory(categoryId);

      // Update local list
      categories.removeWhere((c) => c.id == categoryId);

      Get.snackbar('Éxito', 'Categoría eliminada correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo eliminar la categoría: $e');
    } finally {
      isLoading(false);
    }
  }

  // Get categories by type
  List<Category> getIncomeCategories() {
    return categories.where((c) => c.type == 'income').toList();
  }

  List<Category> getExpenseCategories() {
    return categories.where((c) => c.type == 'expense').toList();
  }

  // Get category by ID
  Category? getCategoryById(String categoryId) {
    try {
      return categories.firstWhere((c) => c.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  // Get category by name
  Category? getCategoryByName(String name) {
    try {
      return categories.firstWhere(
        (c) => c.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  // Search categories
  List<Category> searchCategories(String query) {
    if (query.isEmpty) return categories;

    return categories
        .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Get most used categories (based on transaction count)
  Future<List<Category>> getMostUsedCategories({int limit = 5}) async {
    try {
      final transactionController = Get.find<TransactionController>();
      final categoryUsage = <String, int>{};

      // Count transactions per category
      for (final transaction in transactionController.transactions) {
        categoryUsage[transaction.categoryId] =
            (categoryUsage[transaction.categoryId] ?? 0) + 1;
      }

      // Sort by usage count
      final sortedCategories = categoryUsage.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Get category objects
      final result = <Category>[];
      for (final entry in sortedCategories.take(limit)) {
        final category = getCategoryById(entry.key);
        if (category != null) {
          result.add(category);
        }
      }

      return result;
    } catch (e) {
      return [];
    }
  }

  // Get category statistics
  Future<Map<String, double>> getCategoryTotals() async {
    try {
      final transactionController = Get.find<TransactionController>();
      final totals = <String, double>{};

      for (final transaction in transactionController.transactions) {
        final categoryId = transaction.categoryId;
        final amount = transaction.amount;

        if (transaction.type == 'expense') {
          totals[categoryId] = (totals[categoryId] ?? 0) - amount;
        } else {
          totals[categoryId] = (totals[categoryId] ?? 0) + amount;
        }
      }

      return totals;
    } catch (e) {
      return {};
    }
  }

  // Create custom category
  Future<void> createCustomCategory({
    required String name,
    required String type,
    String icon = 'category',
    String color = '#6B7280',
  }) async {
    try {
      final userId = Get.find<AuthController>().currentUserId;
      final customCategory = Category(
        id: Helpers.generateId(),
        userId: userId,
        name: name,
        type: type,
        icon: icon,
        color: color,
        isCustom: true,
        createdAt: DateTime.now(),
      );

      await addCategory(customCategory);
    } catch (e) {
      throw Exception('Failed to create custom category: $e');
    }
  }

  // Reset to default categories
  Future<void> resetToDefaults() async {
    try {
      isLoading(true);

      // Delete all custom categories
      final customCategories = categories.where((c) => c.isCustom).toList();
      for (final category in customCategories) {
        await _databaseService.deleteCategory(category.id);
      }

      // Reload categories
      await loadCategories();

      Get.snackbar(
        'Éxito',
        'Categorías restablecidas a los valores predeterminados',
      );
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron restablecer las categorías: $e');
    } finally {
      isLoading(false);
    }
  }
}

import 'package:get/get.dart';
import '../models/goal_model.dart';
import '../database/database_service.dart';
import '../utils/helpers.dart';

class GoalController extends GetxController {
  final DatabaseService _databaseService = Get.find<DatabaseService>();

  var goals = <Goal>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadGoals();
  }

  Future<void> loadGoals() async {
    try {
      isLoading(true);
      final loaded = await _databaseService.getAllGoals();
      goals.assignAll(loaded);
    } finally {
      isLoading(false);
    }
  }

  Future<void> addGoal(Goal goal) async {
    isLoading(true);
    try {
      if (goal.id.isEmpty) {
        goal = goal.copyWith(id: Helpers.generateId());
      }
      await _databaseService.insertGoal(goal);
      goals.add(goal);
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateGoal(Goal goal) async {
    isLoading(true);
    try {
      await _databaseService.updateGoal(goal);
      final i = goals.indexWhere((g) => g.id == goal.id);
      if (i != -1) goals[i] = goal;
    } finally {
      isLoading(false);
    }
  }

  Future<void> deleteGoal(String id) async {
    isLoading(true);
    try {
      await _databaseService.deleteGoal(id);
      goals.removeWhere((g) => g.id == id);
    } finally {
      isLoading(false);
    }
  }

  Goal? getGoalById(String id) {
    try {
      return goals.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Goal> getActiveGoals() => goals.where((g) => g.isActive).toList();
  List<Goal> getCompletedGoals() => goals.where((g) => g.isCompleted).toList();

  double getTotalSavings() => goals.fold(0.0, (s, g) => s + g.currentAmount);
  double getTotalTarget() => goals.fold(0.0, (s, g) => s + g.targetAmount);
}

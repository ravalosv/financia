import 'package:get/get.dart';
import '../models/models.dart';
import '../database/database_service.dart';
import '../utils/helpers.dart';

class AuthController extends GetxController {
  final Rx<User?> currentUser = Rx<User?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isAuthenticated = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    isLoading.value = true;
    try {
      final users = DatabaseService.getUsersBox().values.toList();
      
      if (users.isNotEmpty) {
        currentUser.value = users.first;
        isAuthenticated.value = true;
      } else {
        isAuthenticated.value = false;
      }
    } catch (e) {
      isAuthenticated.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register({
    required String email,
    required String name,
    required String password,
  }) async {
    isLoading.value = true;
    try {
      final user = User(
        id: Helpers.generateId(),
        email: email,
        name: name,
        currency: 'USD',
        biometricEnabled: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await DatabaseService.getUsersBox().put(user.id, user);
      
      currentUser.value = user;
      isAuthenticated.value = true;
      
      Get.offAllNamed('/dashboard');
    } catch (e) {
      Get.snackbar('Error', 'Failed to register user: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    isLoading.value = true;
    try {
      final users = DatabaseService.getUsersBox().values.toList();
      final user = users.firstWhere(
        (u) => u.email == email,
        orElse: () => throw Exception('User not found'),
      );

      currentUser.value = user;
      isAuthenticated.value = true;
      
      Get.offAllNamed('/dashboard');
    } catch (e) {
      Get.snackbar('Error', 'Invalid credentials');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    currentUser.value = null;
    isAuthenticated.value = false;
    Get.offAllNamed('/login');
  }

  Future<void> updateUser({
    String? name,
    String? currency,
    bool? biometricEnabled,
  }) async {
    if (currentUser.value == null) return;

    try {
      final updatedUser = currentUser.value!.copyWith(
        name: name,
        currency: currency,
        biometricEnabled: biometricEnabled,
        updatedAt: DateTime.now(),
      );

      await DatabaseService.getUsersBox().put(updatedUser.id, updatedUser);
      
      currentUser.value = updatedUser;
    } catch (e) {
      Get.snackbar('Error', 'Failed to update user: $e');
    }
  }

  String get currentUserId => currentUser.value?.id ?? '';
  String get currentUserCurrency => currentUser.value?.currency ?? 'USD';
}

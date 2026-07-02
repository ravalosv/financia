import 'package:get/get.dart';
import '../models/models.dart';
import '../database/database_service.dart';
import '../security/device_auth_service.dart';
import '../utils/helpers.dart';

class AuthController extends GetxController {
  final Rx<User?> currentUser = Rx<User?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isAuthenticated = false.obs;
  final DeviceAuthService _deviceAuthService = DeviceAuthService();

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
        isAuthenticated.value = false;
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
        biometricEnabled: true,
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

  Future<void> login({required String email, required String password}) async {
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

  Future<void> loginWithDeviceAuth() async {
    isLoading.value = true;
    try {
      if (currentUser.value == null) {
        final users = DatabaseService.getUsersBox().values.toList();
        if (users.isEmpty) {
          Get.snackbar('Autenticación', 'No hay usuario registrado');
          return;
        }
        currentUser.value = users.first;
      }

      if (!(currentUser.value?.biometricEnabled ?? false)) {
        Get.snackbar(
          'Autenticación',
          'Activa biometría/PIN en Configuraciones para usar este acceso',
        );
        return;
      }

      final ok = await _deviceAuthService.authenticate(
        reason: 'Autentica para ingresar a Financia',
      );
      if (!ok) {
        Get.snackbar('Autenticación', 'Acceso denegado');
        return;
      }

      isAuthenticated.value = true;
      Get.offAllNamed('/dashboard');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo autenticar: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> authenticateOnAppEntry() async {
    isLoading.value = true;
    try {
      if (currentUser.value == null) {
        final users = DatabaseService.getUsersBox().values.toList();
        if (users.isEmpty) {
          return false;
        }
        currentUser.value = users.first;
      }

      if (!(currentUser.value?.biometricEnabled ?? true)) {
        isAuthenticated.value = true;
        return true;
      }

      final ok = await _deviceAuthService.authenticate(
        reason: 'Autentica para ingresar a Financia',
      );
      isAuthenticated.value = ok;
      return ok;
    } catch (e) {
      isAuthenticated.value = false;
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> confirmDeviceAuth(String reason) {
    return _deviceAuthService.authenticate(reason: reason);
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

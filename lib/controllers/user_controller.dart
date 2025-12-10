import 'package:get/get.dart';
import '../models/models.dart';
import 'auth_controller.dart';

class UserController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();

  User? get currentUser => _authController.currentUser.value;
  String get userId => _authController.currentUserId;
  String get userCurrency => _authController.currentUserCurrency;

  Future<void> updateProfile({
    String? name,
    String? currency,
    bool? biometricEnabled,
  }) async {
    await _authController.updateUser(
      name: name,
      currency: currency,
      biometricEnabled: biometricEnabled,
    );
  }

  Future<void> changeCurrency(String newCurrency) async {
    await updateProfile(currency: newCurrency);
  }

  Future<void> toggleBiometric(bool enabled) async {
    await updateProfile(biometricEnabled: enabled);
  }
}

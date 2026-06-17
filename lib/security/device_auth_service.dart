import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class DeviceAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> authenticate({required String reason}) async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      if (!isSupported) return false;

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}

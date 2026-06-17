import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class CardSecurityService {
  static const String _storageKey = 'financia_cards_encryption_key_v1';

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<bool> authenticate({required String reason}) async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      if (!isSupported) {
        return false;
      }

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

  Future<String> encryptText(String plainText) async {
    if (plainText.isEmpty) return '';
    final key = await _getOrCreateKey();
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  Future<String> decryptText(String cipherText) async {
    if (cipherText.isEmpty) return '';
    final parts = cipherText.split(':');
    if (parts.length != 2) {
      throw const FormatException('Formato de cifrado invalido');
    }

    final key = await _getOrCreateKey();
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final iv = encrypt.IV.fromBase64(parts[0]);
    return encrypter.decrypt64(parts[1], iv: iv);
  }

  Future<encrypt.Key> _getOrCreateKey() async {
    final existing = await _secureStorage.read(key: _storageKey);
    if (existing != null && existing.isNotEmpty) {
      return encrypt.Key(base64Decode(existing));
    }

    final bytes = Uint8List.fromList(
      List<int>.generate(32, (_) => Random.secure().nextInt(256)),
    );
    await _secureStorage.write(key: _storageKey, value: base64Encode(bytes));
    return encrypt.Key(bytes);
  }
}

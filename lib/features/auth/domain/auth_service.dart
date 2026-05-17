import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:pump_alignment/core/constants/app_constants.dart';

class AuthService {
  const AuthService._();

  /// Generates the expected license key for a given [deviceId].
  static String generateLicenseKey(String deviceId) {
    final key = utf8.encode(AppConstants.licenseSecret);
    final message = utf8.encode(deviceId.trim());
    final hmac = Hmac(sha256, key);
    return hmac.convert(message).toString().toUpperCase();
  }

  static bool isKeyValid({
    required String deviceId,
    required String licenseKey,
  }) {
    final expected = generateLicenseKey(deviceId);
    return expected == licenseKey.trim().toUpperCase();
  }
}
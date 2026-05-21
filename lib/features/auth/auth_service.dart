import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart'; // kIsWeb + defaultTargetPlatform
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const String _baseUrl =
      'https://pumpalignment.theframeworkstudios.com/api';
  static const String _appSecret = 'MyPumpApp_S3cr3t_2026';

  // ─── Private HTTP Helper ───────────────────────────────────────────────────
  Future<Map<String, dynamic>> _post(
      String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'X-App-Secret': _appSecret,
        },
        body: jsonEncode(body),
      )
          .timeout(const Duration(seconds: 15));

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ─── Device ID Helper (Web-Safe) ───────────────────────────────────────────
  // dart:io BILKUL import mat karo — web build pe compile hi nahi hota
  // kIsWeb → 'web'
  // defaultTargetPlatform → Android/iOS detect karta hai bina dart:io ke
  Future<String> _getDeviceId() async {
    if (kIsWeb) return 'web';

    try {
      final deviceInfo = DeviceInfoPlugin();

      if (defaultTargetPlatform == TargetPlatform.android) {
        final info = await deviceInfo.androidInfo;
        return info.id;
      }

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final info = await deviceInfo.iosInfo;
        return info.identifierForVendor ?? 'ios-unknown';
      }
    } catch (_) {}

    return 'unknown-device';
  }

  // ─── Login ─────────────────────────────────────────────────────────────────
  Future<String?> loginUser(String identity, String password) async {
    String deviceId = 'web';
    try {
      deviceId = await _getDeviceId();
    } catch (_) {}

    final result = await _post('login.php', {
      'identity': identity,
      'password': password,
      'device_id': deviceId,
    });

    if (result['success'] == true) {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setInt('auth_user_id', result['user_id']);
      await prefs.setString('auth_username', result['username'] ?? '');

      if (result['session_token'] != null) {
        await prefs.setString('auth_session_token', result['session_token']);
      }
      await prefs.setBool(
          'flutter.lic_is_premium', result['is_premium'] ?? false);
      if (result['premium_expiry'] != null) {
        await prefs.setString(
            'flutter.lic_premium_expiry', result['premium_expiry']);
      }
      if (result['license_key'] != null) {
        await prefs.setString(
            'flutter.lic_license_key', result['license_key']);
      }

      return null;
    }

    return result['message'] ?? 'Login failed';
  }

  // ─── Register ──────────────────────────────────────────────────────────────
  Future<String?> registerUser(
      String username, String email, String phone, String password) async {
    final result = await _post('register.php', {
      'username': username,
      'email': email,
      'phone': phone,
      'password': password,
    });

    if (result['success'] == true) return null;
    return result['message'] ?? 'Registration failed';
  }

  // ─── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_user_id');
    await prefs.remove('auth_username');
    await prefs.remove('auth_email');
    await prefs.remove('auth_session_token');
    await prefs.setBool('flutter.lic_is_premium', false);
  }
}
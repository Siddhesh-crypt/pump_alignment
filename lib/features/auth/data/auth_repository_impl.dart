import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:pump_alignment/core/constants/app_constants.dart';
import 'package:pump_alignment/features/auth/domain/auth_repository.dart';
import 'package:pump_alignment/features/auth/domain/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepositoryImpl implements AuthRepository {
  final DeviceInfoPlugin _deviceInfo;
  final SharedPreferences _prefs;

  const AuthRepositoryImpl({
    required DeviceInfoPlugin deviceInfo,
    required SharedPreferences prefs,
  }) : _deviceInfo = deviceInfo,
      _prefs = prefs;

  @override
  Future<String> getDeviceId() async {
    // Return cached if available to avoid redundant platform calls
    final cached = _prefs.getString(AppConstants.prefDeviceId);
    if (cached != null && cached.isNotEmpty) return cached;

    String id = "UNKNOWN_DEVICE";

    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      id = info.id;
    }else if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      id = info.identifierForVendor ?? 'IOS_NO_ID';
    }

    await _prefs.setString(AppConstants.prefDeviceId, id);
    return id;
  }

  @override
  Future<bool> isUnlocked() async {
    // TODO: implement isUnlocked
    return _prefs.getBool(AppConstants.prefIsUnlocked) ?? false;
  }

  @override
  Future<bool> validateAndUnlock({required String deviceId, required String licenseKey}) async {
    // TODO: implement validateAndUnlock
    final valid = AuthService.isKeyValid(deviceId: deviceId, licenseKey: licenseKey);
    if (valid) {
      await _prefs.setBool(AppConstants.prefIsUnlocked, true);
    }
    return valid;

  }
}
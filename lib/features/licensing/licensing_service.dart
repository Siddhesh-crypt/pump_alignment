import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _C {
  static const baseUrl = 'https://pumpalignment.theframeworkstudios.com/api';
  static const appSecret = 'MyPumpApp_S3cr3t_2026';
  static const razorpayKeyId = 'rzp_live_SqSLvZuzGH7OSW';

  // TESTING CONFIGURATION
  static const razorpayAmount = 100; // 100 paise = 1 Rupee
  static const subscriptionMinutes = 1; // 5 minutes validity for testing

  static const prefIsPremium = 'lic_is_premium';
  static const prefPremiumExpiry = 'lic_premium_expiry';
  static const prefTrialCount = 'lic_trial_count';
  static const prefDeviceId = 'lic_device_id';
  static const prefLicenseKey = 'lic_license_key';
  static const prefTrialUsedToken = 'lic_has_used_trial_token';
}

class DeviceStatus {
  final bool isPremium;
  final int trialCount;
  final String? licenseKey;
  final bool allowed;

  const DeviceStatus({
    required this.isPremium,
    required this.trialCount,
    this.licenseKey,
    this.allowed = true,
  });
}

class LicensingService {
  LicensingService._();
  static final LicensingService instance = LicensingService._();

  Razorpay? _razorpay;
  VoidCallback? onPaymentSuccess;
  VoidCallback? onPaymentFailed;

  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_C.prefDeviceId);
    if (cached != null && cached.isNotEmpty) return cached;

    final plugin = DeviceInfoPlugin();
    String id = 'UNKNOWN';

    try {
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        id = info.id;
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        id = info.identifierForVendor ?? 'IOS_NO_ID';
      }
    } catch (e) {
      debugPrint('Error getting device ID: $e');
    }

    await prefs.setString(_C.prefDeviceId, id);
    return id;
  }

  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('${_C.baseUrl}/$endpoint'),
            headers: {
              'Content-Type': 'application/json',
              'X-App-Secret': _C.appSecret,
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // MINUTES EXPIRY HELPER
  Future<void> _enforceExpiry(SharedPreferences prefs) async {
    bool isPremium = prefs.getBool(_C.prefIsPremium) ?? false;
    String? expiryStr = prefs.getString(_C.prefPremiumExpiry);

    if (isPremium && expiryStr != null) {
      if (DateTime.now().isAfter(DateTime.parse(expiryStr))) {
        await prefs.setBool(_C.prefIsPremium, false); // Expired!
      }
    }
  }

  Future<DeviceStatus> fetchDeviceStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await _enforceExpiry(prefs);

    final deviceId = await getDeviceId();
    final result = await _post('device_status.php', {'device_id': deviceId});

    if (result['success'] == true) {
      final isPremium = result['is_premium'] as bool? ?? false;
      final trialCount = result['trial_count'] as int? ?? 0;
      final licenseKey = result['license_key'] as String?;
      final serverExpiry = result['premium_expiry'] as String?;

      await prefs.setBool(_C.prefIsPremium, isPremium);
      await prefs.setInt(_C.prefTrialCount, trialCount);
      if (licenseKey != null)
        await prefs.setString(_C.prefLicenseKey, licenseKey);
      if (serverExpiry != null)
        await prefs.setString(_C.prefPremiumExpiry, serverExpiry);

      await _enforceExpiry(prefs);

      return DeviceStatus(
        isPremium: prefs.getBool(_C.prefIsPremium) ?? false,
        trialCount: trialCount,
        licenseKey: licenseKey,
      );
    }

    return DeviceStatus(
      isPremium: prefs.getBool(_C.prefIsPremium) ?? false,
      trialCount: prefs.getInt(_C.prefTrialCount) ?? 0,
      licenseKey: prefs.getString(_C.prefLicenseKey),
    );
  }

  Future<DeviceStatus> startFreeTrial() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = await getDeviceId();
    final result = await _post('start_trial.php', {'device_id': deviceId});

    if (result['success'] == true) {
      final trialCount = result['trial_count'] as int? ?? 5;
      final licenseKey = result['license_key'] as String?;

      await prefs.setInt(_C.prefTrialCount, trialCount);
      await prefs.setBool(_C.prefTrialUsedToken, true);
      if (licenseKey != null)
        await prefs.setString(_C.prefLicenseKey, licenseKey);

      return DeviceStatus(
        isPremium: false,
        trialCount: trialCount,
        licenseKey: licenseKey,
      );
    }
    throw Exception(result['message'] ?? 'Failed to initialize free trials.');
  }

  Future<DeviceStatus> consumeTrial() async {
    final prefs = await SharedPreferences.getInstance();
    await _enforceExpiry(prefs);
    final deviceId = await getDeviceId();

    if (prefs.getBool(_C.prefIsPremium) == true) {
      return const DeviceStatus(isPremium: true, trialCount: 0, allowed: true);
    }

    final result = await _post('use_trial.php', {'device_id': deviceId});

    if (result['success'] == true) {
      final allowed = result['allowed'] as bool? ?? false;
      final trialCount = result['trial_count'] as int? ?? 0;
      final isPremium = result['is_premium'] as bool? ?? false;

      await prefs.setInt(_C.prefTrialCount, trialCount);
      await prefs.setBool(_C.prefIsPremium, isPremium);
      await _enforceExpiry(prefs);

      return DeviceStatus(
        isPremium: prefs.getBool(_C.prefIsPremium) ?? false,
        trialCount: trialCount,
        allowed: allowed,
      );
    }

    final localTrials = prefs.getInt(_C.prefTrialCount) ?? 0;
    if (localTrials > 0) {
      final newCount = localTrials - 1;
      await prefs.setInt(_C.prefTrialCount, newCount);
      return DeviceStatus(
        isPremium: false,
        trialCount: newCount,
        allowed: true,
      );
    }

    return const DeviceStatus(isPremium: false, trialCount: 0, allowed: false);
  }

  Future<bool> simulateMockPayment() async {
    final deviceId = await getDeviceId();
    final result = await _post('dummy_unlock.php', {'device_id': deviceId});

    if (result['success'] == true && result['is_premium'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_C.prefIsPremium, true);
      await prefs.setString(_C.prefLicenseKey, 'PUMP-MOCK-UPGRADED');

      // Changed to minutes
      final expiryDate = DateTime.now().add(
        const Duration(minutes: _C.subscriptionMinutes),
      );
      await prefs.setString(_C.prefPremiumExpiry, expiryDate.toIso8601String());
      return true;
    }
    return false;
  }

  void initRazorpay() {
    if (!kIsWeb && Platform.isIOS) return;
    if (_razorpay != null) return;
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  void disposeRazorpay() {
    _razorpay?.clear();
    _razorpay = null;
  }

  Future<void> openPaywall(BuildContext context) async {
    if (!kIsWeb && Platform.isIOS) return;
    if (_razorpay == null) initRazorpay();

    try {
      final deviceId = await getDeviceId();
      final orderResult = await _post('create_order.php', {
        'device_id': deviceId,
      });

      if (orderResult['success'] != true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to init payment: ${orderResult['message']}',
              ),
            ),
          );
        }
        return;
      }

      final String orderId = orderResult['order_id'];
      final options = {
        'key': _C.razorpayKeyId,
        'amount': _C.razorpayAmount,
        'name': 'Pump Alignment Pro',
        'description': '5 Minutes Test Access', // Updated for testing
        'order_id': orderId,
        'prefill': {'contact': '', 'email': ''},
        'theme': {'color': '#1A6E5A'},
      };

      _razorpay!.open(options);
    } catch (e) {
      debugPrint('Razorpay open error: $e');
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    final deviceId = await getDeviceId();
    final result = await _post('verify_payment.php', {
      'device_id': deviceId,
      'razorpay_order_id': response.orderId ?? '',
      'razorpay_payment_id': response.paymentId ?? '',
      'razorpay_signature': response.signature ?? '',
    });

    if (result['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_C.prefIsPremium, true);

      // Successfully paid -> Set 5 Minutes Expiry
      final expiryDate = DateTime.now().add(
        const Duration(minutes: _C.subscriptionMinutes),
      );
      await prefs.setString(_C.prefPremiumExpiry, expiryDate.toIso8601String());

      if (result['license_key'] != null) {
        await prefs.setString(_C.prefLicenseKey, result['license_key']);
      }
      onPaymentSuccess?.call();
    } else {
      onPaymentFailed?.call();
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    onPaymentFailed?.call();
  }

  void _onExternalWallet(ExternalWalletResponse response) {}
}

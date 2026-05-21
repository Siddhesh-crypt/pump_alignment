import 'dart:convert';
import 'dart:io' show Platform;
// Imports section me ye line add karein:
import 'web_interop_stub.dart' if (dart.library.js) 'web_interop_web.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
  static const subscriptionMinutes = 5;

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
  final DateTime? expiryDate;

  const DeviceStatus({
    required this.isPremium,
    required this.trialCount,
    this.licenseKey,
    this.allowed = true,
    this.expiryDate,
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

    if (kIsWeb) {
      // Fingerprint: 15+ browser signals → SHA-256 → stable unique ID
      final webId = await getBrowserDeviceFingerprint();
      await prefs.setString(_C.prefDeviceId, webId);
      return webId;
    }

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

  // ── Human-readable label for phpMyAdmin display ──
  // Web:     "Chrome 124 • Windows 10/11 • 1920×1080 • Asia/Kolkata • 📱Mobile"
  // Android: "Android • Samsung Galaxy / Pixel"
  // iOS:     "iOS • iPhone"
  Future<String> getDeviceLabel() async {
    if (kIsWeb) {
      return getBrowserDeviceLabel(); // web_interop_web.dart se aata hai
    }
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        final brand = info.brand.isNotEmpty ? info.brand : 'Android';
        final model = info.model.isNotEmpty ? info.model : '';
        return 'Android • $brand $model'.trim();
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        final name = info.name ?? 'iPhone';
        final model = info.utsname.machine ?? '';
        return 'iOS • $name ($model)'.trim();
      }
    } catch (_) {}
    return 'Native App';
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

  DateTime? _getExpiry(SharedPreferences prefs) {
    final expStr = prefs.getString(_C.prefPremiumExpiry);
    return expStr != null ? DateTime.parse(expStr) : null;
  }

  Future<void> _enforceExpiry(SharedPreferences prefs) async {
    bool isPremium = prefs.getBool(_C.prefIsPremium) ?? false;
    DateTime? expiryDate = _getExpiry(prefs);

    if (isPremium && expiryDate != null) {
      if (DateTime.now().isAfter(expiryDate)) {
        await prefs.setBool(_C.prefIsPremium, false);
      }
    }
  }

  Future<DeviceStatus> fetchDeviceStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await _enforceExpiry(prefs);

    final userId = prefs.getInt('auth_user_id');
    final sessionToken = prefs.getString('auth_session_token');

    // Agar user logged in hi nahi hai, toh server ko hit karne ki zaroorat nahi
    if (userId == null) {
      return DeviceStatus(isPremium: false, trialCount: 0, expiryDate: null);
    }

    final result = await _post('device_status.php', {
      'user_id': userId,
      'session_token': sessionToken,
    });

    if (result['force_logout'] == true) {
      // Someone else logged in! Wipe everything.
      await prefs.remove('auth_user_id');
      await prefs.remove('auth_username');
      await prefs.remove('auth_email');
      await prefs.remove('auth_session_token');
      await prefs.setBool(_C.prefIsPremium, false);

      throw Exception('SESSION_EXPIRED');
    }

    if (result['success'] == true) {
      final isPremium = result['is_premium'] as bool? ?? false;
      final licenseKey = result['license_key'] as String?;
      final serverExpiry = result['premium_expiry'] as String?;

      await prefs.setBool(_C.prefIsPremium, isPremium);
      if (licenseKey != null)
        await prefs.setString(_C.prefLicenseKey, licenseKey);
      if (serverExpiry != null)
        await prefs.setString(_C.prefPremiumExpiry, serverExpiry);

      await _enforceExpiry(prefs);
    }

    return DeviceStatus(
      isPremium: prefs.getBool(_C.prefIsPremium) ?? false,
      trialCount: 0, // Trials ab humesha 0 rahenge
      licenseKey: prefs.getString(_C.prefLicenseKey),
      expiryDate: _getExpiry(prefs),
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
        expiryDate: _getExpiry(prefs),
      );
    }
    throw Exception(result['message'] ?? 'Failed to initialize free trials.');
  }

  Future<DeviceStatus> consumeTrial() async {
    final prefs = await SharedPreferences.getInstance();
    await _enforceExpiry(prefs);
    final deviceId = await getDeviceId();

    if (prefs.getBool(_C.prefIsPremium) == true) {
      return DeviceStatus(
        isPremium: true,
        trialCount: 0,
        allowed: true,
        expiryDate: _getExpiry(prefs),
      );
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
        expiryDate: _getExpiry(prefs),
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
        expiryDate: _getExpiry(prefs),
      );
    }

    return DeviceStatus(
      isPremium: false,
      trialCount: 0,
      allowed: false,
      expiryDate: _getExpiry(prefs),
    );
  }

  Future<bool> simulateMockPayment() async {
    final deviceId = await getDeviceId();
    final result = await _post('dummy_unlock.php', {'device_id': deviceId});

    if (result['success'] == true && result['is_premium'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_C.prefIsPremium, true);
      await prefs.setString(_C.prefLicenseKey, 'PUMP-MOCK-UPGRADED');

      final expiryDate = DateTime.now().add(
        const Duration(minutes: _C.subscriptionMinutes),
      );
      await prefs.setString(_C.prefPremiumExpiry, expiryDate.toIso8601String());
      return true;
    }
    return false;
  }

  void initRazorpay() {
    if (kIsWeb) return; // Web compiles don't initialize mobile plugins
    if (Platform.isIOS) return;

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

      // WEB COMPILATION ROUTE: Directly calls index.html JavaScript engine
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final userId =
            prefs.getInt('auth_user_id') ?? 0; // Fetch current logged-in ID

        openRazorpayWebCheckoutSafe(
          _C.razorpayKeyId,
          _C.razorpayAmount,
          orderId,
          'Pump Alignment Pro',
          '5 Minutes Test Access',
          _C.appSecret,
          _C.baseUrl,
          userId, // ── Yaha last me userId pass karein ──
        );
        return;
      }

      // NATIVE MOBILE ROUTE
      if (Platform.isIOS) return;
      if (_razorpay == null) initRazorpay();

      final options = {
        'key': _C.razorpayKeyId,
        'amount': _C.razorpayAmount,
        'name': 'Pump Alignment Pro',
        'description': '5 Minutes Test Access',
        'order_id': orderId,
        'prefill': {'contact': '', 'email': ''},
        'theme': {'color': '#1A6E5A'},
      };

      _razorpay!.open(options);
    } catch (e) {
      debugPrint('Razorpay checkout execution error: $e');
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    final deviceId = await getDeviceId();
    final prefs = await SharedPreferences.getInstance();

    // ── MOBILE SYNC FIX: Fetch logged-in user ID ──
    final userId = prefs.getInt('auth_user_id');

    final result = await _post('verify_payment.php', {
      'device_id': deviceId,
      'user_id':
          userId, // Yeh line add ki gayi hai taaki Android apna account ID bheje
      'razorpay_order_id': response.orderId ?? '',
      'razorpay_payment_id': response.paymentId ?? '',
      'razorpay_signature': response.signature ?? '',
    });

    if (result['success'] == true) {
      await prefs.setBool(_C.prefIsPremium, true);

      if (result['premium_expiry'] != null) {
        await prefs.setString(_C.prefPremiumExpiry, result['premium_expiry']);
      } else {
        final fallbackExpiry = DateTime.now().add(
          const Duration(minutes: _C.subscriptionMinutes),
        );
        await prefs.setString(
          _C.prefPremiumExpiry,
          fallbackExpiry.toIso8601String(),
        );
      }

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

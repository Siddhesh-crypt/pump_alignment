import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../licensing_service.dart';
import 'package:pump_alignment/features/licensing/presentation/providers/licensing_state.dart';

class LicensingNotifier extends StateNotifier<LicensingState>
    with WidgetsBindingObserver {
  final LicensingService _service;
  Timer? _heartbeatTimer;

  LicensingNotifier(this._service) : super(const LicensingState()) {
    WidgetsBinding.instance.addObserver(this);
    refreshStatus();
    _startHeartbeat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkSessionPulse();
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        checkSessionPulse();
      }
    });
  }

  Future<void> refreshStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final status = await _service.fetchDeviceStatus();
      state = state.copyWith(
        isPremium: status.isPremium,
        activeLicenseKey: status.licenseKey,
        expiryDate: status.expiryDate,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> checkSessionPulse() async {
    try {
      final status = await _service.fetchDeviceStatus();
      if (status.isPremium != state.isPremium) {
        state = state.copyWith(isPremium: status.isPremium);
      }
    } catch (e) {
      _handleError(e);
    }
  }

  // ── FIX: Correct BuildContext typing for PaywallScreen call ──
  Future<void> initiateRealPayment(BuildContext context) async {
    if (!kIsWeb && Platform.isIOS) return;

    state = state.copyWith(isPaymentLoading: true, clearError: true);

    try {
      await _service.openPaywall(context);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Payment initiation failed.');
    } finally {
      if (mounted) {
        state = state.copyWith(isPaymentLoading: false);
      }
    }
  }

  void _handleError(dynamic e) {
    final errorStr = e.toString();
    if (errorStr.contains('SESSION_EXPIRED') || errorStr.contains('force_logout')) {
      _forceLogout();
    } else {
      state = state.copyWith(isLoading: false, errorMessage: 'Network Error.');
    }
  }

  Future<void> _forceLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    state = const LicensingState(
      isLoading: false,
      errorMessage: 'Security Alert: You have been logged out.',
    );
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final licensingServiceProvider = Provider<LicensingService>(
      (ref) => LicensingService.instance,
);

final licensingProvider =
StateNotifierProvider<LicensingNotifier, LicensingState>(
      (ref) => LicensingNotifier(ref.watch(licensingServiceProvider)),
);
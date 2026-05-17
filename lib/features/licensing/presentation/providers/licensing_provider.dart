import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../licensing_service.dart';

// ── Licensing State ───────────────────────────────────────────────────────────
class LicensingState {
  final bool _isPremium;
  final int trialCount;
  final bool isLoading;
  final bool isMockLoading;
  final bool isPaymentLoading;
  final bool hasActivatedTrialBefore;
  final String? activeLicenseKey;
  final String? errorMessage;

  const LicensingState({
    bool isPremium = false,
    this.trialCount = 0,
    this.isLoading = true,
    this.isMockLoading = false,
    this.isPaymentLoading = false,
    this.hasActivatedTrialBefore = false,
    this.activeLicenseKey,
    this.errorMessage,
  }) : _isPremium = isPremium;

  bool get isPremium {
    if (!kIsWeb && Platform.isIOS) {
      return true;
    }
    return _isPremium;
  }

  bool get canCalculate => isPremium || trialCount > 0;

  LicensingState copyWith({
    bool? isPremium,
    int? trialCount,
    bool? isLoading,
    bool? isMockLoading,
    bool? isPaymentLoading,
    bool? hasActivatedTrialBefore,
    String? activeLicenseKey,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LicensingState(
      isPremium: isPremium ?? this._isPremium,
      trialCount: trialCount ?? this.trialCount,
      isLoading: isLoading ?? this.isLoading,
      isMockLoading: isMockLoading ?? this.isMockLoading,
      isPaymentLoading: isPaymentLoading ?? this.isPaymentLoading,
      hasActivatedTrialBefore:
          hasActivatedTrialBefore ?? this.hasActivatedTrialBefore,
      activeLicenseKey: activeLicenseKey ?? this.activeLicenseKey,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class LicensingNotifier extends StateNotifier<LicensingState> {
  final LicensingService _service;

  LicensingNotifier(this._service) : super(const LicensingState()) {
    refreshStatus();
  }

  Future<void> refreshStatus() async {
    state = state.copyWith(isLoading: true);
    final prefs = await SharedPreferences.getInstance();
    final localTrialToken = prefs.getBool('lic_has_used_trial_token') ?? false;

    try {
      final status = await _service.fetchDeviceStatus();

      final bool trialUsed =
          localTrialToken ||
          (status.licenseKey != null) ||
          (status.trialCount > 0);

      state = state.copyWith(
        isPremium: status.isPremium,
        trialCount: status.trialCount,
        activeLicenseKey: status.licenseKey,
        hasActivatedTrialBefore: trialUsed,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasActivatedTrialBefore: localTrialToken,
        activeLicenseKey: prefs.getString('lic_license_key'),
        errorMessage: 'Could not reach server. Using cached data.',
      );
    }
  }

  Future<void> activateFreeTrialLicense() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _service.startFreeTrial();
      state = state.copyWith(
        isPremium: false,
        trialCount: result.trialCount,
        activeLicenseKey: result.licenseKey,
        hasActivatedTrialBefore: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception:', ''),
      );
    }
  }

  Future<bool> consumeTrialAndCheck() async {
    if (state.isPremium) return true;

    final result = await _service.consumeTrial();
    state = state.copyWith(
      isPremium: result.isPremium,
      trialCount: result.trialCount,
      clearError: true,
    );
    return result.allowed;
  }

  Future<void> initiateRealPayment(dynamic context) async {
    if (!kIsWeb && Platform.isIOS) return;

    state = state.copyWith(isPaymentLoading: true, clearError: true);
    await _service.openPaywall(context);
    if (mounted) {
      state = state.copyWith(isPaymentLoading: false);
    }
  }

  Future<bool> simulateMockPayment() async {
    state = state.copyWith(isMockLoading: true, clearError: true);
    try {
      final success = await _service.simulateMockPayment();
      if (success) {
        state = state.copyWith(isMockLoading: false);
        await refreshStatus();
        return true;
      } else {
        state = state.copyWith(
          isMockLoading: false,
          errorMessage: 'Mock payment failed. Check server logs.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isMockLoading: false,
        errorMessage: 'Network error: $e',
      );
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

// ── Providers ─────────────────────────────────────────────────────────────────
final licensingServiceProvider = Provider<LicensingService>(
  (ref) => LicensingService.instance,
);
final licensingProvider =
    StateNotifierProvider<LicensingNotifier, LicensingState>((ref) {
      return LicensingNotifier(ref.watch(licensingServiceProvider));
    });

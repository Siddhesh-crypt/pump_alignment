import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
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
  final DateTime? expiryDate;
  final String? warningMessage;

  const LicensingState({
    bool isPremium = false,
    this.trialCount = 0,
    this.isLoading = true,
    this.isMockLoading = false,
    this.isPaymentLoading = false,
    this.hasActivatedTrialBefore = false,
    this.activeLicenseKey,
    this.errorMessage,
    this.expiryDate,
    this.warningMessage,
  }) : _isPremium = isPremium;

  bool get isPremium {
    if (!kIsWeb && Platform.isIOS) return true;
    return _isPremium;
  }

  bool get canCalculate => isPremium || trialCount > 0;

  // ── NEW GETTER: Bache huye din ya minute calculate karne ke liye ──
  String get timeRecencyLeft {
    if (expiryDate == null) return '';
    final difference = expiryDate!.difference(DateTime.now());

    if (difference.isNegative) return 'Expired';

    // Agar difference 1 din se zyada hai toh Days dikhao, nahi toh Minutes dikhao (Testing ke liye)
    if (difference.inDays >= 1) {
      return '${difference.inDays} days left';
    } else {
      final minutes = difference.inMinutes;
      if (minutes <= 0) {
        return '${difference.inSeconds} secs left';
      }
      return '$minutes mins left';
    }
  }

  LicensingState copyWith({
    bool? isPremium,
    int? trialCount,
    bool? isLoading,
    bool? isMockLoading,
    bool? isPaymentLoading,
    bool? hasActivatedTrialBefore,
    String? activeLicenseKey,
    String? errorMessage,
    DateTime? expiryDate,
    String? warningMessage,
    bool clearError = false,
    bool clearWarning = false,
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
      expiryDate: expiryDate ?? this.expiryDate,
      warningMessage: clearWarning
          ? null
          : (warningMessage ?? this.warningMessage),
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class LicensingNotifier extends StateNotifier<LicensingState> {
  final LicensingService _service;
  Timer? _expiryTimer;
  Timer? _warningTimer;
  Timer? _uiRefreshTimer; // To keep the 'minutes/seconds left' badge live on UI

  LicensingNotifier(this._service) : super(const LicensingState()) {
    refreshStatus();
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _warningTimer?.cancel();
    _uiRefreshTimer?.cancel();
    super.dispose();
  }

  void _scheduleExpiryTimer() {
    _expiryTimer?.cancel();
    _warningTimer?.cancel();
    _uiRefreshTimer?.cancel();

    if (!kIsWeb && Platform.isIOS) return;

    if (state.isPremium && state.expiryDate != null) {
      final now = DateTime.now();
      if (state.expiryDate!.isAfter(now)) {
        final duration = state.expiryDate!.difference(now);

        // UI live update karne ke liye timer (testing me seconds/minutes live ghat-te dikhenge)
        _uiRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
          if (mounted) state = state.copyWith();
        });

        // 3 Days before lock warning
        final warningThreshold = const Duration(days: 3);

        if (duration > warningThreshold) {
          _warningTimer = Timer(duration - warningThreshold, () {
            if (mounted)
              state = state.copyWith(
                warningMessage:
                    '⏳ Notice: Your Premium Access will expire in 3 days.',
              );
          });
        } else if (duration > const Duration(seconds: 0)) {
          _warningTimer = Timer(const Duration(seconds: 2), () {
            if (mounted) {
              final displayTime = duration.inDays > 0
                  ? '${duration.inDays} days'
                  : '${duration.inMinutes} minutes';
              state = state.copyWith(
                warningMessage:
                    '⏳ Notice: Your Premium Access is expiring in $displayTime!',
              );
            }
          });
        }

        _expiryTimer = Timer(duration, () {
          refreshStatus();
        });
      } else {
        refreshStatus();
      }
    }
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
        expiryDate: status.expiryDate,
        hasActivatedTrialBefore: trialUsed,
        isLoading: false,
        clearError: true,
      );
      _scheduleExpiryTimer();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasActivatedTrialBefore: localTrialToken,
        errorMessage: 'Network Error.',
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
        expiryDate: result.expiryDate,
        hasActivatedTrialBefore: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> consumeTrialAndCheck() async {
    if (!kIsWeb && Platform.isIOS) return true;
    if (state.isPremium && state.expiryDate != null) {
      if (DateTime.now().isAfter(state.expiryDate!)) {
        await refreshStatus();
        return false;
      }
      return true;
    }
    final result = await _service.consumeTrial();
    state = state.copyWith(
      isPremium: result.isPremium,
      trialCount: result.trialCount,
      expiryDate: result.expiryDate,
      clearError: true,
    );
    _scheduleExpiryTimer();
    return result.allowed;
  }

  Future<void> initiateRealPayment(dynamic context) async {
    if (!kIsWeb && Platform.isIOS) return;
    state = state.copyWith(isPaymentLoading: true, clearError: true);
    await _service.openPaywall(context);
    if (mounted) state = state.copyWith(isPaymentLoading: false);
  }

  void clearError() => state = state.copyWith(clearError: true);
  void clearWarning() => state = state.copyWith(clearWarning: true);
}

final licensingServiceProvider = Provider<LicensingService>(
  (ref) => LicensingService.instance,
);
final licensingProvider =
    StateNotifierProvider<LicensingNotifier, LicensingState>(
      (ref) => LicensingNotifier(ref.watch(licensingServiceProvider)),
    );

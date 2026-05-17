import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pump_alignment/features/auth/data/auth_repository_impl.dart';
import 'package:pump_alignment/features/auth/domain/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Infrastructure providers ──────────────────────────────────────────────────

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in main()');
});

final deviceInfoProvider = Provider<DeviceInfoPlugin>((ref) {
  return DeviceInfoPlugin();
});

// ── Repository provider ───────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    deviceInfo: ref.watch(deviceInfoProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  );
});

// ── Auth State ────────────────────────────────────────────────────────────────

class AuthState {
  final bool isUnlocked;
  final String deviceId;
  final bool isLoading;
  final String? errorMessage;
  final bool isValidating;

  const AuthState({
    this.isUnlocked = false,
    this.deviceId = '',
    this.isLoading = true,
    this.errorMessage,
    this.isValidating = false,
  });

  AuthState copyWith({
    bool? isUnlocked,
    String? deviceId,
    bool? isLoading,
    String? errorMessage,
    bool? isValidating,
    bool clearError = false,
  }) {
    return AuthState(
      isUnlocked: isUnlocked ?? this.isUnlocked,
      deviceId: deviceId ?? this.deviceId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isValidating: isValidating ?? this.isValidating,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);
    try {
      final results = await Future.wait([
        _repository.getDeviceId(),
        _repository.isUnlocked(),
      ]);
      state = AuthState(
        deviceId: results[0] as String,
        isUnlocked: results[1] as bool,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to initialize device: $e',
      );
    }
  }

  Future<void> unlock(String licenseKey) async {
    if (state.deviceId.isEmpty) return;
    state = state.copyWith(isValidating: true, clearError: true);
    try {
      final success = await _repository.validateAndUnlock(
        deviceId: state.deviceId,
        licenseKey: licenseKey,
      );
      if (success) {
        state = state.copyWith(isUnlocked: true, isValidating: false);
      } else {
        state = state.copyWith(
          isValidating: false,
          errorMessage: 'Invalid license key. Please check and try again.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isValidating: false,
        errorMessage: 'Unlock failed: $e',
      );
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

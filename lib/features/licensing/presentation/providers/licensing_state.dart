// lib/features/licensing/presentation/providers/licensing_state.dart
class LicensingState {
  final bool isPremium;
  final bool isLoading;
  final bool isPaymentLoading;
  final String? activeLicenseKey;
  final String? errorMessage;
  final DateTime? expiryDate;
  final String? warningMessage;

  const LicensingState({
    this.isPremium = false,
    this.isLoading = true,
    this.isPaymentLoading = false,
    this.activeLicenseKey,
    this.errorMessage,
    this.expiryDate,
    this.warningMessage,
  });

  LicensingState copyWith({
    bool? isPremium,
    bool? isLoading,
    bool? isPaymentLoading,
    String? activeLicenseKey,
    String? errorMessage,
    DateTime? expiryDate,
    String? warningMessage,
    bool clearError = false,
  }) {
    return LicensingState(
      isPremium: isPremium ?? this.isPremium,
      isLoading: isLoading ?? this.isLoading,
      isPaymentLoading: isPaymentLoading ?? this.isPaymentLoading,
      activeLicenseKey: activeLicenseKey ?? this.activeLicenseKey,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      expiryDate: expiryDate ?? this.expiryDate,
      warningMessage: warningMessage ?? this.warningMessage,
    );
  }

  // UI ke liye time helper
  String get timeRecencyLeft {
    if (expiryDate == null) return '';
    final diff = expiryDate!.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inDays >= 1) return '${diff.inDays}d left';
    if (diff.inHours >= 1) return '${diff.inHours}h left';
    return '${diff.inMinutes}m left';
  }
}
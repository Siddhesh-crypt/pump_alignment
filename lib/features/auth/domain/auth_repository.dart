abstract interface class AuthRepository {
  Future<String> getDeviceId();

  Future<bool> isUnlocked();

  Future<bool> validateAndUnlock({
    required String deviceId,
    required String licenseKey,
  });
}
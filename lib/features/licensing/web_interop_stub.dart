// lib/features/licensing/web_interop_stub.dart

Future<String> getBrowserDeviceFingerprint() async {
  throw UnsupportedError('Browser fingerprint only available on web');
}

// Native platforms pe device label alag se handle hoti hai (AuthService me)
String getBrowserDeviceLabel() {
  throw UnsupportedError('getBrowserDeviceLabel only available on web');
}

void openRazorpayWebCheckoutSafe(
  String keyId,
  int amount,
  String orderId,
  String name,
  String desc,
  String appSecret,
  String baseUrl,
  int userId,
) {
  throw UnsupportedError('This platform does not support web checkout');
}

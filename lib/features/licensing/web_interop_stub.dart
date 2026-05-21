// lib/features/licensing/web_interop_stub.dart

void openRazorpayWebCheckoutSafe(
    String keyId,
    int amount,
    String orderId,
    String name,
    String desc,
    String appSecret,
    String baseUrl,
    int userId, // ── 8th Argument Added ──
    ) {
  throw UnsupportedError('This platform does not support web checkout');
}
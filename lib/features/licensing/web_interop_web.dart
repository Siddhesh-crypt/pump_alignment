// lib/features/licensing/web_interop_web.dart
import 'dart:js' as js;

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
  js.context.callMethod('openRazorpayWebCheckout', [
    keyId, amount, orderId, name, desc, appSecret, baseUrl, userId // ── JS ko pass kiya ──
  ]);
}
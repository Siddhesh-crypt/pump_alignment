// lib/features/licensing/web_interop_web.dart
// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'dart:html' as html;
import 'dart:convert';
import 'package:crypto/crypto.dart';

// ══════════════════════════════════════════════════════
// 1. BROWSER FINGERPRINT — unique hash (for DB identity)
// ══════════════════════════════════════════════════════
Future<String> getBrowserDeviceFingerprint() async {
  final components = <String>[];

  // Canvas GPU rendering signature
  try {
    final canvas = html.CanvasElement(width: 200, height: 50);
    final ctx = canvas.context2D;
    ctx.textBaseline = 'top';
    ctx.font = '14px Arial';
    ctx.fillStyle = '#f60';
    ctx.fillRect(125, 1, 62, 20);
    ctx.fillStyle = '#069';
    ctx.fillText('BrowserFP🔐', 2, 15);
    ctx.fillStyle = 'rgba(102, 204, 0, 0.7)';
    ctx.fillText('BrowserFP🔐', 4, 17);
    components.add('canvas:${canvas.toDataUrl()}');
  } catch (_) {
    components.add('canvas:blocked');
  }

  // WebGL renderer (Graphics card)
  try {
    final canvas = html.CanvasElement();
    final gl = canvas.getContext('webgl') ?? canvas.getContext('experimental-webgl');
    if (gl != null) {
      final debugInfo = (gl as dynamic).getExtension('WEBGL_debug_renderer_info');
      if (debugInfo != null) {
        final renderer = (gl as dynamic).getParameter(debugInfo['UNMASKED_RENDERER_WEBGL']);
        final vendor   = (gl as dynamic).getParameter(debugInfo['UNMASKED_VENDOR_WEBGL']);
        components.add('webgl_renderer:$renderer');
        components.add('webgl_vendor:$vendor');
      }
    }
  } catch (_) {
    components.add('webgl:blocked');
  }

  // Screen
  final screen = html.window.screen;
  if (screen != null) {
    components.add('screen:${screen.width}x${screen.height}x${screen.colorDepth}');
    components.add('pixel_ratio:${html.window.devicePixelRatio}');
  }

  // Timezone
  try {
    final tz = js.context['Intl'] != null
        ? (js.JsObject.fromBrowserObject(js.context['Intl']))
        .callMethod('DateTimeFormat')
        .callMethod('resolvedOptions')['timeZone']
        .toString()
        : DateTime.now().timeZoneName;
    components.add('tz:$tz');
  } catch (_) {
    components.add('tz:${DateTime.now().timeZoneName}');
  }

  // Language + Platform + Hardware
  components.add('lang:${html.window.navigator.language ?? 'unknown'}');
  components.add('platform:${html.window.navigator.platform ?? 'unknown'}');

  try {
    final nav = js.JsObject.fromBrowserObject(html.window.navigator);
    components.add('cores:${nav['hardwareConcurrency']}');
    components.add('memory:${nav['deviceMemory']}');
    components.add('touch:${nav['maxTouchPoints']}');
  } catch (_) {}

  // UserAgent core (version numbers stripped)
  final ua = html.window.navigator.userAgent ?? '';
  final uaCore = ua.replaceAll(RegExp(r'[\d.]+'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
  components.add('ua:$uaCore');

  // Hash everything → short unique ID
  final digest = sha256.convert(utf8.encode(components.join('|')));
  final shortHash = digest.toString().substring(0, 16).toUpperCase();
  return 'WEB-$shortHash';
}

// ══════════════════════════════════════════════════════
// 2. HUMAN-READABLE DEVICE LABEL — phpMyAdmin me clearly dikhega
//    Example: "Chrome 124 • Windows 11 • 1920×1080 • Asia/Kolkata"
// ══════════════════════════════════════════════════════
String getBrowserDeviceLabel() {
  final parts = <String>[];

  // Browser name + version
  final ua = html.window.navigator.userAgent ?? '';
  parts.add(_parseBrowserName(ua));

  // OS name
  parts.add(_parseOsName(ua));

  // Screen resolution
  final screen = html.window.screen;
  if (screen != null) {
    parts.add('${screen.width}×${screen.height}');
  }

  // Timezone (shows country/city → tells you where the user is)
  try {
    final tz = js.context['Intl'] != null
        ? (js.JsObject.fromBrowserObject(js.context['Intl']))
        .callMethod('DateTimeFormat')
        .callMethod('resolvedOptions')['timeZone']
        .toString()
        : DateTime.now().timeZoneName;
    parts.add(tz);
  } catch (_) {
    parts.add(DateTime.now().timeZoneName);
  }

  // Mobile/Desktop indicator
  final isMobile = ua.contains(RegExp(r'Mobile|Android|iPhone|iPad', caseSensitive: false));
  parts.add(isMobile ? '📱Mobile' : '🖥️Desktop');

  return parts.where((p) => p.isNotEmpty).join(' • ');
}

// Helper: "Chrome 124" / "Firefox 125" / "Safari 17" / "Edge 123"
String _parseBrowserName(String ua) {
  // Edge (Chromium-based) — check karo Chrome se pehle
  final edgeMatch = RegExp(r'Edg/(\d+)').firstMatch(ua);
  if (edgeMatch != null) return 'Edge ${edgeMatch.group(1)}';

  // Chrome
  final chromeMatch = RegExp(r'Chrome/(\d+)').firstMatch(ua);
  if (chromeMatch != null && !ua.contains('Chromium')) return 'Chrome ${chromeMatch.group(1)}';

  // Firefox
  final ffMatch = RegExp(r'Firefox/(\d+)').firstMatch(ua);
  if (ffMatch != null) return 'Firefox ${ffMatch.group(1)}';

  // Safari (Chrome nahi hona chahiye)
  final safariMatch = RegExp(r'Version/(\d+)').firstMatch(ua);
  if (safariMatch != null && ua.contains('Safari')) return 'Safari ${safariMatch.group(1)}';

  // Samsung Browser
  final samsungMatch = RegExp(r'SamsungBrowser/(\d+)').firstMatch(ua);
  if (samsungMatch != null) return 'Samsung Browser ${samsungMatch.group(1)}';

  // Opera
  if (ua.contains('OPR/')) {
    final operaMatch = RegExp(r'OPR/(\d+)').firstMatch(ua);
    if (operaMatch != null) return 'Opera ${operaMatch.group(1)}';
  }

  return 'Browser';
}

// Helper: "Windows 11" / "macOS" / "iPhone iOS 17" / "Android 14" / "Linux"
String _parseOsName(String ua) {
  if (ua.contains('iPhone')) {
    final iosMatch = RegExp(r'OS (\d+)_').firstMatch(ua);
    return iosMatch != null ? 'iPhone iOS ${iosMatch.group(1)}' : 'iPhone';
  }
  if (ua.contains('iPad')) {
    final iosMatch = RegExp(r'OS (\d+)_').firstMatch(ua);
    return iosMatch != null ? 'iPad iOS ${iosMatch.group(1)}' : 'iPad';
  }
  if (ua.contains('Android')) {
    final androidMatch = RegExp(r'Android (\d+)').firstMatch(ua);
    return androidMatch != null ? 'Android ${androidMatch.group(1)}' : 'Android';
  }
  if (ua.contains('Windows NT 10.0')) return 'Windows 10/11';
  if (ua.contains('Windows NT 6.3'))  return 'Windows 8.1';
  if (ua.contains('Windows NT 6.1'))  return 'Windows 7';
  if (ua.contains('Windows'))         return 'Windows';
  if (ua.contains('Mac OS X'))        return 'macOS';
  if (ua.contains('Linux'))           return 'Linux';
  return 'Unknown OS';
}

// ══════════════════════════════════════════════════════
// 3. RAZORPAY WEB CHECKOUT (unchanged)
// ══════════════════════════════════════════════════════
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
  js.context.callMethod('openRazorpayWebCheckout', [
    keyId, amount, orderId, name, desc, appSecret, baseUrl, userId
  ]);
}
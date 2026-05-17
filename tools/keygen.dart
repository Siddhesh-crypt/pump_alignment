// tools/keygen.dart
// Run with: dart run tools/keygen.dart <DEVICE_ID>
// Example:  dart run tools/keygen.dart abc123def456

import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';

// !! MUST match the secret in lib/core/constants/app_constants.dart !!
const String _secret = 'SiddheshSecret2026';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('');
    stderr.writeln('╔══════════════════════════════════════════════╗');
    stderr.writeln('║   Rim & Face Alignment - License Key Tool    ║');
    stderr.writeln('╚══════════════════════════════════════════════╝');
    stderr.writeln('');
    stderr.writeln('Usage:  dart run tools/keygen.dart <DEVICE_ID>');
    stderr.writeln('');
    stderr.writeln('Example:');
    stderr.writeln('  dart run tools/keygen.dart a1b2c3d4e5f6g7h8');
    stderr.writeln('');
    exit(1);
  }

  final deviceId = args[0].trim();

  if (deviceId.isEmpty) {
    stderr.writeln('Error: Device ID cannot be empty.');
    exit(1);
  }

  final key = utf8.encode(_secret);
  final message = utf8.encode(deviceId);
  final hmac = Hmac(sha256, key);
  final digest = hmac.convert(message);
  final licenseKey = digest.toString().toUpperCase();

  stdout.writeln('');
  stdout.writeln('╔══════════════════════════════════════════════╗');
  stdout.writeln('║         LICENSE KEY GENERATED                ║');
  stdout.writeln('╠══════════════════════════════════════════════╣');
  stdout.writeln('║ Device ID  : $deviceId');
  stdout.writeln('║ License Key: $licenseKey');
  stdout.writeln('╚══════════════════════════════════════════════╝');
  stdout.writeln('');
  stdout.writeln('Send this License Key to the user.');
}
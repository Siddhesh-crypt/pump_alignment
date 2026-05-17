import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../providers/auth_provider.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _keyCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _copyDeviceId(String id) async {
    await Clipboard.setData(ClipboardData(text: id));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Device ID copied to clipboard'),
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _unlock() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).unlock(_keyCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isLoading = state.isLoading;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Lock Icon ───────────────────────────────────
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 40,
                      color: cs.primary,
                    ),
                  )
                      .animate()
                      .scale(
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  ),

                  const Gap(24),

                  Text(
                    'Device Authorization Required',
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 150.ms, duration: 400.ms),

                  const Gap(8),

                  Text(
                    'This app is licensed per device. Please send your Device ID to the administrator to receive your License Key.',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms),

                  const Gap(28),

                  // ── Device ID Card ──────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.perm_device_info_rounded,
                                  size: 16, color: cs.primary),
                              const Gap(6),
                              Text(
                                'Your Device ID',
                                style: tt.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: cs.primary,
                                ),
                              ),
                            ],
                          ),
                          const Gap(10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText(
                              state.deviceId.isEmpty
                                  ? 'Fetching…'
                                  : state.deviceId,
                              style: tt.bodyMedium?.copyWith(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const Gap(10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: state.deviceId.isEmpty
                                  ? null
                                  : () =>
                                  _copyDeviceId(state.deviceId),
                              icon: const Icon(
                                  Icons.copy_rounded,
                                  size: 18),
                              label: const Text('Copy Device ID'),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 400.ms)
                      .slideY(begin: 0.05, end: 0),

                  const Gap(20),

                  // ── License Key Entry ───────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.vpn_key_rounded,
                                  size: 16, color: cs.primary),
                              const Gap(6),
                              Text(
                                'Enter License Key',
                                style: tt.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: cs.primary,
                                ),
                              ),
                            ],
                          ),
                          const Gap(12),
                          TextFormField(
                            controller: _keyCtrl,
                            obscureText: _obscure,
                            textCapitalization:
                            TextCapitalization.characters,
                            onChanged: (_) {
                              if (state.errorMessage != null) {
                                ref
                                    .read(authProvider.notifier)
                                    .clearError();
                              }
                            },
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Please enter your license key';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'License Key',
                              hintText: 'Paste your key here',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                        () => _obscure = !_obscure),
                              ),
                              errorText: state.errorMessage,
                            ),
                          ),
                          const Gap(12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: state.isValidating
                                  ? null
                                  : _unlock,
                              icon: state.isValidating
                                  ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : const Icon(
                                  Icons.lock_open_rounded,
                                  size: 20),
                              label: Text(state.isValidating
                                  ? 'Validating…'
                                  : 'Unlock App'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 400.ms)
                      .slideY(begin: 0.05, end: 0),

                  const Gap(24),

                  Text(
                    'Contact the administrator with your Device ID\nto receive your License Key.',
                    style: tt.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 400.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:pump_alignment/features/licensing/presentation/providers/licensing_provider.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(licensingProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Gap(30),

              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    size: 42,
                    color: cs.primary,
                  ),
                ),
              ),
              const Gap(24),

              Text(
                'Unlock Premium Access',
                style: tt.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(8),
              Text(
                'Your free trial has ended. Choose a plan to continue performing accurate alignments.',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const Gap(32),

              // Features List
              const _FeatureRow(
                icon: Icons.bolt_rounded,
                text: 'Unlimited Rim & Face Calculations',
              ),
              const _FeatureRow(
                icon: Icons.screen_rotation_rounded,
                text: 'Supports Vertical & Horizontal Planes',
              ),
              const _FeatureRow(
                icon: Icons.analytics_rounded,
                text: 'Instant Front & Rear Feet Correction Values',
              ),
              const _FeatureRow(
                icon: Icons.timer_rounded,
                text: 'Valid for 5 Minutes (Testing Mode)',
              ), // <-- Updated to 5 Mins

              const Gap(32),

              // Action Buttons
              if (!kIsWeb && Platform.isAndroid) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: state.isPaymentLoading
                        ? null
                        : () => ref
                              .read(licensingProvider.notifier)
                              .initiateRealPayment(context),
                    icon: state.isPaymentLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.currency_rupee_rounded),
                    label: Text(
                      state.isPaymentLoading
                          ? 'Initializing Checkout...'
                          : 'Pay ₹1 — Test 5 Mins Access', // <-- Text updated to 1 Rupee
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const Gap(24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── UI Component ──
class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: cs.primary),
          ),
          const Gap(14),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

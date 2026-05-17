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
          physics: const BouncingScrollPhysics(), // iOS native scroll feel
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Gap(30),

              // ── Premium Icon ──
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
                ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
              ),
              const Gap(24),

              // ── Header Text ──
              Text(
                state.hasActivatedTrialBefore
                    ? 'Free Trials Exhausted'
                    : 'License Required',
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 100.ms),
              const Gap(12),

              Text(
                state.hasActivatedTrialBefore
                    ? 'You have used all 5 free calculations.\nUpgrade once for unlimited access — forever.'
                    : 'Get started with a free trial or unlock lifetime unlimited access directly.',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 150.ms),
              const Gap(24),

              // ── Active License Key Display (If any) ──
              if (state.activeLicenseKey != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outlineVariant, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.key_rounded, size: 16, color: cs.primary),
                      const Gap(10),
                      Text(
                        'Your Key: ${state.activeLicenseKey}',
                        style: tt.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 180.ms),
                const Gap(24),
              ],

              // ── Features List ──
              ...[
                    (Icons.all_inclusive_rounded, 'Unlimited calculations'),
                    (
                      Icons.devices_rounded,
                      'Locked to your device — no subscription',
                    ),
                    (Icons.bolt_rounded, 'Instant activation after payment'),
                    (
                      Icons.wifi_off_rounded,
                      'Works fully offline after unlock',
                    ),
                  ]
                  .map((item) => _FeatureRow(icon: item.$1, text: item.$2))
                  .toList()
                  .animate(interval: 60.ms)
                  .fadeIn(delay: 200.ms)
                  .slideX(begin: -0.04, end: 0),
              const Gap(32),

              // ── Error Message Display ──
              if (state.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 20,
                        color: cs.onErrorContainer,
                      ),
                      const Gap(12),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(20),
              ],

              // ── BUTTON 1: Activate Free Trial (Only visible if never activated before) ──
              if (!state.hasActivatedTrialBefore) ...[
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: state.isPaymentLoading
                        ? null
                        : () => ref
                              .read(licensingProvider.notifier)
                              .activateFreeTrialLicense(),
                    icon: const Icon(Icons.play_arrow_rounded),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.primary,
                      side: BorderSide(color: cs.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    label: const Text(
                      'Activate 5 Free Trials',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const Gap(14),
              ],

              // ── BUTTON 2: Real Razorpay Pay Button ──
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: state.isPaymentLoading
                      ? null
                      : () => ref
                            .read(licensingProvider.notifier)
                            .initiateRealPayment(context),
                  icon: state.isPaymentLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                      : const Icon(Icons.currency_rupee_rounded),
                  label: Text(
                    state.isPaymentLoading
                        ? 'Initializing Checkout...'
                        : 'Pay ₹50 — Lifetime Access',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const Gap(24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── UI Components ──
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

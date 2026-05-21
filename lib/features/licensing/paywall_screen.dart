import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
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
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            children: [
              const Gap(30),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(color: cs.primaryContainer, shape: BoxShape.circle),
                child: Icon(Icons.workspace_premium_rounded, size: 42, color: cs.primary),
              ),
              const Gap(24),
              Text('Unlock Premium Access', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const Gap(8),
              Text('Choose a plan to continue performing accurate alignments.',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
              const Gap(32),

              const _FeatureRow(icon: Icons.bolt_rounded, text: 'Unlimited Rim & Face Calculations'),
              const _FeatureRow(icon: Icons.screen_rotation_rounded, text: 'Supports Vertical & Horizontal Planes'),
              const _FeatureRow(icon: Icons.analytics_rounded, text: 'Instant Front & Rear Feet Correction'),

              const Gap(32),

              if (kIsWeb || (!kIsWeb && Platform.isAndroid))
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: state.isPaymentLoading
                        ? null
                        : () => ref.read(licensingProvider.notifier).initiateRealPayment(context),
                    icon: state.isPaymentLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.currency_rupee_rounded),
                    label: Text(state.isPaymentLoading ? 'Initializing...' : 'Pay ₹1 — Premium Access'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

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
        children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: cs.primaryContainer.withOpacity(0.3), shape: BoxShape.circle), child: Icon(icon, size: 18, color: cs.primary)),
          const Gap(14),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pump_alignment/core/constants/app_constants.dart';
import 'package:pump_alignment/core/theme/app_theme.dart';
import 'package:pump_alignment/features/licensing/presentation/providers/licensing_provider.dart';
import 'package:pump_alignment/features/calculator/presentation/screens/calculator_screen.dart';
import 'package:pump_alignment/features/licensing/licensing_service.dart';
import 'package:pump_alignment/features/licensing/paywall_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const RimFaceApp(),
    ),
  );
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main() before use.',
  );
});

class RimFaceApp extends ConsumerWidget {
  const RimFaceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const _AppGate(),
    );
  }
}

class _AppGate extends ConsumerStatefulWidget {
  const _AppGate();

  @override
  ConsumerState<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends ConsumerState<_AppGate> {
  @override
  void initState() {
    super.initState();

    // ── Connect Razorpay Callbacks and Force State Updates ──
    LicensingService.instance.onPaymentSuccess = () {
      if (mounted) {
        // Direct Provider call block force refresh execute karega
        ref.read(licensingProvider.notifier).refreshStatus();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.verified_user_rounded, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '🎉 Payment Verified! 5 Minutes Test Access Unlocked.',
                    softWrap: true,
                  ),
                ),
              ],
            ),
            backgroundColor: Color(0xFF1A6E5A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    };

    LicensingService.instance.onPaymentFailed = () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Payment failed or cancelled. Please try again.',
                    softWrap: true,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(licensingProvider);

    if (state.isLoading) {
      return const _SplashScreen();
    }

    if (state.canCalculate) {
      return const CalculatorScreen();
    }

    return const PaywallScreen();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.settings_input_component_rounded,
                size: 48,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppConstants.appName,
              style: tt.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Initialising…',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

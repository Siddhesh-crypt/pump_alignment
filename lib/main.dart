import 'dart:async';
import 'package:flutter/foundation.dart';
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
import 'package:pump_alignment/features/auth/presentation/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  final prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)], child: const RimFaceApp()));
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

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

class _AppGateState extends ConsumerState<_AppGate> with WidgetsBindingObserver {
  Timer? _heartbeatTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // ── THE KICK-OUT TIMER (3 Seconds Background Check) ──
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        final prefs = ref.read(sharedPreferencesProvider);
        if (prefs.containsKey('auth_user_id')) {
          ref.read(licensingProvider.notifier).checkSessionPulse();
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(licensingProvider.notifier).checkSessionPulse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(licensingProvider);
    final prefs = ref.watch(sharedPreferencesProvider);
    if (state.isLoading) return const _SplashScreen();
    final isUserLoggedIn = prefs.containsKey('auth_user_id');

    if (!isUserLoggedIn) return LoginScreen(onLoginSuccess: () { ref.read(licensingProvider.notifier).refreshStatus(); setState(() {}); });
    if (state.isPremium) return const CalculatorScreen();
    return const PaywallScreen();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
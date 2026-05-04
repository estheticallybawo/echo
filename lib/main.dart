import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/account-setups/permission_setup_screen.dart';
import 'screens/account-setups/phrase_setup_screen.dart';
import 'screens/account-setups/tier1_inner_circle_setup_screen.dart';
import 'screens/account-setups/tier2_public_alert_setup_screen.dart';
import 'screens/account-setups/system_test_screen.dart';
import 'screens/onboarding/onboarding_flow.dart';

import 'theme.dart';
import 'screens/onboarding/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EchoApp());
}

class EchoApp extends StatelessWidget {
  const EchoApp({super.key});

  @override
  Widget build(BuildContext context) {
    GoogleFonts.config.allowRuntimeFetching = true;

    return MaterialApp(
      title: 'Echo',
      debugShowCheckedModeBanner: false,
      theme: buildEchoTheme(),
      home: const SplashScreen(),
      routes: {
        '/account-setups': (context) => const AccountSetupsScreen(),
        '/permission-setup': (context) => const AccountSetupsScreen(),
        '/phrase-setup': (context) => const PhraseSetupScreen(),
        '/tier1-inner-circle-setup': (context) => const Tier1InnerCircleSetupScreen(),
        '/tier2-public-alert-setup': (context) => const Tier2PublicAlertSetupScreen(),
        '/onboarding': (context) => const OnboardingFlow(),
        '/system-test': (context) => const SystemTestScreen(),
      },
    );
  }
}

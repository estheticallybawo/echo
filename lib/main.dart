import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/account-setups/permission_setup_screen.dart';
import 'screens/account-setups/tier1_inner_circle_setup_screen.dart';
import 'screens/account-setups/tier2_public_alert_setup_screen.dart';
import 'screens/account-setups/system_test_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/main_scaffold.dart';
import 'screens/home/ai_intel_screen.dart';
import 'screens/home/contacts_screen.dart';
import 'screens/home/emergency_active_screen.dart';
import 'screens/home/activity_screen.dart';
import 'screens/home/settings_screen.dart';
import 'screens/home/profile_screen.dart';
import 'screens/home/notification_screen.dart';
import 'screens/home/threat_analysis_result_screen.dart';
import 'screens/home/terms_privacy_screen.dart';

import 'screens/onboarding/onboarding_flow.dart';

import 'package:provider/provider.dart';
import 'providers/escalation_provider.dart';
import 'providers/theme_provider.dart';
import 'theme.dart';
import 'screens/onboarding/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => EscalationProvider()),
      ],
      child: const EchoApp(),
    ),
  );
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
        '/tier1-inner-circle-setup': (context) => const Tier1InnerCircleSetupScreen(),
        '/tier2-public-alert-setup': (context) => const Tier2PublicAlertSetupScreen(),
        '/onboarding': (context) => const OnboardingFlow(),
        '/system-test': (context) => const SystemTestScreen(),
        '/home': (context) => const MainScaffold(),
        '/ai-intel': (context) => const AiIntelScreen(),
        '/contacts': (context) => const ContactsScreen(),
        '/emergency-active': (context) => const EmergencyActiveScreen(),
        '/activity': (context) => const ActivityScreen(),
        '/notifications': (context) => const NotificationScreen(),
        '/terms-privacy': (context) => const TermsPrivacyScreen(),
        '/threat-analysis-result': (context) => const ThreatAnalysisResultScreen(),

        '/settings': (context) => const SettingsScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

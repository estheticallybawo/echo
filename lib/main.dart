import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/emergency_active_screen.dart';
import 'screens/onboarding_flow.dart';
import 'screens/contacts_screen.dart';
import 'screens/ai_intel_screen.dart';
import 'screens/ai_settings_screen.dart';
import 'theme.dart';

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
      home: const AuthScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/emergency-active': (context) => const EmergencyActiveScreen(),
        '/onboarding': (context) => const OnboardingFlow(),
        '/contacts': (context) => const ContactsScreen(),
        '/ai-intel': (context) => const AIIntelScreen(),
        '/ai-settings': (context) => const AISettingsScreen(),
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/emergency_active_screen.dart';
import 'screens/onboarding_flow.dart';
import 'screens/contacts_screen.dart';
import 'screens/ai_intel_screen.dart';
import 'screens/fake_call_screen.dart';
import 'screens/incident_log_screen.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize any services here (audio, location, etc.)
  runApp(const GuardianApp());
}

class GuardianApp extends StatelessWidget {
  const GuardianApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure Google Fonts loads correctly
    GoogleFonts.config.allowRuntimeFetching = true;

    return MaterialApp(
      title: 'Guardian',
      debugShowCheckedModeBanner: false,
      theme: buildGuardianTheme(),
      home: const OnboardingFlow(), // Start with onboarding to see all UI
      routes: {
        '/home': (context) => const HomeScreen(),
        '/emergency-active': (context) => const EmergencyActiveScreen(),
        '/onboarding': (context) => const OnboardingFlow(),
        '/contacts': (context) => const ContactsScreen(),
        '/ai-intel': (context) => const AIIntelScreen(),
        '/fake-call': (context) => const FakeCallScreen(),
        '/incident-log': (context) => const IncidentLogScreen(),
      },
      navigatorObservers: [
        // Add analytics or logging observer here
      ],
    );
  }
}

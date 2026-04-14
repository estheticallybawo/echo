import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/emergency_active_screen.dart';
import 'screens/onboarding_flow.dart';
import 'screens/contacts_screen.dart';
import 'screens/ai_intel_screen.dart';
import 'theme.dart';
import 'services/voice_recognition_service.dart';
import 'services/secrets_service.dart';
import 'services/emergency_state_manager.dart';

late VoiceRecognitionService voiceService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final emergencyManager = EmergencyStateManager();

  final savedPhrase = await SecretsService.getSafetyPhrase() ?? 'help me';
  voiceService = VoiceRecognitionService(safetyPhrase: savedPhrase);
  final initialized = await voiceService.initialize(
    onActivation: emergencyManager.handleVoiceActivation,
  );
  if (initialized) await voiceService.startListening();

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
      },
      navigatorObservers: [
        // Add analytics or logging observer here
      ],
    );
  }
}

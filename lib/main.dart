import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

// Screens
import 'screens/auth/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/emergency_active_screen.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/ai_intel_screen.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/background_listening_provider.dart';

// Services
import 'services/auth_service.dart';
import 'services/background_listening_service.dart';

import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb) {
    try {
      await dotenv.load();
    } catch (e) {
      debugPrint('Warning: Could not load .env file: $e');
    }
  }
  
  runApp(const EchoApp());
}

class EchoApp extends StatelessWidget {
  const EchoApp({super.key});

  String _getEnv(String key, String fallback) {
    if (kIsWeb) return fallback;
    return dotenv.env[key] ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    GoogleFonts.config.allowRuntimeFetching = true;

    final authService = AuthService();
    final backgroundListeningService = BackgroundListeningService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService: authService),
        ),
        ChangeNotifierProvider(
          create: (_) => BackgroundListeningProvider(
            listeningService: backgroundListeningService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Echo',
        debugShowCheckedModeBanner: false,
        theme: buildEchoTheme(),
        home: const SplashScreen(), // Use remote's splash screen
        routes: {
          '/home': (context) => const HomeScreen(),
          '/emergency-active': (context) => const EmergencyActiveScreen(),
          '/onboarding': (context) => const OnboardingFlow(),
          '/contacts': (context) => const ContactsScreen(),
          '/ai-intel': (context) => const AIIntelScreen(),
        },
      ),
    );
  }
}

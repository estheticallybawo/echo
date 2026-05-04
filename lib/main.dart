import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'screens/home_screen.dart';
import 'screens/emergency_active_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/ai_intel_screen.dart';
import 'theme.dart';
// Track C: Providers
import 'providers/gemma_provider.dart';
import 'providers/user_preferences_provider.dart';
// Track C: Services
import 'services/llama_threat_service.dart';
import 'services/llama_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file (mobile/desktop only)
  // Web builds don't support file assets in dotenv - skip loading
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    print('⚠️ Could not load .env file (OK for Web builds): $e');
  }

  // Verify llama-server is healthy before proceeding
  final isHealthy = await LlamaConfig.isServerHealthy();
  if (!isHealthy) {
    print(
      '⚠️ WARNING: llama-server is not responding at ${LlamaConfig.activeHost}',
    );
    print(
      '   Make sure to run: .\\llama-server.exe -m <model.gguf> --host 0.0.0.0 --port 8080',
    );
  } else {
    print('✅ llama-server is healthy and ready');
  }

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }

  runApp(const EchoApp());
}

class EchoApp extends StatefulWidget {
  const EchoApp({super.key});

  @override
  State<EchoApp> createState() => _EchoAppState();
}

class _EchoAppState extends State<EchoApp> {
  @override
  Widget build(BuildContext context) {
    // Track C: Initialize Gemma 4 service
    final gemmaService =
        LlamaThreatService(); // Using local llama-server for testing

    // NOTE: ConfirmationSoundService initialization moved to after auth in home_screen
    // (was initializing before Firebase auth was ready)

    return MultiProvider(
      providers: [
        // Track C: User Preferences Provider - Must be first for onboarding checks
        ChangeNotifierProvider(create: (_) => UserPreferencesProvider()),
        // Track C: Gemma Provider
        ChangeNotifierProvider(
          create: (_) => GemmaProvider(llamaThreatService: gemmaService),
        ),
      ],
      child: MaterialApp(
        title: 'Echo',
        debugShowCheckedModeBanner: false,
        theme: buildEchoTheme(),
        home: const OnboardingFlow(),
        routes: {
          '/onboarding': (context) => const OnboardingFlow(),
          '/home': (context) => const HomeScreen(),
          '/emergency': (context) => const EmergencyActiveScreen(),
          '/emergency-active': (context) => const EmergencyActiveScreen(),
          '/contacts': (context) => const ContactsScreen(),
          '/ai-intel': (context) => const AIIntelScreen(),
        },
        navigatorObservers: [
          // Add analytics or logging observer here
        ],
      ),
    );
  }
}

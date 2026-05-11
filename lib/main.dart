import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'screens/emergency_active_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'screens/threat_analysis_result_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/model_setup_screen.dart';
import 'providers/escalation_provider.dart';
import 'providers/gemma_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_preferences_provider.dart';
import 'services/local_storage_service.dart';
import 'theme.dart';
import 'screens/onboarding/splash_screen.dart';
import 'package:flutter_gemma/flutter_gemma.dart';





void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load();
  
  // Initialize local storage (must be before Firebase)
  await LocalStorageService().initialize();
  WidgetsFlutterBinding.ensureInitialized();

  // Important: initialize the plugin
  FlutterGemma.initialize(
    huggingFaceToken: const String.fromEnvironment('HUGGINGFACE_TOKEN'),
    maxDownloadRetries: 10,
  );

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final localStorage = LocalStorageService();
  await localStorage.setCurrentUser(
    uid: 'demo-hiny',
    email: 'hiny@demo.echo',
    displayName: 'Hiny',
  );

  if (localStorage.getContacts('demo-hiny').isEmpty) {
    await localStorage.addContact(
      'demo-hiny',
      name: 'Mom',
      phoneNumber: '+12345678901',
    );
    await localStorage.addContact(
      'demo-hiny',
      name: 'Sister',
      phoneNumber: '+12345678902',
    );
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserPreferencesProvider()),
        ChangeNotifierProvider(create: (_) => EscalationProvider()),
        ChangeNotifierProvider(
          create: (_) => GemmaProvider(),
        ),
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
        '/onboarding': (context) => const OnboardingFlow(),
        '/home': (context) => const HomeScreen(),
        '/emergency-active': (context) => const EmergencyActiveScreen(),
        '/threat-analysis-result': (context) => const ThreatAnalysisResultScreen(),
        '/chat': (context) => const ChatScreen(),
        '/model-setup': (context) => const ModelSetupScreen(),
      },
    );
  }
}
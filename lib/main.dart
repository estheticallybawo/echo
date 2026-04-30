import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/emergency_active_screen.dart';
import 'screens/onboarding_flow.dart';
import 'screens/contacts_screen.dart';
import 'screens/ai_intel_screen.dart';
import 'theme.dart';
// Track C: Social Media Providers
import 'providers/gemma_provider.dart';
import 'providers/social_media_provider.dart';
import 'providers/user_preferences_provider.dart';
// Track C: Services
import 'services/llama_threat_service.dart';
import 'services/llama_config.dart';
import 'services/x_oauth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: '.env');

  // Configure Llama.cpp server with Ngrok URL (for team testing)
  // If NGROK_URL is set, teammates can test without local Gemma download

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
    
    // Load X OAuth 1.0a credentials from .env
    final xConsumerKey = dotenv.env['X_CONSUMER_KEY'] ?? '';
    final xConsumerSecret = dotenv.env['X_CONSUMER_SECRET'] ?? '';
    final xAccessToken = dotenv.env['X_ACCESS_TOKEN'] ?? '';
    final xAccessTokenSecret = dotenv.env['X_ACCESS_TOKEN_SECRET'] ?? '';
    
    // Validate OAuth 1.0a credentials are available
    if (xConsumerKey.isEmpty || xConsumerSecret.isEmpty || xAccessToken.isEmpty || xAccessTokenSecret.isEmpty) {
      print('❌ X OAuth 1.0a credentials missing from .env - auto-posting will fail');
    } else {
      print('✅ X OAuth 1.0a Config loaded:');
      print('   Consumer Key: ${xConsumerKey.substring(0, min(10, xConsumerKey.length))}...');
      print('   Access Token: ${xAccessToken.substring(0, min(10, xAccessToken.length))}...');
    }
    
    final xService = XOauthService(
      consumerKey: xConsumerKey,
      consumerSecret: xConsumerSecret,
      accessToken: xAccessToken,
      accessTokenSecret: xAccessTokenSecret,
    );

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
        // Track C: Social Media Provider (depends on Gemma)
        ChangeNotifierProxyProvider<GemmaProvider, SocialMediaProvider>(
          create: (_) => SocialMediaProvider(
            xService: xService,
            gemmaProvider: GemmaProvider(llamaThreatService: gemmaService),
          ),
          update: (_, gemmaProvider, socialMediaProvider) =>
              socialMediaProvider ??
              SocialMediaProvider(
                xService: xService,
                gemmaProvider: gemmaProvider,
              ),
        ),
      ],
      child: MaterialApp(
        title: 'Echo',
        debugShowCheckedModeBanner: false,
        theme: buildEchoTheme(),
        home: const AuthScreen(),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/emergency': (context) => const EmergencyActiveScreen(),
          '/emergency-active': (context) => const EmergencyActiveScreen(),
          '/onboarding': (context) => const OnboardingFlow(),
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

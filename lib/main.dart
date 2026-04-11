import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/emergency_active_screen.dart';
import 'screens/onboarding_flow.dart';
import 'screens/contacts_screen.dart';
import 'screens/ai_intel_screen.dart';
import 'theme.dart';
<<<<<<< Updated upstream
=======
// Authentication
import 'providers/auth_provider.dart';
import 'services/auth_service.dart';
// Background Listening (Privacy-First)
import 'providers/background_listening_provider.dart';
import 'services/background_listening_service.dart';
// Track C: Social Media Providers
import 'providers/gemma_provider.dart';
import 'providers/social_media_provider.dart';
// Track C: Services
import 'services/gemma_threat_assessment_service.dart';
import 'services/social_media_posting_service.dart';
import 'services/twitter_oauth_service.dart';
>>>>>>> Stashed changes

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Only load .env file on native platforms
  // On Web, use fallback values (CORS prevents .env loading)
  if (!kIsWeb) {
    try {
      await dotenv.load();
    } catch (e) {
      print('Warning: Could not load .env file: $e');
    }
  }
  
  // Initialize any services here (audio, location, etc.)
  runApp(const EchoApp());
}

class EchoApp extends StatelessWidget {
  const EchoApp({super.key});
<<<<<<< Updated upstream
=======

  /// Get environment variable safely (works on both web and native)
  String _getEnv(String key, String fallback) {
    if (kIsWeb) {
      return fallback; // Use fallback on web
    }
    return dotenv.env[key] ?? fallback; // Use .env on native platforms
  }
>>>>>>> Stashed changes

  @override
  Widget build(BuildContext context) {
    // Ensure Google Fonts loads correctly
    GoogleFonts.config.allowRuntimeFetching = true;

<<<<<<< Updated upstream
    return MaterialApp(
      title: 'Echo',
      debugShowCheckedModeBanner: false,
      theme: buildEchoTheme(),
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
=======
    // Initialize services
    final authService = AuthService();
    
    final backgroundListeningService = BackgroundListeningService();
    
    final gemmaService = GemmaThreatAssessmentService(
      apiKey: _getEnv('GOOGLE_API_KEY', 'default-key'),
    );
    
    final twitterService = TwitterOAuthService(
      apiKey: _getEnv('TWITTER_API_KEY', 'your-client-id'),
      apiSecret: _getEnv('TWITTER_API_SECRET', 'your-client-secret'),
      redirectUri: 'echo://oauth-callback',
    );
    
    final socialMediaService = SocialMediaPostingService(
      gemmaService: gemmaService,
      twitterService: twitterService,
    );

    return MultiProvider(
      providers: [
        // Authentication
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService: authService),
        ),
        // Background Listening (Privacy-First - User Autonomy)
        ChangeNotifierProvider(
          create: (_) => BackgroundListeningProvider(
            listeningService: backgroundListeningService,
          ),
        ),
        // Track C: Gemma Provider
        ChangeNotifierProvider(
          create: (_) => GemmaProvider(gemmaService: gemmaService),
        ),
        // Track C: Social Media Provider (depends on Gemma)
        ChangeNotifierProxyProvider<GemmaProvider, SocialMediaProvider>(
          create: (_) => SocialMediaProvider(
            socialMediaService: socialMediaService,
            twitterService: twitterService,
            gemmaProvider: GemmaProvider(gemmaService: gemmaService),
          ),
          update: (_, gemmaProvider, socialMediaProvider) =>
              socialMediaProvider ?? SocialMediaProvider(
            socialMediaService: socialMediaService,
            twitterService: twitterService,
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
          '/emergency-active': (context) => const EmergencyActiveScreen(),
          '/onboarding': (context) => const OnboardingFlow(),
          '/contacts': (context) => const ContactsScreen(),
          '/ai-intel': (context) => const AIIntelScreen(),
        },
        navigatorObservers: [
          // Add analytics or logging observer here
        ],
      ),
>>>>>>> Stashed changes
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
// Track C: Services
import 'services/gemma_threat_assessment_service.dart';
import 'services/social_media_posting_service.dart';
import 'services/twitter_oauth_service.dart';
import 'services/confirmation_sound_service.dart';
import 'services/deep_link_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  await dotenv.load(fileName: '.env');
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Anonymous sign-in for initial app state
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  } catch (e) {
    print('Firebase initialization error: $e');
  }
  
  runApp(const EchoApp());
}

class EchoApp extends StatefulWidget {
  const EchoApp({super.key});

  @override
  State<EchoApp> createState() => _EchoAppState();
}

class _EchoAppState extends State<EchoApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  late DeepLinkService deepLinkService;

  @override
  void initState() {
    super.initState();
    deepLinkService = DeepLinkService();
    // Initialize deep link handling after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await deepLinkService.initAppLinks();
      deepLinkService.startListeningToDeepLinks(context);
    });
  }

  @override
  void dispose() {
    deepLinkService.stopListeningToDeepLinks();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    GoogleFonts.config.allowRuntimeFetching = true;

    // Track C: Initialize services
    final apiKey = dotenv.env['GOOGLE_AI_STUDIO_API_KEY'] ?? '';
    final gemmaService = GemmaThreatAssessmentService(
      apiKey: apiKey,
    );
    
    final twitterService = TwitterOAuthService(
      apiKey: 'your-client-id',
      apiSecret: 'your-client-secret',
      redirectUri: 'guard://oauth-callback',
    );
    
    final socialMediaService = SocialMediaPostingService(
      gemmaService: gemmaService,
      twitterService: twitterService,
    );

    // Initialize Confirmation Sound Service (listens to Firestore in real-time)
    final confirmationSoundService = ConfirmationSoundService();
    confirmationSoundService.startListening().then((success) {
      if (success) {
        print('✅ Confirmation sound service initialized');
      } else {
        print('⚠️ Confirmation sound service initialization failed');
      }
    });

    return MultiProvider(
      providers: [
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
        navigatorKey: navigatorKey,
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

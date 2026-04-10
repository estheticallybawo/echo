import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize any services here (audio, location, etc.)
  runApp(const GuardApp());
}

class GuardApp extends StatelessWidget {
  const GuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    GoogleFonts.config.allowRuntimeFetching = true;

    // Track C: Initialize services
    final gemmaService = GemmaThreatAssessmentService(
      apiKey: 'AIzaSyBc5Yhnka-eQqTwmW5Gl6Nr7GZ-Dnm14Qw', // From .env in production
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
        title: 'Guard',
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
      ),
    );
  }
}

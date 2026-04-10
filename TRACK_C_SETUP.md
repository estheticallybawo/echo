# Track C: Social Media Auto-Posting Setup

**Created on**: April 10, 2026  
**Developer**: Esther Bawo Tsotso Track C (Social Media + Gemma Integration)  
**Branch**: `feature/track-c-mvp`  
**Status**: Week 1 - Mock Implementation

---

## 📁 Files Created

### Providers (State Management)
```
lib/providers/
├── gemma_provider.dart              # Gemma 4 threat assessment state
└── social_media_provider.dart       # Twitter OAuth + posting state
```

### Services (Business Logic)
```
lib/services/
├── gemma_threat_assessment_service.dart    # Gemma mock + real API calls
├── twitter_oauth_service.dart              # Twitter OAuth 2.0 + posting
└── social_media_posting_service.dart       # Main pipeline orchestrator
```

### Configuration
- Updated `lib/main.dart` - Added Provider integration
- Updated `pubspec.yaml` - Added `http` package dependency

---

## 🎯 Current Implementation (Week 1 - Days 1-2)

### ✅ Completed
- [x] Provider setup with MultiProvider
- [x] GemmaProvider for threat analysis (mock)
- [x] SocialMediaProvider for Twitter integration (mock)
- [x] GemmaThreatAssessmentService (mock responses)
- [x] TwitterOAuthService (mock OAuth)
- [x] SocialMediaPostingService (main pipeline orchestrator)
- [x] All imports in main.dart configured

### 🔄 Status
- **Mocks Active**: All services use mock data for fast iteration
- **Latency Simulation**: Mock services simulate realistic API latency
- **Ready for Integration**: Friday (Apr 12) merge with Track A audio buffer

---

## 🚀 How to Use

### In UI Screens (Days 3+)

**Display Gemma threat analysis:**
```dart
Consumer<GemmaProvider>(
  builder: (context, gemmaProvider, child) {
    if (gemmaProvider.isAnalyzing) {
      return CircularProgressIndicator();
    }
    if (gemmaProvider.lastThreatAssessment != null) {
      final threat = gemmaProvider.lastThreatAssessment!['threat'];
      final confidence = gemmaProvider.lastThreatAssessment!['confidence'];
      return Text('Threat: $threat ($confidence%)');
    }
    return Text('No threat assessment yet');
  },
)
```

**Display Twitter posting status:**
```dart
Consumer<SocialMediaProvider>(
  builder: (context, socialProvider, child) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: socialProvider.isTwitterConnected
              ? () => socialProvider.authenticateTwitterMock()
              : null,
          child: Text(socialProvider.isTwitterConnected
              ? 'Twitter Connected: ${socialProvider.twitterUsername}'
              : 'Connect Twitter'),
        ),
        if (socialProvider.isPosting)
          CircularProgressIndicator()
        else if (socialProvider.lastPostText != null)
          Text('Last post: ${socialProvider.lastPostText!}'),
      ],
    );
  },
)
```

---

## 📅 Week 1 Checklist

### Days 1-2 (Apr 9-10) - Mock Implementation ✅
- [x] All provider files created
- [x] Mock responses implemented
- [x] Provider integrated in main.dart
- [x] Services fully mocked

### Days 3-4 (Apr 11-12) - Real API Integration
- [ ] Get Google AI Studio API key
- [ ] Replace `analyzeThreatMock()` → `analyzeThreat()`
- [ ] Get Twitter Client ID + Secret
- [ ] Replace `authenticateOAuthMock()` → `authenticateOAuth()`
- [ ] Test with real Gemma API
- [ ] Test with real Twitter OAuth

### Day 5 (Apr 12 Friday) - Integration
- [ ] Merge with Track A (audio buffer)
- [ ] Merge with Track B (location)
- [ ] End-to-end test: Audio → Threat → Post → Twitter
- [ ] Merge to `develop` branch

---

## 🔑 Required API Keys

Add to `.env` file:

```env
# Google AI Studio (for Gemma)
GOOGLE_AI_STUDIO_API_KEY=AIzaSyBc5Yhnka-eQqTwmW5Gl6Nr7GZ-Dnm14Qw

# Twitter OAuth 2.0
TWITTER_CLIENT_ID=your-client-id
TWITTER_CLIENT_SECRET=your-client-secret
TWITTER_REDIRECT_URI=guard://oauth-callback
```

---

## 🔄 Week 2+ Plan (Post-MVP)

### Week 2 (Apr 15-19) - Ollama Integration
- [ ] Switch GemmaProvider to use Ollama locally
- [ ] Test on desktop with gemma:26b model
- [ ] Implement model routing (local vs cloud fallback)

### Week 3 (Apr 22-28) - Optimization
- [ ] Device-specific model selection (26B vs 2B vs cloud)
- [ ] Error handling + resilience testing
- [ ] Performance optimization

---

## 📊 Current State

**Main Pipeline** (Audio → Threat → Post → Twitter):
```
Track A Audio Buffer
        ↓
Track C: GemmaProvider.analyzeThreatMock()
        ↓
Track C: GemmaProvider.generatePostPreview()
        ↓
Track C: SocialMediaProvider.postEmergencyAlert()
        ↓
Track C: TwitterService.postEmergencyAlertMock()
        ↓
Twitter (or mock response)
```

**All mocks return consistent, testable data for Friday integration.**

---

## 🧪 Testing (Optional - Days 2-3)

Run provider tests:
```bash
flutter test lib/providers/gemma_provider.dart
flutter test lib/providers/social_media_provider.dart
```

Run service tests:
```bash
flutter test lib/services/gemma_threat_assessment_service.dart
flutter test lib/services/social_media_posting_service.dart
```

---

## 🚨 Important Notes

1. **Mocks are sufficient for Week 1** - All services have latency simulation
2. **No API key needed yet** - Mocks work standalone
3. **Minimal main.dart changes** - Isolated Track C integration
4. **Ready for parallel work** - Other tracks can develop independently
5. **Branch:** `feature/track-c-mvp` - Push this branch, PR to `develop` Friday

---

## 🎯 Success Metrics (By Friday Apr 12)

- [ ] All mock services return consistent data
- [ ] Providers properly update UI state
- [ ] No compiler errors
- [ ] Builds successfully on Chrome
- [ ] Ready for Track A audio buffer integration

---

**Status**: Ready for Day 3 (Apr 11) real API integration 🚀

# Echo App - Flutter/Dart Codebase Structure Analysis
**Date:** April 20, 2026  
**Focus:** Gemma/Ollama Integration, API Services, and Firebase Architecture

---

## 📋 Executive Summary

### Current State
- ✅ **Threat Assessment Service**: OPERATIONAL (OpenRouter API, with mock fallback)
- ✅ **Firebase Integration**: OPERATIONAL (Auth, Firestore, Cloud Messaging)
- ✅ **Escalation Timer**: OPERATIONAL (3-tier escalation logic)
- ✅ **Social Media Pipeline**: PARTIALLY OPERATIONAL (Twitter OAuth mock, real service stub)
- ❌ **Ollama Integration**: NOT YET IMPLEMENTED (documented in Phase 1 docs, ollama_config.dart missing)
- ⚠️ **Community Feed Service**: MODEL-ONLY (CommunityFeedEntry model exists, no service implementation)

### What Exists vs What Needs to be Created

| Component | Status | Location | Notes |
|-----------|--------|----------|-------|
| **Gemma Threat Assessment** | ✅ Exists | `lib/services/gemma_threat_assessment_service.dart` | Uses OpenRouter API, has mock mode |
| **Ollama Config** | ❌ Missing | Should be `lib/config/ollama_config.dart` | Documented in Phase 1 plan |
| **Ollama Integration Service** | ❌ Missing | Should be `lib/services/ollama_gemma_service.dart` | Planned refactor of existing service |
| **Community Feed Service** | ❌ Missing | Should be `lib/services/community_feed_service.dart` | Model exists, no CRUD operations |
| **Decision Engine** | ✅ Exists | `lib/services/gemma_decision_engine.dart` | Uses threat assessment to make escalation decisions |
| **Firestore Incident Service** | ✅ Exists | `lib/services/firestore_incident_service.dart` | Full CRUD + real-time listeners |
| **Escalation Timer** | ✅ Exists | `lib/services/escalation_timer_service.dart` | Multi-tier escalation (T+5s, T+30s, T+60s, T+90s) |
| **User Profile Service** | ✅ Exists | `lib/services/user_profile_service.dart` | Profile, contacts, threat history management |
| **Social Media Service** | ✅ Partial | `lib/services/social_media_posting_service.dart` | Pipeline exists, Twitter OAuth is mock |
| **Twitter OAuth Service** | ⚠️ Partial | `lib/services/twitter_oauth_service.dart` | Mock implementation, real OAuth pending |
| **Confirmation Sound Service** | ✅ Exists | `lib/services/confirmation_sound_service.dart` | Firestore listeners + audio playback |

---

## 🧠 Gemma/Threat Assessment Services

### 1. **GemmaThreatAssessmentService** 
📍 [lib/services/gemma_threat_assessment_service.dart](lib/services/gemma_threat_assessment_service.dart)

**Current Implementation:**
- Uses **OpenRouter API** (cloud-based)
- Model: `google/gemma-4-31b-it` (configurable)
- Two methods:
  - `analyzeThreatMock()` - Week 1 demo (hardcoded kidnapping response)
  - `analyzeThreat()` - Real API calls with fallback

**API Endpoint:**
```
https://openrouter.ai/api/v1/chat/completions
```

**Configuration Method:**
- Via `environment variables` (.env file):
  - `GEMMA_MODE`: 'openrouter' or 'google'
  - `OPENROUTER_API_KEY`: API key for OpenRouter
  - `OPENROUTER_MODEL`: Model name (default: 'google/gemma-4-31b-it')

**Threat Assessment Output Format:**
```json
{
  "threat": "Kidnapping|Assault|Fire|Medical|Robbery|Stalking|Other",
  "confidence": 0-100,
  "action": "specific emergency action",
  "summary": "brief explanation",
  "analyzedSituation": "one-line description",
  "threatLevel": "critical|high|medium|low"
}
```

**System Instructions:**
- Uses `GemmaSystemPrompts.emergencyThreatAssessment`
- Extensive multi-threat analysis framework
- Bias toward caution (false positives > false negatives)
- Cultural awareness and accessibility considerations

**Status:** ✅ OPERATIONAL (ready for OpenRouter)

---

### 2. **GemmaProvider** 
📍 [lib/providers/gemma_provider.dart](lib/providers/gemma_provider.dart)

**Role:** State management for threat analysis

**Key Methods:**
- `analyzeThreat(audioContext)` - Real API analysis
- `analyzeThreatMock(audioContext)` - Demo mode
- `logThreatToFirestore()` - Persist to Firebase

**State Tracked:**
- `isAnalyzing` - Boolean
- `lastThreatAssessment` - Latest assessment result
- `lastDecision` - Decision from GemmaDecisionEngine
- `lastIncidentId` - Last logged incident

**Status:** ✅ OPERATIONAL (integrates with service + Firestore)

---

### 3. **GemmaDecisionEngine** 
📍 [lib/services/gemma_decision_engine.dart](lib/services/gemma_decision_engine.dart)

**Role:** Makes escalation decisions based on threat assessment + user history

**Threat Confidence Thresholds:**
```dart
'kidnapping': 60,
'assault': 65,
'medical': 70,
'fire': 85,
'other': 75,
```

**Decision Levels:**
- `ESCALATE` - High confidence, meets threshold
- `ESCALATE_IMMEDIATE` - Very high confidence + threat pattern detected
- `MONITOR_CLOSE` - Borderline, needs monitoring
- `MONITOR` - Low threat, continue monitoring
- `DISMISS` - Too low to act on

**Factors:**
- Threat confidence score
- User threat sensitivity ('high', 'medium', 'low')
- Threat history (similar incidents in past 90 days)
- Auto-escalation user preference

**Status:** ✅ OPERATIONAL (ready for use)

---

## 🔥 Firebase Services

### 4. **FirestoreIncidentService**
📍 [lib/services/firestore_incident_service.dart](lib/services/firestore_incident_service.dart)

**Firestore Collection Structure:**
```
/incidents/{userId}/logs/{incidentId}
├─ action_type: "emergency_press"
├─ timestamp: Timestamp
├─ contact_id: "contact_123"
├─ location: "12.34, 56.78"
├─ threat_level: "HIGH"
├─ threat_category: "domestic_abuse"
├─ gemma_analysis: "..."
├─ escalation_status: "NOT_STARTED|PENDING|ESCALATED|CANCELLED"
├─ escalation_time: Timestamp
├─ user_id: "user_xyz"
└─ confirmation_status: "PENDING|CONFIRMED|DISMISSED"
```

**IncidentModel Methods:**
- `toFirestore()` - Convert to Firestore document
- `fromFirestore()` - Create from Firestore snapshot

**Status:** ✅ OPERATIONAL (model defined, CRUD operations ready)

---

### 5. **UserProfileService**
📍 [lib/services/user_profile_service.dart](lib/services/user_profile_service.dart)

**Firestore Collections:**
```
/users/{userId}/
├─ uid, full_name, phone, emergency_email
├─ threat_threshold: "medium|high|low"
├─ auto_escalate_enabled: boolean
├─ notification_preferences: {...}
├─ privacy_settings: {...}
└─ emergency_contacts/{contactId}
   ├─ name, phone, relationship
   ├─ whatsapp_group
   └─ is_active: boolean
```

**Key Methods:**
- `initializeUserProfile()` - First-time setup
- `addEmergencyContact()` - Add contacts
- `getThreatHistory()` - Get threats from past N days

**Status:** ✅ OPERATIONAL (ready for onboarding)

---

### 6. **EscalationTimerService**
📍 [lib/services/escalation_timer_service.dart](lib/services/escalation_timer_service.dart)

**Multi-Tier Escalation Timeline:**
- **T+5s:** TIER 1 ACTIVATION - Send WhatsApp to inner circle
- **T+30s:** Tier 1 checkpoint - Escalate to Tier 2 if no confirmation
- **T+60s:** Tier 1 follow-up nudge
- **T+90s:** Tier 3 auto-escalation - Twitter auto-post

**State Management:**
- `isRunning` - Timer active
- `secondsElapsed` / `secondsRemaining`
- `progressPercentage` - 0-100%
- `currentTier` - 1, 2, or 3
- Escalation tracking: `_tier1Confirmed`, `_tier2Confirmed`

**Callbacks:**
- `onTier1Activate()` - T+5s
- `onTier2Escalate()` - T+30s
- `onTier1Nudge()` - T+60s
- `onTier3Escalate()` - T+90s
- `onTick(seconds)` - Every second for UI updates

**Status:** ✅ OPERATIONAL (core escalation logic complete)

---

### 7. **ConfirmationSoundService**
📍 [lib/services/confirmation_sound_service.dart](lib/services/confirmation_sound_service.dart)

**Role:** Plays notification sound when incident is logged

**Features:**
- Listens to Firestore for incident creation
- Plays audio file on match
- Integrates with AudioPlayers plugin

**Status:** ✅ OPERATIONAL (audio playback ready)

---

## 📱 Social Media Integration

### 8. **SocialMediaPostingService**
📍 [lib/services/social_media_posting_service.dart](lib/services/social_media_posting_service.dart)

**Pipeline:**
```
Audio Context → Threat Analysis (Gemma) → Generate Post → Twitter
```

**Methods:**
- `postEmergencyAlertMock()` - Demo pipeline
- `postEmergencyAlert()` - Real pipeline (Gemma → Twitter)

**Post Template:**
```
"{UserName} needs urgent help, they are in a {analyzed_situation} 
last live location is at {location} if you can help please tag anyone who can, 
tweet by Echo"
```

**Status:** ⚠️ PARTIAL (mock works, real Twitter needs OAuth)

---

### 9. **TwitterOAuthService**
📍 [lib/services/twitter_oauth_service.dart](lib/services/twitter_oauth_service.dart)

**Current Implementation:**
- OAuth mock methods: `authenticateOAuthMock()`, `postEmergencyAlertMock()`
- Real OAuth methods: `authenticateOAuth()`, `postEmergencyAlert()` (STUBS)

**OAuth Parameters:**
```dart
TwitterOAuthService(
  apiKey: 'your-client-id',
  apiSecret: 'your-client-secret',
  redirectUri: 'guard://oauth-callback',
)
```

**Status:** ⚠️ STUB ONLY (mock works, real implementation needed)

---

### 10. **SocialMediaProvider**
📍 [lib/providers/social_media_provider.dart](lib/providers/social_media_provider.dart)

**Role:** State management for Twitter authentication and posting

**State Tracked:**
- `isAuthenticating` / `isTwitterConnected`
- `twitterUsername`
- `isPosting` / `lastPostId` / `lastPostText`
- `autoPostEnabled` - Feature toggle
- `error` - Error messages

**Key Methods:**
- `authenticateTwitterMock()` - Demo
- `authenticateTwitter()` - Real OAuth
- `postEmergencyAlert()` - Main pipeline
- `disconnectTwitter()` - Cleanup

**Status:** ✅ PARTIALLY READY (mock works, real OAuth pending)

---

## 📊 Models

### 11. **CommunityFeedModel**
📍 [lib/models/community_feed_model.dart](lib/models/community_feed_model.dart)

**CommunityFeedEntry Fields:**
```dart
- id, victimName, victimId
- location, state, country
- triggeredAt (DateTime)
- hashTag (e.g., "#findJaneOkafor")
- shareCount, retweetCount, impressions
- status: "active|resolved|archived"
- gemmaAssessment (optional)
```

**Key Methods:**
- `getTimeElapsed()` - Relative time since trigger
- `getDisplayLocation()` - Formatted location
- `getFeedMessage()` - Display message
- `copyWith()` - Immutable updates

**Status:** ✅ MODEL ONLY (no service yet - see "Missing Components")

---

### 12. **UserModel**
📍 [lib/models/user_model.dart](lib/models/user_model.dart)

**Status:** ✅ Basic user model present

---

## ⚙️ Configuration & Constants

### 13. **GemmaSystemPrompts**
📍 [lib/constants/gemma_system_prompts.dart](lib/constants/gemma_system_prompts.dart)

**Prompts Included:**
1. `emergencyThreatAssessment` - Main threat analysis prompt
2. `quickThreatCheck` - Fast binary decision
3. `audioAnalysis` - For audio/video files
4. `multimodalDemo` - Demonstrate Gemma 4 capabilities
5. `reasoningMode` - Step-by-step threat reasoning

**Features:**
- Extensive threat analysis framework
- Bias toward caution
- Cultural awareness
- Child safety considerations
- Domestic violence pattern recognition

**Status:** ✅ COMPLETE (ready for prompt injection)

---

### 14. **Main.dart Firebase Setup**
📍 [lib/main.dart](lib/main.dart#L1-L100)

**Firebase Initialization:**
```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
```

**Gemma Service Initialization:**
```dart
final gemmaMode = dotenv.env['GEMMA_MODE'] ?? 'openrouter'
final apiKey = dotenv.env['OPENROUTER_API_KEY'] ?? ''
final modelName = dotenv.env['OPENROUTER_MODEL'] ?? 'google/gemma-4-31b-it'
final gemmaService = GemmaThreatAssessmentService(apiKey, modelName)
```

**MultiProvider Setup:**
- `UserPreferencesProvider` (first)
- `GemmaProvider`
- `SocialMediaProvider`
- `UserProfileService`

**Status:** ✅ INITIALIZED (Firebase + Gemma service ready)

---

## 🔴 Missing Components (NOT YET IMPLEMENTED)

### ❌ 1. **ollama_config.dart** 
**Planned Location:** `lib/config/ollama_config.dart`

**What's Needed:**
```dart
class OllamaConfig {
  static const String HOST = 'http://localhost:11434';
  static const String MODEL = 'gemma:26b';
  static const double TEMPERATURE = 0.3;
  static const int MAX_TOKENS = 300;
}
```

**Why:** Phase 1 plan specifies Ollama local deployment for offline AI

---

### ❌ 2. **ollama_gemma_service.dart** 
**Planned Location:** `lib/services/ollama_gemma_service.dart`

**What's Needed:**
- Refactored version of `GemmaThreatAssessmentService`
- Uses Ollama HTTP endpoint instead of OpenRouter
- Payload format:
```dart
{
  "model": "gemma:26b",
  "prompt": "...",
  "stream": false,
  "temperature": 0.3,
}
```

**HTTP Endpoint:** `http://localhost:11434/api/generate`

---

### ❌ 3. **community_feed_service.dart** 
**Planned Location:** `lib/services/community_feed_service.dart`

**What's Needed:**
- CRUD operations for CommunityFeedEntry
- Firestore collection: `/communityFeed/{feedId}`
- Methods:
  - `createFeedEntry()` - From incident
  - `updateFeedEntry()` - Modify status/shares
  - `listActiveFeed()` - Real-time stream
  - `searchByHashTag()` - Find by hashtag
  - `getByState()` - Filter by state

**Current Gap:** Model exists, no service implementation

---

### ❌ 4. **twitter_oauth_real_implementation** 
**Location:** `lib/services/twitter_oauth_service.dart`

**What's Needed:**
- Real OAuth 2.0 flow (mock currently exists)
- Methods that need implementation:
  - `authenticateOAuth()` - Real OAuth flow
  - `postEmergencyAlert()` - Real tweet posting
  - `getUserInfo()` - Get username
- Use Twitter API v2 or v1.1 (depending on setup)

---

## 📊 Current API Integration State

| API | Status | Implementation | Notes |
|-----|--------|-----------------|-------|
| **OpenRouter (Gemma)** | ✅ ACTIVE | `GemmaThreatAssessmentService` | Cloud-based, requires API key |
| **Firebase Auth** | ✅ ACTIVE | `main.dart` | Anonymous + email/phone ready |
| **Firestore** | ✅ ACTIVE | `FirestoreIncidentService` + others | Real-time listeners working |
| **Cloud Messaging** | ✅ ACTIVE | Configured in main.dart | Not yet used in screens |
| **Twitter OAuth** | ⚠️ MOCK | `TwitterOAuthService` | Mock implementation only |
| **Ollama (Local)** | ❌ NOT YET | Planned in Phase 1 | Configuration missing |
| **Google AI Studio** | ⚠️ FALLBACK | Mentioned in code | Not primary integration |

---

## 🎯 Import Issues & Dependencies

### Current Imports in Services:
✅ All imports are resolvable:
- `package:http` - HTTP client (v1.1.0)
- `package:cloud_firestore` - Firestore (v6.3.0)
- `package:firebase_auth` - Auth (v6.4.0)
- `package:flutter_dotenv` - Environment variables (v6.0.0)
- `package:audioplayers` - Audio playback (v6.6.0)
- `package:provider` - State management (v6.0.0)

### Missing Dependencies for Full Implementation:
- ❌ `twitter_api` - For real Twitter OAuth
- ❌ `dio` or `http` enhancement - Better HTTP error handling (only http v1.1.0 present)
- ⚠️ `google_generative_ai` - Present but not used (v0.4.7)

---

## 🏗️ Architecture Overview

```
main.dart
  ├── Firebase Initialization
  ├── Gemma Service Initialization (OpenRouter)
  └── MultiProvider Setup
      ├── UserPreferencesProvider
      ├── GemmaProvider
      │   ├── GemmaThreatAssessmentService
      │   ├── FirestoreIncidentService
      │   └── GemmaDecisionEngine
      ├── SocialMediaProvider
      │   ├── SocialMediaPostingService
      │   └── TwitterOAuthService
      ├── UserProfileService
      └── Other Providers

Services Layer:
  ├── Threat Analysis (Gemma)
  │   └── GemmaThreatAssessmentService (OpenRouter)
  ├── Data Persistence (Firebase)
  │   ├── FirestoreIncidentService
  │   ├── UserProfileService
  │   └── ConfirmationSoundService
  ├── Escalation Logic
  │   ├── EscalationTimerService (T+5/30/60/90)
  │   └── GemmaDecisionEngine (threat → decision)
  ├── Social Media
  │   ├── SocialMediaPostingService
  │   └── TwitterOAuthService (mock)
  └── [MISSING] Community Feed Service

Models:
  ├── IncidentModel (Firestore)
  ├── UserModel
  ├── CommunityFeedEntry (no service)
  └── BackgroundListeningSettings
```

---

## ✅ Summary: What's Ready vs What Needs Work

### Ready for Deployment (✅)
- Threat assessment (OpenRouter + mock fallback)
- Firebase initialization (Auth, Firestore, Messaging)
- Escalation timer (3-tier countdown logic)
- Incident logging to Firestore
- User profile management
- Gemma decision engine (threat → escalation)
- Confirmation sound playback

### Ready for Testing (⚠️)
- Social media pipeline (mock only)
- Twitter OAuth (mock implementation)
- Community feed model (no CRUD)

### Need Implementation (❌)
- Ollama configuration and service
- Community feed CRUD service
- Real Twitter OAuth flow
- Real Twitter posting

### Phase 1 Deliverables (Per ESTHER_PHASE_1_BRAIN_NERVOUS_SYSTEM.md)
- [ ] Ollama installation verification
- [ ] `ollama_config.dart` creation
- [ ] `ollama_gemma_service.dart` refactor
- [ ] Community feed service
- [ ] Integration tests

---

## 📁 File Structure Summary

```
lib/
├── main.dart (Firebase + Gemma initialization)
├── theme.dart
├── services/
│   ├── gemma_threat_assessment_service.dart ✅
│   ├── gemma_decision_engine.dart ✅
│   ├── firestore_incident_service.dart ✅
│   ├── escalation_timer_service.dart ✅
│   ├── user_profile_service.dart ✅
│   ├── social_media_posting_service.dart ⚠️
│   ├── twitter_oauth_service.dart ⚠️
│   ├── confirmation_sound_service.dart ✅
│   └── [MISSING] community_feed_service.dart
├── providers/
│   ├── gemma_provider.dart ✅
│   ├── social_media_provider.dart ⚠️
│   └── user_preferences_provider.dart ✅
├── models/
│   ├── community_feed_model.dart ✅
│   ├── user_model.dart ✅
│   └── background_listening_settings.dart ✅
├── constants/
│   └── gemma_system_prompts.dart ✅
├── config/
│   └── [MISSING] ollama_config.dart
├── screens/ (UI layer)
├── widgets/ (UI components)
└── [MISSING] lib/services/ollama_gemma_service.dart
```

---

## 🚀 Next Steps (Prioritized)

1. **URGENT (Phase 1)**: Create `ollama_config.dart`
2. **URGENT (Phase 1)**: Implement `community_feed_service.dart`
3. **HIGH (Phase 1)**: Refactor to `ollama_gemma_service.dart`
4. **MEDIUM (Phase 2)**: Real Twitter OAuth integration
5. **LOW (Phase 3)**: Additional API providers (Google AI, etc.)

---

**Generated:** April 20, 2026  
**For:** Esther (AI & Data Lead), Echo Development Team

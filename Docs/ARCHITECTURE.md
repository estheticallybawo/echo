# Guardian App - Architecture & Implementation Guide

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        FLUTTER UI LAYER                         │
│  (HomeScreen, EmergencyActiveScreen, OnboardingFlow, etc.)      │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│                    SERVICE LAYER (Dart/Kotlin/Swift)            │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Core Services                                            │   │
│  │ - VoiceRecognitionService (E2B Gemma 2B-IT)            │   │
│  │ - LocationTrackerService (GPS + Cell)                   │   │
│  │ - EmergencyStateManager (coordinate activation)         │   │
│  │ - AudioRecorderService (capture + pre-buffer)           │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Integration Services                                     │   │
│  │ - GemmaAnalysisService (API streaming)                  │   │
│  │ - NotificationService (SMS + WhatsApp)                  │   │
│  │ - ContactNotifier (broadcast alerts)                    │   │
│  │ - ConfirmationSoundSystem (audio + haptic)              │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Data Services (May 17 MVP)                               │   │
│  │ - ContactRepository (contact storage + encryption)      │   │
│  │ - PreferencesService (user settings + voice phrase)     │   │
│  │ - EncryptionService (AES-256, key management)           │   │
│  │                                                          │   │
│  │ Data Services (POST-LAUNCH)                             │   │
│  │ - IncidentRepository (Hive/Isar persistence) ⏸️         │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Native Method Channels                                   │   │
│  │ - Android: Haptic feedback, foreground service          │   │
│  │ - iOS: CoreHaptics, AVAudioSession background modes     │   │
│  └──────────────────────────────────────────────────────────┘   │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                 ┌─────────┼─────────┐
                 ↓         ↓         ↓
        ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
        │   EXTERNAL   │ │   DATABASE   │ │   DEVICE OS  │
        │     APIs     │ │              │ │              │
        ├──────────────┤ ├──────────────┤ ├──────────────┤
        │ • Gemma API  │ │ • Hive       │ │ • Microphone │
        │ • Google     │ │ • Isar       │ │ • GPS/Cell   │
        │   Places     │ │ • Encrypted  │ │ • Vibrator   │
        │ • Twilio SMS │ │   storage    │ │ • AudioFocus │
        │ • WhatsApp   │ │              │ │ • Contacts   │
        │   API        │ │              │ │ • Background │
        │ • Firebase   │ │              │ │   service    │
        │   FCM        │ │              │ │              │
        │ • Twitter    │ │              │ │              │
        │   API        │ │              │ │              │
        └──────────────┘ └──────────────┘ └──────────────┘
```

---

## Service Class Hierarchy & Dependencies

### 1. Core Emergency Services

#### VoiceRecognitionService
```dart
// lib/services/voice_recognition_service.dart

class VoiceRecognitionService {
  // RESPONSIBILITIES:
  // - Initialize E2B Gemma 2B-IT model (lazy load during onboarding)
  // - Listen to microphone stream continuously (background + foreground)
  // - Process audio in near-real-time chunks (500ms)
  // - Match audio against user's recorded safety phrase
  // - Calculate confidence score (>85% = activation)
  
  Future<void> initialize() async {
    // Load Gemma 2B-IT model (~500MB)
    // Set up audio session (category: record, mode: measurement)
    // Start background listener if granted permissions
  }
  
  Stream<VoiceRecognitionEvent> startListening() {
    // Yields: VoiceRecognitionEvent with confidence + timestamp
    // Triggered => EmergencyActivationService.handleActivation()
  }
  
  Future<void> recordUserPhrase(String phrase) async {
    // Save user's unique safety phrase
    // Used during onboarding (page 3)
  }
  
  // Dependencies:
  // - e2b_flutter (edge model runner)
  // - speech_to_text
  // - audio_session
  // - geolocator (check if in high-risk location)
}
```

#### LocationTrackerService
```dart
// lib/services/location_tracker_service.dart

class LocationTrackerService {
  // RESPONSIBILITIES:
  // - Capture GPS coordinates with high accuracy (>10m)
  // - Fall back to cell triangulation if GPS unavailable
  // - Stream location updates during emergency (every 5-30s)
  // - Validate location before storing
  
  Stream<LocationSnapshot> startTracking({
    required Duration updateInterval,  // 5s during emergency, 30s normal
    required LocationAccuracy accuracy,  // highAccuracy during emergency
  }) {
    // Yields: LocationSnapshot(lat, lon, accuracy, timestamp)
  }
  
  Future<LocationSnapshot> getCurrentLocation() async {
    // One-time location capture (used during system test)
  }
  
  // Dependencies:
  // - geolocator
  // - permission_handler
  // - location_to_address (reverse geocoding)
}
```

#### EmergencyStateManager
```dart
// lib/state/emergency_state_manager.dart

class EmergencyStateManager extends ChangeNotifier {
  // RESPONSIBILITIES:
  // - Central state machine coordinating all emergency services
  // - Ensure atomicity (all-or-nothing activation)
  // - Handle state transitions: idle → triggered → active → resolved
  
  // States:
  // 1. IDLE: Normal operation
  // 2. TRIGGERED: Voice detected, waiting for confirmation
  // 3. ACTIVE_EMERGENCY: Full activation, services running
  // 4. PAUSED: User in fake call, background
  // 5. RESOLVED: User cancelled or completed
  
  Future<void> handleVoiceTriggered(VoiceRecognitionEvent event) async {
    // 1. Request location snapshot
    // 2. Start audio capture (pre-buffer + live)
    // 3. Create EmergencySession record
    // 4. Notify all subscribers (trigger UI)
    // 5. Navigate to emergency_active_screen
  }
  
  Future<void> activateEmergency(EmergencySession session) async {
    // 1. Validate session data
    // 2. Start: location tracking, Gemma analysis, notification queue
    // 3. Begin WhatsApp alerting to Tier 1 contacts
    // 4. Begin social media posting queue
  }
  
  Future<void> cancelEmergency(String reason) async {
    // 1. Stop all services (location, audio, Gemma stream)
    // 2. Send cancellation notification to contacts
    // 3. Return to home screen

  }
  
  // Dependencies (May 17 MVP):
  // - VoiceRecognitionService
  // - LocationTrackerService
  // - AudioRecorderService
  // - GemmaAnalysisService
  // - NotificationService
  // - SocialMediaPostingService
}
```

---

### 2. Integration Services

#### GemmaAnalysisService
```dart
// lib/services/gemma_analysis_service.dart

class GemmaAnalysisService {
  // RESPONSIBILITIES:
  // - Stream incident analysis in real-time as user speaks
  // - Generate: threat assessment, incident type, auto-post text
  // - Use audio transcription + context to analyze danger level
  
  Stream<String> analyzeIncident({
    required AudioStream audioStream,
    required LocationSnapshot location,
    required String userContext,  // e.g., "at bar, male approaching"
  }) {
    // Yields: Streamed text response from Gemma 4
    // System prompt: analyze for immediate danger, classification
    // 
    // Example response:
    // "Threat Level: HIGH\n
    //  Estimated danger: aggressive male in enclosed space\n
    //  Recommended action: CALL POLICE immediately\n
    //  Alert neighbors: YES"
  }
  
  Future<String> generateAutoPost({
    required String analysis,
    required LocationSnapshot location,
    required bool includeAddress,  // false for anonymity
  }) async {
    // Generate Twitter/public alert version (no sensitive data)
    // Example: "Safety Alert: Suspicious activity reported in [area]. 
    //          If you see anything unusual, contact police @[number]"
  }
  
  // Dependencies:
  // - google_generative_ai (Gemma API client)
  // - TranscriptionService (convert audio to text)
}
```

#### NotificationService
```dart
// lib/services/notification_service.dart

class NotificationService {
  // RESPONSIBILITIES:
  // - Broadcast emergency alerts to tier-1/tier-2 contacts
  // - Support: SMS, WhatsApp, push notifications
  // - Track delivery status + retry on failure
  
  Future<NotificationResult> notifyContacts({
    required List<Contact> tierOneContacts,
    required LocationSnapshot location,
    required String incidentType,
  }) async {
    // For each contact:
    // 1. Try SMS (universal, always works)
    // 2. If contact has WhatsApp, send rich WhatsApp message + map
    // 3. Log delivery status (sent/delivered/failed)
    // 4. Retry failed messages after 30s, 5min, 15min
    
    // Message template:
    // "EMERGENCY ALERT: [Name] needs help at [Location]
    //  [Google Maps URL]
    //  Police contacted: YES
    //  Reply: I'm coming / Already there / Can't help"
  }
  
  // Dependencies:
  // - twilio_flutter (SMS)
  // - whatsapp_flutter or REST API
  // - workmanager (background retry jobs)
}
```

#### ConfirmationSoundSystem (Already Exists)
```dart
// lib/services/confirmation_sound_system.dart

class ConfirmationSoundSystem {
  // ALREADY IMPLEMENTED
  // - Maps action types to audio + haptic patterns
  // - Called by EmergencyStateManager after each action
  
  enum ConfirmationActionType {
    police_called,          // Police dispatch initiated
    tweet_posted,           // Public alert posted
    en_route,               // Contact status: coming to help
    public_post_live,       // Alert live on social media
    contact_notified,       // Sent to specific contact
    emergency_stopped,      // User cancelled
  }
  
  Future<void> playConfirmation(ConfirmationActionType action) async {
    // AUDIO: Pre-recorded for each action
    // HAPTIC: Custom pattern via native channels
    // Example for police_called:
    //   Audio: "Police contacted" (Serene Chime sound)
    //   Haptic: Double pulse (100ms on, 50ms off, 100ms on)
  }
}
```

---

### 3. Data Services

#### IncidentRepository ⏸️ DEFERRED POST-LAUNCH
```dart
// lib/data/repositories/incident_repository.dart

class IncidentRepository {
  // RESPONSIBILITIES:
  // - CRUD operations on incidents (Hive/Isar backend)
  // - Search, filter, sort incidents
  // - Archive/delete old incidents
  // - Export incidents to PDF
  // ⏸️  All functionality deferred to post-launch
  
  Future<void> createIncident(EmergencySession session) async {
    // Save incident with:
    // - ID, timestamp, location (encrypted)
    // - Audio file path (encrypted)
    // - Transcript (encrypted)
    // - Gemma analysis
    // - Alert recipient list + delivery status
    // - Status (active/resolved/false-alarm)
    // - User notes
  }
  
  Stream<List<Incident>> watchIncidents({
    required IncidentFilter filter,  // date range, status, location radius
  }) {
    // Real-time stream for IncidentLogScreen
  }
  
  Future<Incident> getIncidentDetail(String incidentId) async {
    // Include full analysis, map data, transcript
  }
  
  // Dependencies:
  // - isar or hive
  // - flutter_secure_storage (encryption keys)
}
```

#### ContactRepository
```dart
// lib/data/repositories/contact_repository.dart

class ContactRepository {
  // RESPONSIBILITIES:
  // - Store contacts locally with tier levels
  // - Import from device contacts
  // - Validate phone numbers
  // - Search and filter
  
  Future<void> addContact({
    required String name,
    required String phone,
    required ContactTier tier,  // tier1, tier2
    String? relationship,
  }) async {
    // Validate phone number (international format)
    // Encrypt phone before storing
    // Deduplicate (check if contact already exists)
  }
  
  Stream<List<Contact>> watchTierContacts(ContactTier tier) {
    // Real-time stream for ContactsScreen
  }
  
  // Dependencies:
  // - isar or hive
  // - flutter_secure_storage
}
```

#### EncryptionService
```dart
// lib/services/encryption_service.dart

class EncryptionService {
  // RESPONSIBILITIES:
  // - Manage encryption keys (stored in secure enclave)
  // - Encrypt/decrypt sensitive data
  // - Used by: ContactRepository (May 17 MVP)
  // - Used by: IncidentRepository (⏸️ POST-LAUNCH)
  
  Future<String> encryptData(String plaintext) async {
    // AES-256-GCM encryption
    // Generate/retrieve key from secure storage
    // Return: base64-encoded ciphertext
  }
  
  Future<String> decryptData(String ciphertext) async {
    // Reverse process
  }
  
  // Dependencies:
  // - pointycastle (AES encryption)
  // - flutter_secure_storage (key storage)
}
```

---

## Data Models

### Core Models

```dart
// lib/models/emergency_session.dart

class EmergencySession {
  final String id;
  final DateTime triggeredAt;
  final LocationSnapshot locationAtTrigger;
  final String userPhrase;  // Matched voice phrase
  final double voiceConfidence;  // 0-1, >0.85 = activation
  final List<String> audioFilePathes;  // Pre-buffer + live
  final String? transcript;  // From STT
  final String? gemmaAnalysis;  // Streamed from API
  final IncidentType? classifiedType;  // Police, medical, assault, etc.
  final ThreatLevel threatLevel;  // LOW, MEDIUM, HIGH, CRITICAL
  final List<NotificationLog> contactAlerts;  // Who was notified
  final List<String> postUrls;  // Social media posts
  final IncidentStatus status;  // active, resolved, false-alarm
  final String? userNotes;  // User added notes post-incident
  
  // Computed
  Duration get duration => DateTime.now().difference(triggeredAt);
  bool get isResolved => status != IncidentStatus.active;
}

enum ThreatLevel { LOW, MEDIUM, HIGH, CRITICAL }
enum IncidentStatus { active, resolved, false_alarm, cancelled }
enum IncidentType { assault, robbery, harassment, medical, other }

class NotificationLog {
  final Contact contact;
  final String phoneNumber;
  final NotificationMethod method;  // sms, whatsapp, fcm
  final NotificationStatus status;  // sent, delivered, failed
  final DateTime sentAt;
  final DateTime? deliveredAt;
  final String? errorMessage;
}

enum NotificationMethod { sms, whatsapp, fcm }
enum NotificationStatus { pending, sent, delivered, failed }
```

---

## Service Initialization & Dependency Injection

### App Initialization Sequence

```dart
// lib/main.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize local storage (May 17 MVP)
  await Hive.initFlutter();
  // ⏸️  await Hive.openBox<Incident>('incidents');  DEFERRED to post-launch
  await Hive.openBox<Contact>('contacts');
  
  // 2. Initialize encryption
  final encryptionService = EncryptionService();
  await encryptionService.initialize();
  
  // 3. Initialize repositories (May 17 MVP)
  // ⏸️  final incidentRepository = IncidentRepository(encryptionService);  DEFERRED
  final contactRepository = ContactRepository(encryptionService);
  
  // 4. Initialize location tracking
  final locationTracker = LocationTrackerService();
  await locationTracker.requestPermissions();
  
  // 5. Initialize voice recognition (LAZY - during onboarding page 3)
  // Do NOT load E2B model on startup (500MB)
  
  // 6. Create state managers
  final emergencyManager = EmergencyStateManager(
    voiceService: null,  // Will be set during onboarding
    locationTracker: locationTracker,
    // ⏸️  incidentRepository DEFERRED to post-launch
    contactRepository: contactRepository,
  );
  
  // 7. Run app with provider setup
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => emergencyManager),
        // ⏸️  Provider<IncidentRepository> DEFERRED to post-launch
        Provider<ContactRepository>(create: (_) => contactRepository),
        Provider<LocationTrackerService>(create: (_) => locationTracker),
        // ... other services
      ],
      child: const GuardianApp(),
    ),
  );
}
```

---

## Integration Workflows

### Emergency Activation Workflow

```
User says safety phrase
    ↓
VoiceRecognitionService detects phrase (confidence > 85%)
    ↓
Yields VoiceRecognitionEvent with confidence + timestamp
    ↓
EmergencyStateManager.handleVoiceTriggered()
    ↓
1. LocationTrackerService.getCurrentLocation()  [Snapshot at trigger]
2. AudioRecorderService.startCapture()           [Begin recording]
3. Create EmergencySession object
4. Notify all subscribers (ChangeNotifier)
    ↓
UI: EmergencyActiveScreen appears
    ↓
5. GemmaAnalysisService.analyzeIncident()        [Start streaming analysis]
6. LocationTrackerService.startTracking()        [Begin continuous tracking]
    ↓
User sees:
- Live recording timer
- Streamed Gemma analysis
- Location indicator
- "Cancel" button
    ↓
[After user confirms or timed out]
    ↓
EmergencyStateManager.activateEmergency()
    ↓
1. NotificationService.notifyContacts()          [SMS/WhatsApp to tier-1]
2. ConfirmationSoundSystem.play(police_called) + haptic
3. PublicAlertService.postToSocialMedia()        [If user consented]
4. ⏸️  IncidentRepository.createIncident() DEFERRED [Save to local DB]
5. ConfirmationSoundSystem.play(tweet_posted)
    ↓
User sees confirmation screen with:
- "Police en route" / "Contacts notified"
- Map showing live location
- List of who was told
    ↓
[User can add notes, view Gemma analysis, see contact ETA]
    ↓
User closes: EmergencyStateManager.resolveEmergency()
    ↓
1. Stop all services (location, audio, Gemma stream)
2. Generate incident summary
3. Clear session
4. Return to HomeScreen
```

---


### Contact Box/Collection
```
contacts
├─ id: String (primary key)
├─ name: String
├─ phone: String (encrypted)
├─ tier: String (tier1, tier2)
├─ relationship: String (optional)
├─ created_at: DateTime
├─ last_notified: DateTime
├─ notification_count: int
└─ notes: String
```

### Settings Box/Collection
```
settings
├─ voice_phrase: String (encrypted)
├─ auto_post_enabled: boolean
├─ notification_method_sms: boolean
├─ notification_method_whatsapp: boolean
├─ confirmation_sound_type: String
├─ vibration_enabled: boolean
├─ location_update_interval_ms: int
├─ dark_mode_enabled: boolean
├─ battery_saver_mode: boolean
└─ last_system_test: DateTime
```

---

## Error Handling & Fallbacks

### Critical Path Fallbacks

```dart
class FallbackStrategy {
  // 1. VOICE RECOGNITION FAILS
  //    Fallback: Tap SOS button (manual activation)
  //    UI shows: "Tap SOS if you can't speak"
  
  // 2. LOCATION FAILS
  //    Fallback: Cell triangulation or last known location
  //    Risk: Less accurate, but still useful
  //    Notify: "Location accuracy reduced"
  
  // 3. GEMMA API FAILS
  //    Fallback: Simple classification (loud sounds = danger)
  //    Risk: Less intelligent analysis
  //    Notify: "Analysis unavailable, basic alerts sent"
  
  // 4. SMS/WHATSAPP FAILS
  //    Fallback: Try other contact method
  //    Behavior: SMS timeout = 10s, then try next contact
  //    Retry: Automatic after 30s, 5min, 15min
  
  // 5. AUDIO CAPTURE FAILS
  //    Fallback: Text-only incident (no transcript)
  //    Risk: No voice evidence
  //    Notify: "Microphone not available"
}
```

---

## Security Considerations

### Data Encryption

```
┌─ Sensitive Data Requiring Encryption ─────────────────────┐
│ ✓ Phone numbers (contacts)                                │
│ ✓ Audio files (recorded emergency)                        │
│ ✓ Transcripts (what user said)                            │
│ ✓ Incident location coordinates (privacy)                 │
│ ✓ Voice phrase (user's safety words)                      │
│ ✓ Encryption keys (stored in Secure Enclave/Keyguard)     │
│                                                             │
│ ✗ Incident status (who cares if it's "resolved")          │
│ ✗ Contact names (not sensitive by themselves)             │
│ ✗ User preferences (non-identifying)                      │
└─────────────────────────────────────────────────────────────┘
```

### Secure Storage

- **Android**: Keystore2 (since Android 9)
- **iOS**: Secure Enclave or Keychain
- **Dart**: `flutter_secure_storage` handles both

### Network Security

- HTTPS only (no HTTP)
- Certificate pinning for API calls (if high security needed)
- Never log API keys, phone numbers, locations

---

## Testing Strategy

### Unit Tests per Service

```
tests/
├─ services/
│  ├─ voice_recognition_service_test.dart
│  ├─ location_tracker_service_test.dart
│  ├─ emergency_state_manager_test.dart
│  ├─ notification_service_test.dart
│  ├─ gemma_analysis_service_test.dart
│  └─ encryption_service_test.dart
├─ repositories/
│  ├─ incident_repository_test.dart
│  └─ contact_repository_test.dart
└─ models/
   ├─ emergency_session_test.dart
   └─ contact_test.dart
```

### Integration Tests

```
tests/integration/
├─ emergency_activation_flow_test.dart
│  └─ Test: voice trigger → location capture → notification → database
├─ offline_sync_test.dart
│  └─ Test: app works without internet, syncs when online
└─ encryption_integrity_test.dart
   └─ Test: encrypted data stays encrypted, decrypts correctly
```

### Mock External Services

```dart
// tests/mocks/mock_gemma_service.dart
class MockGemmaAnalysisService extends GemmaAnalysisService {
  @override
  Stream<String> analyzeIncident({...}) {
    // Return canned response for testing
    return Stream.value("Threat Level: HIGH\n...");
  }
}

// tests/mocks/mock_notification_service.dart
class MockNotificationService extends NotificationService {
  @override
  Future<NotificationResult> notifyContacts({...}) async {
    // Simulate successful notification without real SMS
    return NotificationResult(sentCount: 3, failedCount: 0);
  }
}
```

---

## Deployment Strategy

### Pre-Deployment Checklist

```
BEFORE RELEASE:
☐ All unit tests passing (>80% coverage)
☐ All integration tests passing
☐ No critical bugs in issue tracker
☐ Encryption keys properly secured
☐ API keys [NOT committed to repo, use environment variables]
☐ Privacy policy reviewed & updated
☐ Audio files not backed up to cloud
☐ Permissions properly documented

ANDROID RELEASE:
☐ Signed APK with release keystore
☐ version code incremented in pubspec.yaml
☐ Play Store release notes updated
☐ Screenshots + description updated

IOS RELEASE:
☐ Built for iOS devices
☐ App Store certificate + provisioning profile valid
☐ Version bumped in iOS build settings
☐ App Store listing updated
```

---

## Common Patterns & Best Practices

### StateNotifier Pattern

```dart
// Use ChangeNotifier for global state
class EmergencyStateManager extends ChangeNotifier {
  void handleStateChange() {
    // Update internal state
    // Call notifyListeners() to rebuild widgets
    notifyListeners();
  }
}

// In widgets:
Consumer<EmergencyStateManager>(
  builder: (context, emergencyManager, child) {
    if (emergencyManager.isEmergencyActive) {
      return EmergencyActiveScreen();
    }
    return HomeScreen();
  },
)
```

### Stream Pattern (for real-time data)

```dart
// Services expose streams for continuous updates
class LocationTrackerService {
  Stream<LocationSnapshot> startTracking() {
    return _geolocator.getPositionStream(...).map(...);
  }
}

// In widgets:
StreamBuilder<LocationSnapshot>(
  stream: locationTracker.startTracking(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return MapWidget(location: snapshot.data);
    }
    return LoadingWidget();
  },
)
```

### Repository Pattern (for data access)

⏸️ **Note**: May 17 MVP uses **ContactRepository** only. **IncidentRepository** is shown as example for POST-LAUNCH.

```dart
// Abstract away database/API details

// ⏸️ POST-LAUNCH ONLY: IncidentRepository (deferred)
abstract class IncidentRepository {
  Stream<List<Incident>> watchIncidents(IncidentFilter filter);
  Future<void> createIncident(EmergencySession session);
}

// Implementation + encryption hidden
// ⏸️ POST-LAUNCH ONLY
class HiveIncidentRepository implements IncidentRepository {
  // Internally handles Hive, encryption, etc.
}

// May 17 MVP: ContactRepository
abstract class ContactRepository {
  Stream<List<Contact>> watchTierContacts(ContactTier tier);
  Future<void> addContact({required String name, required String phone, required ContactTier tier});
}
```

---

## Next Steps for Team

1. **Read This Document** - Understand the overall architecture
2. **Review FEATURES.md** - See the complete feature list
3. **Check TASK_TRACKING.md** - Know which branches to create
4. **Clone Repository** - `git clone <repo>`
5. **Create Feature Branch** - `git checkout -b feature/<your-feature>`
6. **Implement Service** - Follow the patterns shown above
7. **Write Tests** - Follow the testing strategy
8. **Create PR** - Link to related issue, get reviewed
9. **Merge** - Celebrate your contribution!

---

## Questions?

- **Architecture questions**: See the diagrams above
- **Service implementation**: Reference similar services already exists (ConfirmationSoundSystem)
- **Database schema**: Follow the Hive/Isar patterns above
- **Testing approach**: Use mocks and dependency injection
- **Deployment**: Check the pre-deployment checklist

Good luck! 🚀

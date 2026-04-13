# Echo App - Complete Feature & Implementation Roadmap

 **TIMELINE UPDATE (April 8, 2026) — MAY 17 HARD DEADLINE**
- **Submission Deadline**: May 17, 2026 (Kaggle Hackathon — NO EXTENSION)
- **This document is a REFERENCE CHECKLIST ONLY** — see **[MVPONLY.md](MVPONLY.md)** for the actual execution plan + timeline
- **6 FEATURES SHIP BY MAY 17** (marked with 🚀 below)
- **2 WOW FACTORS** (marked with ✨ below): Emotion Detection + Gemma Threat Assessment
- **ALL OTHER FEATURES DEFERRED** to post-launch (marked with ⏸️ below)

---

## MAY 17 MVP FEATURES (What Customers Will See)

| # | Feature | Status | WOW? |
|---|---------|--------|------|
| 1 | Voice Phrase Recognition | 🚀 Shipping | — |
| 2 | 2-Tier Emergency Escalation | 🚀 Shipping | — |
| 3 | Gemma 4 Threat Assessment | 🚀 Shipping | ✨ WOW #2 |
| 4 | Real-Time Emotion Detection | 🚀 Shipping | ✨ WOW #1 |
| 5 | Social Media Auto-Posting | 🚀 Shipping | — |
| 6 | WhatsApp Alert + Proof | 🚀 Shipping | — |

---

## Overview
Echo is a discreet, AI-powered community safety app designed for real-time emergency response and incident analysis.

**For May 17 MVP Execution Plan**, see [MVPONLY.md](MVPONLY.md) — that is the single source of truth for shipping features, timeline, and team assignments.

---

## THE 6-PHASE USER FLOW (Why We Built It This Way)

### Phase 1: Onboarding (~5 minutes)
User setup: add 3-5 emergency contacts (Tier 1), record voice phrase, grant permissions, opt into social posting, practice system test.
- ✅ **UI complete** in `onboarding_flow.dart`
- ✅ **Services to implement**: Contact validation, voice phrase recording, permission requests

### Phase 2: Background Listening (Always On)
App listens silently for voice phrase in background. No battery drain, no privacy concerns (fully on-device with E2B).
- ✅ **Feature**: VoiceRecognitionService with E2B Gemma 2B-IT
- ✅ **Target**: <5% battery impact per hour

### Phase 3: Emergency Activation (<2 seconds)
Voice phrase detected → emergency screen appears → Gemma begins analyzing audio in real-time → emotion gauge shows fear level
- ✅ **WOW #1**: Emotion Detection (local TensorFlow Lite model shows panic level)
- ✅ **Features**: EmergencyActivationManager, EmotionDetectionService

### Phase 4: 2-Tier Escalation (30 seconds total)
- **T=0-5s**: Send WhatsApp to Tier 1 (inner circle 3-5 contacts) with location + 15s proof audio + Gemma threat type
- **T=5-30s**: Tier 1 responds? Escalation stops. No response? Proceed to Tier 2.
- **T=30s**: Send WhatsApp to Tier 2 (extended network 5-10 contacts) with same proof
- **WOW #2**: Gemma threat assessment ("This is a kidnapping, 92% confidence, call police") included in EVERY alert
- ✅ **Features**: EscalationManager (FSM), WhatsAppService, GemmaThreatAssessment

### Phase 5: Closure
User marks self safe → emergency ends → all contacts notified "Esther is safe" → minimal data stored locally (no trauma re-exposure)


### Phase 6: Social Layer
Emergency auto-posts to user's Twitter: "🚨 EMERGENCY at [address]. [Threat type]. Help needed. #EmergencyAlert"
- ✅ **Feature**: Social media auto-posting (no mass adoption needed, just user's followers see it)

---

# FEATURES SHIPPING BY MAY 17 🚀

## 1. CORE EMERGENCY ACTIVATION (Priority: P0 - Critical)

### 1.1 Voice Phrase Recognition
**Purpose**: Silent, hands-free emergency activation without drawing attention

**Implementation Requirements**:
- [ ] Voice phrase recording during onboarding (already UI)
- [ ] Local speech recognition using Gemma 2B-IT (E2B edge model)
- [ ] Background audio listener (always-on, even when app is backgrounded)
- [ ] Noise filtering to reduce false positives
- [ ] Phrase matching with confidence threshold (>85%)

**Tech Stack**:
- Package: `speech_to_text` + `audio_session` for background streaming
- E2B API client for Gemma 2B-IT running locally
- Native method channels (Android AudioRecord, iOS AVAudioEngine)

**Deliverables**:
- [ ] VoiceRecognitionService class with background listener
- [ ] E2B model initialization (lazy loaded during onboarding)
- [ ] Confidence scoring and false-positive filtering
- [ ] Unit tests for phrase matching accuracy

**Branch**: `feature/voice-activation`

---

### 1.2 Emergency Activation Trigger
**Purpose**: Convert voice detection → captured state with timestamp, location, audio logs

**Implementation Requirements**:
- [ ] Handle voice phrase recognition event
- [ ] Capture audio stream (5 seconds before + 30 seconds after detection)
- [ ] Record timestamp and geolocation immediately
- [ ] Trigger emergency active screen (already UI)
- [ ] Lock device to prevent accidental cancellation (UX safeEcho)

**Tech Stack**:
- Package: `record` for audio capture
- `geolocator` for location snapshot
- SharedPreferences for session metadata

**Deliverables**:
- [ ] EmergencySession model (audio_buffer, location, timestamp, phrase_confidence)
- [ ] EmergencyStateManager (singleton managing activation state)
- [ ] Audio capture service with ring buffer (5s pre-event)
- [ ] Integration tests for state transitions

**Branch**: `feature/emergency-activation`

---

## 2. LOCATION TRACKING (Priority: P0 - Critical)

### 2.1 Real-Time Location Capture
**Purpose**: Persistent location tracking for alert recipients and police dispatch

**Implementation Requirements**:
- [ ] Continuous location updates (every 5-30 seconds during emergency)
- [ ] High-accuracy GPS (>10m accuracy) + fallback to cell triangulation
- [ ] Battery-efficient background location service
- [ ] Permission handling (location access on iOS/Android)
- [ ] Graceful degradation if location unavailable

**Tech Stack**:
- Package: `geolocator` (high accuracy + permissions)
- Native background service (foreground notification on Android)
- Native background modes on iOS

**Deliverables**:
- [ ] LocationTracker service class with background stream
- [ ] ForegroundService implementation for Android (persistent notification)
- [ ] Background modes configuration for iOS
- [ ] Accuracy validation and fallback logic
- [ ] Unit tests (mock location providers)

**Branch**: `feature/location-tracking`

---

### 2.2 Location History & Map Visualization (⏸️ DEFERRED POST-LAUNCH)

**Why deferred for May 17?** MVP captures one-time location at emergency activation only (not continuous tracking). Continuous tracking adds complexity and battery drain. Post-launch, we'll add active tracking with contact-shared location updates.

**Implementation Requirements**:
- [ ] Store location waypoints with timestamps (in app-local database)
- [ ] Display incident map with user path
- [ ] Search/filter incidents by location radius
- [ ] Proximity-based contact suggestions

**Tech Stack**:
- Package: `flutter_map` or `google_maps_flutter`
- Hive/Isar for local location history
- Polyline drawing for routes

**Deliverables**:
- [ ] MapScreen showing incident routes
- [ ] LocationHistory model + Hive adapter
- [ ] Proximity calculation service
- [ ] Integration tests with mock maps

**Branch**: `feature/location-history`

---

## 3. AI ANALYSIS & INCIDENT GENERATION (Priority: P0 - Critical)

⭐ **2 WOW FACTORS SHIPPING HERE** ⭐

### 3.1 Real-Time Emotion Detection (✨ WOW FACTOR #1)
**Priority**: P0 - Shipping by May 17
**Purpose**: Detect user panic/fear from voice → auto-trigger police dispatch if panic >70%

**Impact on User Flow**: In Phase 3 (Emergency Activation), emotion gauge shows live fear level (0-100). If hits >70%, automatically sends SMS to police dispatcher without waiting for contact confirmation.

**Implementation Requirements**:
- [ ] Load TensorFlow Lite emotion detection model (local, offline, <500ms inference)
- [ ] Analyze 20-second audio buffer from voice activation
- [ ] Classify: calm (0-30), concerned (30-60), panic/fear (60-100)
- [ ] If panic >70% → auto-send emergency SMS to police
- [ ] Display emotion confidence on EmergencyActiveScreen (live updating gauge)

**Tech Stack**:
- Package: `tflite_flutter` (emotion detection model)
- OR: `google_generative_ai` with emotion prompt (slower, but more accurate)
- Local on-device = instant response, no API latency

**Deliverables**:
- [ ] EmotionDetectionService with model loading
- [ ] Feature extraction from audio
- [ ] Confidence scoring + threshold logic
- [ ] Auto-police trigger on panic >70%
- [ ] UI gauge showing emotion level (live)
- [ ] Unit tests with mock audio

**Branch**: `feature/emotion-detection`

**Why it's a WOW Factor**: Shows AI truly understands user intent (panic/danger) even if they can't speak clearly during emergency. Most impressive + defensible for Kaggle judges.

---

### 3.2 Real-Time Gemma 4 Threat Assessment (✨ WOW FACTOR #2)
**Priority**: P0 - Shipping by May 17
**Purpose**: Analyze emergency audio → identify threat type + confidence + action recommendation

**Impact on User Flow**: In Phase 4 (Escalation), every WhatsApp alert to Tier 1/2 includes Gemma summary: "🚨 Kidnapping detected - 92% confidence - CALL POLICE"

**Implementation Requirements**:
- [ ] Stream voice data to Gemma 4 API (with audio transcription first)
- [ ] System prompt: "Analyze this emergency audio. Detect: threat type (kidnapping, assault, medical, fire, etc.), confidence (0-100%), recommended action"
- [ ] Response: structured JSON with threat_type, confidence, action
- [ ] Include confidence in WhatsApp alert to contacts
- [ ] Display on EmergencyActiveScreen (streaming text response)

**Tech Stack**:
- Package: `google_generative_ai` (Gemma API client)
- Audio transcription first (speech-to-text), then context to Gemma
- StreamBuilder for real-time text updates

**Deliverables**:
- [ ] GemmaThreatAssessmentService with streaming support
- [ ] Prompt engineering (system prompt for threat analysis)
- [ ] Response parsing: threat_type, confidence, action
- [ ] Integration with WhatsApp alerts (include summary)
- [ ] Error handling and timeout management
- [ ] Unit tests with mocked Gemma API

**Branch**: `feature/gemma-threat-assessment`

**Why it's a WOW Factor**: Explains the threat to contacts in human-readable form. Police/contacts know exactly what they're responding to. Shows Gemma 4 edge+cloud hybrid capability (local + cloud API working together).

---

### 3.3 Auto-Post Generation (🚀 SHIPPING - May 17)
**Priority**: P0 - Shipping by May 17
**Purpose**: Emergency alert auto-posts to Twitter/Nextdoor without user action

**Impact on User Flow**: In Phase 6 (Social Layer), post automatically published to user's Twitter timeline: "🚨 EMERGENCY: [Location] [Threat Type Detected]. Help needed. #EmergencyAlert"

**Implementation Requirements**:
- [ ] Generate concise public alert (location, danger type, timestamp)
- [ ] Include threat type from Gemma (e.g., "kidnapping", "assault")
- [ ] Don't include sensitive details (victim name, audio clip)
- [ ] OAuth 2.0 integration with Twitter API v2
- [ ] User consent stored during onboarding (already UI)
- [ ] Max 280 characters (simple, loud, scannable)

**Tech Stack**:
- Package: `flutter_appauth ^6.1.0` (OAuth 2.0)
- Twitter API v2: POST /2/tweets
- Gemma API for post generation

**Deliverables**:
- [ ] SocialMediaPostingService with Twitter adapter
- [ ] OAuth 2.0 authentication during onboarding
- [ ] Token storage (encrypted keychain)
- [ ] Post content generation (location + threat + hashtag)
- [ ] Auto-post on emergency activation
- [ ] Settings: View/delete posts, toggle auto-post
- [ ] Integration tests with mock Twitter API

**Branch**: `feature/social-media-posting`

**Why it matters**: Broadcasts to user's followers + public feed instantly. No mass adoption needed. Friends see post, neighborhood sees alert. Fastest way to get help.

---

### 4 Local Database Setup (Hive/Isar)
**Purpose**: Offline-first incident storage with encryption for user privacy

**Implementation Requirements**:
- [ ] Store incidents with: timestamp, location, audio, transcript, Gemma analysis, alert status
- [ ] Encryption at rest (sensitive data like audio blurred in logs)
- [ ] Device-local only (no cloud sync yet)
- [ ] Backup/export to PDF or encrypted file

**Tech Stack**:
- Package: `isar` (faster than Hive for complex queries) OR `hive` (simpler)
- `flutter_secure_storage` for encryption keys
- `pdf` package for export

**Deliverables**:
- [ ] Incident model + Hive/Isar adapters
- [ ] Database initialization with encryption keys
- [ ] CRUD operations (create, read, update, delete)
- [ ] Query methods (filter by date, location, status)
- [ ] Backup/export functionality
- [ ] Migration path for schema updates
- [ ] Unit tests for persistence

**Branch**: `feature/local-database`


---

## 5. CONTACT MANAGEMENT (Priority: P1 - High)

### 5.1 Inner Circle Contact Network
**Purpose**: Tier-1 emergency notification recipients (Tier 2 also tracked for extended network)

**Implementation Requirements**:
- [ ] Store contacts: name, phone, relationship, tier level
- [ ] Validate phone numbers (format, international support)
- [ ] Encrypt phone numbers in local storage
- [ ] Support adding via phone contacts or manual entry
- [ ] Deduplication (prevent duplicate contacts)

**Tech Stack**:
- Package: `contacts_service` or `contact_picker_flutter` for importing
- `flutter_secure_storage` for phone encryption
- Local validation before saving

**Deliverables**:
- [ ] Contact model + Hive/Isar adapters
- [ ] ContactRepository with search, add, edit, delete
- [ ] Import from device contacts
- [ ] Validation service (phone number format, international)
- [ ] Unit tests
- [ ] Migration if switching to new contact store

**Branch**: `feature/contact-management`

---

### 5.2 SMS/WhatsApp Notification Service (🚀 SHIPPING - May 17)
**Priority**: P0 - Critical
**Purpose**: Alert tier-1 and tier-2 contacts immediately upon activation with proof + Gemma recommendation

**Impact on User Flow**: Phase 4 (Escalation) sends WhatsApp to Tier 1 with: location + 15s audio proof + Gemma threat assessment ("92% kidnapping confidence - CALL POLICE")

**Implementation Requirements**:
- [ ] Generate alert message from location + incident type + Gemma threat
- [ ] Send WhatsApp (rich format) to all Tier 1 contacts in parallel
- [ ] Include Gemma threat summary in message: "🚨 [Location] [Threat Type] detected - [Confidence]% - [Action]"
- [ ] Track delivery status per contact
- [ ] Retry failed messages (3 retries with 10s delay)
- [ ] User can customize message template during onboarding

**Tech Stack**:
- Package: `twilio_flutter ^0.2.6` (or direct HTTP to Twilio REST API)
- Twilio SMS Messaging API
- WhatsApp API integration

**Deliverables**:
- [ ] WhatsAppNotificationService with Twilio integration
- [ ] Message template system (include Gemma threat summary)
- [ ] Delivery tracking (sent, delivered, failed)
- [ ] Retry logic with exponential backoff
- [ ] Parallel sends to all Tier 1 contacts
- [ ] Unit tests with mock Twilio API

**Branch**: `feature/contact-notifications`

---

### 5.3 Proximity Suggestions (⏸️ DEFERRED POST-LAUNCH)
**Purpose**: Suggest nearby emergency services, police stations, hospitals

**Why deferred for May 17?** MVP focuses on direct contact alerts + social posting. Post-launch, we'll add GPS-based service discovery.

**Implementation Requirements**:
- [ ] Integrate with Google Places/Maps API for nearby services
- [ ] Query: hospitals, police, fire, safe houses (women's shelters)
- [ ] Show distance and directions
- [ ] Cache data locally to reduce API calls
- [ ] Available during emergency (already UI, needs API)

**Tech Stack**:
- Package: `google_maps_flutter` Places API
- Local cache with TTL (time-to-live)

**Deliverables**:
- [ ] ProximityService with Google Places integration
- [ ] Caching layer with TTL
- [ ] Distance calculation
- [ ] Unit tests with mock Places API
- [ ] Integration with home screen contact suggestions

**Branch**: `feature/proximity-services`

---

## 6. AUDIO & HAPTIC FEEDBACK (🚀 SHIPPING - May 17)

### 6.1 Audio Confirmation Playback (🚀 SHIPPING - May 17)
**Priority**: P0 - Critical
**Purpose**: Auditory confirmation for each action (already ConfirmationSoundService defined)

**Implementation Requirements**:
- [ ] Pre-recorded audio files for 6 action types
- [ ] Load audio once (during app init)
- [ ] Play with volume control
- [ ] Handle audio focus (pause music, respect silent mode)
- [ ] Already defined: ConfirmationSoundSystem service

**Tech Stack**:
- Package: `audioplayers` for playback
- `flutter_sound` as alternative (more features)

**Deliverables**:
- [ ] Integration of audio_player with ConfirmationSoundSystem
- [ ] Load audio assets during app startup
- [ ] Volume control (per app or system volume)
- [ ] Silent mode handling
- [ ] Unit tests with mocked audio player

**Branch**: `feature/audio-feedback`

---

### 6.2 Haptic Feedback (Native Android/iOS) (🚀 SHIPPING - May 17)
**Priority**: P0 - Critical
**Purpose**: Vibration patterns for feedback in silent situations

**Implementation Requirements**:
- [ ] Native Android method channel for haptics
- [ ] Native iOS method channel for haptics
- [ ] Different patterns per action type:
  - Police called = double pulse (100-50-100ms)
  - Contact notified = light tap (50ms)
  - Etc. (already defined in ConfirmationSoundSystem)
- [ ] Respect device vibration settings

**Tech Stack**:
- Native Android: VibratorManager API
- Native iOS: CoreHaptics (iOS 13+) + Taptic Engine
- Dart method channels

**Deliverables**:
- [ ] Android native code (MainActivity.kt or Kotlin file)
- [ ] iOS native code (GeneratedPluginRegistrant integration)
- [ ] Dart method channel bridge
- [ ] Haptic pattern definitions
- [ ] Unit tests (mock method channel)

**Branch**: `feature/haptic-feedback`

---

### 6.3 Fake Call System (⏸️ DEFERRED POST-LAUNCH)
**Priority**: P2 - Medium
**Purpose**: Discreet exit from dangerous situation by faking incoming call

**Why deferred for May 17?** Lower priority feature (impacts ~5% of users). MVP focuses on core escalation flow. Post-launch after Kaggle submission.

**Implementation Requirements**:
- [ ] Simulate incoming call with custom caller
- [ ] Play fake ringtone
- [ ] Active call UI (already exists)
- [ ] End call quietly (reset to normal state)
- [ ] Doesn't trigger actual call functionality

**Tech Stack**:
- `flutter_phone_direct_caller` (fake calls deprecated)
- Manual FakeCallScreen implementation (already UI)
- AudioPlayer for ringtone

**Deliverables**:
- [ ] FakeCallService managing state and audio
- [ ] Integration with FakeCallScreen (already UI)
- [ ] Ringtone playback
- [ ] State cleanup on call end
- [ ] Unit tests

**Branch**: `feature/fake-call` (likely mostly UI already, minimal backend)

---

## 7. PUSH NOTIFICATIONS (⏸️ DEFERRED - Post-Launch)

**Strategy Change**: Original plan was Firebase FCM for community geolocation alerts (broadcast to nearby users). **Replaced with social media posting** for May 17 (no mass adoption needed, instant reach via Twitter).

### 7.1 Local Notifications (⏸️ DEFERRED POST-LAUNCH)
**Purpose**: Remind user to test system, update contacts

**Why deferred for May 17?** Nice-to-have feature not critical for emergency flow. Post-launch, we'll add reminders.

**Implementation Requirements**:
- [ ] Schedule reminders (daily/weekly)
- [ ] Show on lock screen
- [ ] Support notification actions (dismiss, reschedule)
- [ ] App doesn't need to be running (native notification service)

**Tech Stack**:
- Package: `flutter_local_notifications`
- Android: NotificationManager API
- iOS: UNUserNotificationCenter

**Deliverables**:
- [ ] NotificationService for scheduling
- [ ] Notification payload handling
- [ ] Settings UI for notification preferences
- [ ] Unit tests with mock notifications

**Branch**: `feature/local-notifications`

---

### 7.2 Remote Notifications — REPLACED WITH SOCIAL POSTING
**Original Purpose**: Future-proofing for community alerts via Firebase FCM

**What Changed**: Instead of broadcasting to nearby app users (requires mass adoption to be valuable), we now:
- **May 17 MVP**: Auto-post to user's Twitter → instant reach to followers + public feed
- **Post-Launch**: Consider Firebase FCM for other use cases (app updates, emergencies in user's network, etc.)

**Implementation**:
For May 17, see **3.2 Social Media Auto-Posting** section above.

**Post-Launch Firebase FCM Setup**:
- [ ] Firebase project setup
- [ ] FCM token management (for future features)
- [ ] Listen for incoming messages
- [ ] Display in system tray
- [ ] Handle notification tap (deep link to relevant screen)

**Tech Stack**:
- Package: `firebase_messaging`
- Firebase Console for sending

**Branch**: `feature/remote-notifications` (defer to post-launch)

---
- [ ] FCM token management
- [ ] Listen for incoming messages
- [ ] Display in system tray
- [ ] Handle notification tap (deep link to relevant screen)

**Tech Stack**:
- Package: `firebase_messaging`
- Firebase Console for sending

**Deliverables**:
- [ ] Firebase project initialization
- [ ] FCM token registration/refresh
- [ ] Message listener implementation
- [ ] Deep linking for notification taps
- [ ] Settings UI for notification opt-in/out
- [ ] Unit tests with mock Firebase

**Branch**: `feature/remote-notifications` (lower priority, can follow local)

---

## 8. VOICE RECORDING & AUDIO ANALYSIS (🚀 SHIPPING - May 17)

### 8.1 Audio Capture Service (🚀 SHIPPING - May 17)
**Priority**: P0 - Critical
**Purpose**: Record emergency audio for Gemma analysis and emotion detection

**Implementation Requirements**:
- [ ] Capture microphone stream during emergency
- [ ] Store locally (encrypted)
- [ ] Pre-event buffer (5s before voice detection)
- [ ] Post-event capture (5 min max or until cancellation)
- [ ] Respect privacy (allow user to delete audio)

**Tech Stack**:
- Package: `record` or `flutter_sound` for capture
- `path_provider` for local storage
- Encryption for stored files

**Deliverables**:
- [ ] AudioRecorder service with streaming
- [ ] Pre-event ring buffer implementation
- [ ] File storage with encryption
- [ ] Cleanup/deletion of old audio files
- [ ] Unit tests

**Branch**: `feature/audio-capture`

---

### 8.2 Speech-to-Text Transcription (⏸️ DEFERRED POST-LAUNCH)
**Priority**: P2 - Medium
**Purpose**: Convert voice recordings to text 

**Why deferred for May 17?** Gemma API can handle raw audio for threat assessment. Optional transcription is nice-to-have. Post-launch, we'll add for audit/transcript purposes.

**Implementation Requirements**:
- [ ] Use Google Speech-to-Text API or Gemma's transcription
- [ ] Cache transcriptions locally
- [ ] Support offline transcription (degraded mode)
- [ ] Handle multiple speakers (background voices)

**Tech Stack**:
- Google Cloud Speech-to-Text API OR
- Gemma API transcription endpoint

**Deliverables**:
- [ ] TranscriptionService with API integration
- [ ] Caching of transcriptions
- [ ] Error handling and fallback
- [ ] Unit tests with mock API

**Branch**: `feature/speech-transcription`

---

## 9. PERMISSIONS & PRIVACY (🚀 SHIPPING - May 17)

### 9.1 Permission Management (🚀 SHIPPING - May 17)
**Priority**: P0 - Critical
**Purpose**: Request and track required permissions proactively

**Implementation Requirements**:
- [ ] Location (always, during emergency)
- [ ] Microphone (always, during emergency)
- [ ] Contacts (read-only for inner circle import)
- [ ] Notifications (for alerts, reminders)
- [ ] Background execution (for voice listener)
- [ ] Already has onboarding UI for this

**Tech Stack**:
- Package: `permission_handler`
- Native Android/iOS permission APIs

**Deliverables**:
- [ ] PermissionService managing all permissions
- [ ] Check status on app launch
- [ ] Request missing permissions
- [ ] Handle denials (degraded mode vs. critical)
- [ ] Unit tests

**Branch**: `feature/permissions-management`

---

### 9.2 Data Privacy & Encryption (🚀 SHIPPING - May 17)
**Priority**: P0 - Critical
**Purpose**: Protect sensitive user data at rest and in transit

**Implementation Requirements**:
- [ ] Encrypt audio files (AES-256)
- [ ] Encrypt stored incident metadata
- [ ] Encrypt phone numbers in contact storage
- [ ] Use HTTPS for all API calls
- [ ] Exclude audio from backup (iOS/Android)
- [ ] Allow user to wipe all incident data

**Tech Stack**:
- Package: `pointycastle` for encryption
- `flutter_secure_storage` for key management
- Native secure enclave access (iOS) if needed

**Deliverables**:
- [ ] Encryption service with key generation/management
- [ ] Integration across: audio storage, contact storage, incident database
- [ ] Secure key storage in device credential manager
- [ ] Data wipe utility
- [ ] Unit tests with encryption validation
- [ ] Privacy policy documentation

**Branch**: `feature/encryption`

---

## 10. BACKGROUND SERVICES (🚀 SHIPPING - May 17)

### 10.1 Background Voice Listener (🚀 SHIPPING - May 17)
**Priority**: P0 - Critical
**Purpose**: Keep voice phrase listener active even when app backgrounded or device locked

**Implementation Requirements**:
- [ ] Android: Foreground service with notification
- [ ] iOS: Background modes (audio) in Info.plist
- [ ] iOS: Keep audio session active with interruptions handling
- [ ] Manage battery usage (periodic wake-up vs. continuous)
- [ ] Handle app lifecycle (pause/resume)

**Tech Stack**:
- Package: `workmanager` or direct native code
- Android: Service + ForegroundServiceType.MEDIA_PLAYBACK
- iOS: Background modes + AVAudioSession

**Deliverables**:
- [ ] BackgroundServiceManager
- [ ] Android: Service implementation + manifest changes
- [ ] iOS: Background modes configuration + AVAudioSession setup
- [ ] Lifecycle management (start on app launch, stop on app close)
- [ ] Unit tests with mock background services

**Branch**: `feature/background-services`

---

### 10.2 Battery Optimization (⏸️ DEFERRED POST-LAUNCH)
**Priority**: P2 - Medium
**Purpose**: Reduce battery drain from continuous voice listening

**Why deferred for May 17?** Focus on correctness over optimization. Post-launch, we'll add adaptive listening based on time/location.

**Implementation Requirements**:
- [ ] Adjust voice listener frequency (heavy during night, light during day)
- [ ] Geofence awareness (listen more in high-risk locations)
- [ ] Adaptive listening (pause during calls, when on low power)
- [ ] Display battery status to user

**Tech Stack**:
- Package: `battery_plus` for battery status
- `geolocator` for location-based triggers
- Custom listening intervals

**Deliverables**:
- [ ] BatteryAwareService with adaptive listening
- [ ] Geofence integration
- [ ] Settings UI for battery mode
- [ ] Unit tests

**Branch**: `feature/battery-optimization`

---

## 11. USER SETTINGS & PREFERENCES (⏸️ DEFERRED POST-LAUNCH)

### 11.1 Settings Screen
**Priority**: P2 - Medium
**Purpose**: User controls for app behavior, notifications, audio feedback

**Why deferred for May 17?** Settings can be managed in onboarding. Post-launch, we'll add dedicated settings page for controls.

**Implementation Requirements**:
- [ ] Audio feedback control (on/off, volume)
- [ ] Vibration pattern selection
- [ ] Notification settings (reminders, severity)
- [ ] Location tracking frequency
- [ ] Auto-post consent toggle
- [ ] Emergency contacts visibility
- [ ] Dark mode toggle (already designed, not implemented)
- [ ] Data export/delete

**Tech Stack**:
- Package: `shared_preferences` for simple settings
- Already has ConfirmationSoundSystem with preferences

**Deliverables**:
- [ ] SettingsScreen UI (design later, but model structure now)
- [ ] PreferencesService for storage/retrieval
- [ ] Integration across all services (audio, notifications, location)
- [ ] Unit tests

**Branch**: `feature/user-settings`

---

## 12. TESTING & QA (🚀 SHIPPING - May 17)

### 12.1 System Self-Test (🚀 SHIPPING - May 17)
**Priority**: P0 - Critical
**Purpose**: Onboarding system test that user must pass (already UI)

**Impact on User Flow**: Phase 1 (Onboarding) final step - user validates mic, location, contacts, audio/haptics all working before launching live feature.
- [ ] Test microphone recording
- [ ] Test voice recognition (with recorded phrase)
- [ ] Test location capture (GPS or fallback)
- [ ] Test contact notification (SMS/WhatsApp send to test number)
- [ ] Test audio playback (all confirmation sounds)
- [ ] Test haptic feedback (all patterns)
- [ ] Provide feedback (✓ passed, ✗ failed with remedies)

**Tech Stack**:
- Reuse all services: VoiceRecognition, Location, Notification, Audio

**Deliverables**:
- [ ] SystemTestService orchestrating all tests
- [ ] Test result logging
- [ ] UI feedback (already onboarding screen 7)
- [ ] Unit tests

**Branch**: `feature/system-test`

---

### 12.2 Unit & Integration Tests (🚀 SHIPPING - May 17)
**Priority**: P0 - Critical
**Purpose**: Comprehensive test coverage for critical features

**Implementation Requirements**:
- [ ] Unit tests for all services (>80% coverage)
- [ ] Integration tests for workflows (activation → notification → escalation)
- [ ] Mock external APIs (Gemma, Twilio, Twitter)
- [ ] CI/CD pipeline integration
- [ ] Device testing on Android + iOS

**Tech Stack**:
- Package: `test`, `flutter_test`, `mockito`
- CI: GitHub Actions (free tier)

**Deliverables**:
- [ ] Unit test files for each service
- [ ] Integration test scenarios
- [ ] Mock utilities for external services
- [ ] GitHub Actions workflow
- [ ] Test coverage badge

**Branch**: `feature/testing-infrastructure`

---

## 13. DOCUMENTATION (⏸️ DEFERRED POST-LAUNCH)

### 13.1 API Documentation
**Priority**: P3 - Low
**Purpose**: Guide for team and future contributors

**Why deferred for May 17?** Inline code documentation + README are enough for launch. Post-launch, we'll create formal API docs.

**Implementation Requirements**:
- [ ] Service class documentation (VoiceRecognitionService, etc.)
- [ ] Database schema documentation
- [ ] API endpoint documentation (if backend server added later)
- [ ] Prompt engineering guide (Gemma system prompts)

**Tech Stack**:
- Dartdoc comments in code
- API.md file with examples

**Deliverables**:
- [ ] Dartdoc comments for all public methods
- [ ] API.md with examples
- [ ] Database schema ERD

**Branch**: `docs/api-documentation`

---

### 13.2 Contributor Guidelines (⏸️ DEFERRED POST-LAUNCH)
**Priority**: P3 - Low
**Purpose**: Help new team members contribute effectively

**Why deferred for May 17?** For team of 6, informal process is fine. Post-launch, we'll formalize.

**Implementation Requirements**:
- [ ] Code style guide (Dart conventions)
- [ ] Git workflow (branches, PRs, commits)
- [ ] Feature development checklist
- [ ] Testing requirements
- [ ] Deployment process

**Deliverables**:
- [ ] CONTRIBUTING.md (already planned)
- [ ] CODE_STYLE.md
- [ ] DEPLOYMENT.md

**Branch**: `docs/contributor-guidelines`

---

## 14. ANALYTICS & MONITORING (⏸️ DEFERRED POST-LAUNCH)

### 14.1 Crash Reporting (⏸️ DEFERRED POST-LAUNCH)
**Priority**: P3 - Low
**Purpose**: Report app crashes to team for debugging

**Why deferred for May 17?** Add post-launch for production monitoring. For development, we catch crashes in QA.

**Implementation Requirements**:
- [ ] Firebase Crashlytics integration
- [ ] Capture device info, Android/iOS version
- [ ] Exclude sensitive data from crashes

**Tech Stack**:
- Package: `firebase_crashlytics`

**Deliverables**:
- [ ] Crashlytics initialization
- [ ] Exception handler integration
- [ ] Dashboard setup

**Branch**: `feature/crash-reporting`

---

### 14.2 Anonymous Usage Analytics (⏸️ DEFERRED POST-LAUNCH)
**Priority**: P3 - Low
**Purpose**: Understand user behavior patterns (non-invasive)

**Why deferred for May 17?** Focus on shipping core features. Post-launch, we'll analyze what users actually do.

**Implementation Requirements**:
- [ ] Firebase Analytics integration
- [ ] Track: app opens, feature usage, errors
- [ ] NO location data, NO audio data, NO contact data
- [ ] User can opt-out

**Tech Stack**:
- Package: `firebase_analytics`

**Deliverables**:
- [ ] Analytics initialization
- [ ] Events for: app launch, feature access, emergency activation
- [ ] Opt-out mechanism
- [ ] Dashboard setup

**Branch**: `feature/analytics`

---

## ?FINAL CHECKLIST: MAY 17 SHIPPING FEATURES

### Shipping by May 17 (6 Core + 2 WOW = 8 Features Total)

| # | Feature | Section | WOW? | Shipping |
|---|---------|---------|------|----------|
| 1 | Voice Phrase Recognition | 1.1 | — | 🚀 |
| 2 | Emergency Activation Trigger | 1.2 | — | 🚀 |
| 3 | Real-Time Location Capture | 2.1 | — | 🚀 |
| 4 | Emotion Detection (Local TensorFlow) | 3.1 | ✨ WOW #1 | 🚀 |
| 5 | Gemma 4 Threat Assessment | 3.2 | ✨ WOW #2 | 🚀 |
| 6 | Social Media Auto-Posting | 3.3 | — | 🚀 |
| 7 | Inner Circle Contact Network | 5.1 | — | 🚀 |
| 8 | WhatsApp Alert + Proof | 5.2 | — | 🚀 |
| 9 | Audio Confirmation | 6.1 | — | 🚀 |
| 10 | Haptic Feedback | 6.2 | — | 🚀 |
| 11 | Audio Capture Service | 8.1 | — | 🚀 |
| 12 | Permission Management | 9.1 | — | 🚀 |
| 13 | Data Encryption | 9.2 | — | 🚀 |
| 14 | Background Voice Listener | 10.1 | — | 🚀 |
| 15 | System Self-Test | 12.1 | — | 🚀 |
| 16 | Unit & Integration Tests | 12.2 | — | 🚀 |

**Total Shipping**: 16 features (all critical path for May 17)

### Deferred to Post-Launch (⏸️)

| Feature | Section | Why Deferred |
|---------|---------|-------------|
| Location History & Maps | 2.2 | Continuous tracking too complex for 2-week build |
| Proximity Services | 5.3 | GPS-based discoveries nice-to-have, not critical |
| Fake Call | 6.3 | Low priority feature (~5% of users, post-launch OK) |
| Local Notifications | 7.1 | Reminders system can follow after core shipping |
| Remote Notifications (FCM) | 7.2 | Replaced with social media posting (instant reach, no adoption needed) |
| Speech Transcription | 8.2 | Gemma API can handle raw audio, transcription optional |
| Settings Screen | 11.1 | Onboarding covers controls, formal settings UI post-launch |
| Battery Optimization | 10.2 | Focus on correctness over optimization for May 17 |
| Documentation (formal) | 13.1-13.2 | Inline docs sufficient for launch, formal docs post-launch |
| Analytics/Monitoring | 14.1-14.2 | Add post-launch for production monitoring |

**Total Deferred**: 11 features (post-launch roadmap)

---

```
CRITICAL PATH (Block other features):
1. Voice Activation (feature/voice-activation)
   ↓
2. Emergency Activation (feature/emergency-activation)
   ↓
3. Location Tracking (feature/location-tracking)
   ├→ AI Analysis (feature/gemma-analysis)
   ├→ Contact Notifications (feature/contact-notifications)
   └→ Audio/Haptic Feedback (feature/audio-feedback, feature/haptic-feedback)

PARALLEL FEATURES (Can start immediately):
- Contact Management (feature/contact-management)
- Local Database (feature/local-database)
- Permissions Management (feature/permissions-management)
- Encryption (feature/encryption)
- Audio Capture (feature/audio-capture)
- Speech Transcription (feature/speech-transcription)
- Background Services (feature/background-services)

DEPENDENT ON ABOVE:
- Incident Persistence (depends: local-database + audio-capture)
- Auto-Post Alerts (depends: gemma-analysis)
- Proximity Services (depends: location-tracking)

POLISH/OPTIONAL (Can follow core):
- Local Notifications (feature/local-notifications)
- Remote Notifications (feature/remote-notifications)
- Fake Call System (feature/fake-call)
- User Settings (feature/user-settings)
- Battery Optimization (feature/battery-optimization)
- System Test (feature/system-test)
- Analytics & Monitoring
- Documentation
```

---

## TEAM ASSIGNMENT RECOMMENDATION

### Team Member 1: Backend Services Lead (Dev Naema)
**Branches**:
1. `feature/voice-activation` - Voice recognition with E2B
2. `feature/audio-capture` - Audio recording and buffering
3. `feature/background-services` - Foreground service management
4. `feature/speech-transcription` - Voice-to-text conversion

**Rationale**: Focus on the voice pipeline (the unique differentiator of Echo)

---

### Team Member 2: Location & Notifications Lead Precious
**Branches**:
1. `feature/location-tracking` - GPS and background location
2. `feature/contact-notifications` - SMS/WhatsApp alerting
3. `feature/proximity-services` - Nearby services discovery
4. `feature/contact-management` - Contact storage and management

**Rationale**: Real-time emergency notification chain (second most critical)

---

### Team Member 3: AI & Data Lead Esther
**Branches**:
1. `feature/gemma-analysis` - Real-time incident analysis
2. `feature/auto-post-alerts` - Social media publishing
3. `feature/local-database` - Hive/Isar setup
4. `feature/incident-persistence` - Persistence layer

**Rationale**: Data processing and intelligent decision-making

---

### Team Member 4: Native & Polish Lead Rola
**Branches**:
1. `feature/haptic-feedback` - Android/iOS native haptics
2. `feature/audio-feedback` - Audio system integration
3. `feature/permissions-management` - Permission flows
4. `feature/encryption` - Data security and privacy

**Rationale**: Native platform integration and security hardening

---

## GIT WORKFLOW

### Branch Naming Convention
```
feature/<feature-name>         - New functionality
fix/<bug-description>          - Bug fixes
refactor/<area>                - Code refactoring
docs/<documentation-area>      - Documentation
```

### PR Review Process
1. Create branch from `main`
2. Implement feature + tests
3. Push to GitHub, create PR
4. Peer review (at least 1 approval)
5. CI/CD checks must pass
6. Merge to `main`
7. Delete feature branch

### Commit Message Format
```
[TAG] Short description

Longer explanation if needed.

Closes #issueNumber (if applicable)

TAG options: FEAT, FIX, DOCS, REFACTOR, TEST, PERF
```

---

## DEVELOPMENT CHECKLIST (Per Feature)

Each team member should complete:
- [ ] Create feature branch
- [ ] Implement core functionality
- [ ] Add unit tests (>80% coverage)
- [ ] Add integration tests
- [ ] Update FEATURES.md progress
- [ ] Create PR with description
- [ ] Address code review feedback
- [ ] Ensure CI/CD passes
- [ ] Merge to main
- [ ] Update changelog

---

## NEXT STEPS

1. **Team Sync**: Review this feature list, assign branches 1:1 to team members
2. **Setup CI/CD**: Create `.github/workflows/test.yml` for GitHub Actions
3. **Create Issues**: Transform branches into GitHub issues (auto-tracked)
4. **Begin Development**: Team members start on Phase 1 branches simultaneously
5. **Weekly Syncs**: Review progress, handle blockers, celebrate wins

---


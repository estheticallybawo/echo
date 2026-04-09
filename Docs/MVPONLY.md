# Echo App - MVP ONLY (May 17 Kaggle Deadline)

**Timeline**: April 8 - May 17, 2026 (Exactly 6 weeks calendar / 30 working days)
**Hard Deadline**: May 17 (Kaggle submission cutoff — CANNOT EXTEND)
**Team**: 5 people (4 developers + 1 designer )
**Sprint Structure**:
- **Week 1-2 (Apr 8-21, 10 working days)**: Build ALL core features + 2 WOW factors (aggressive)
- **Week 3 (Apr 22-28, 5 working days)**: QA + UI polish + bug fixes
- **Week 4 (Apr 29-May 17, 9 working days)**: Final fixes + submission buffer

**Goal**: Emergency safety app with voice activation, 2-tier escalation, emotion detection + Gemma threat assessment 

---

## CRITICAL PATH: May 17 Deadline (30 Working Days)

**WHAT SHIPS BY MAY 17**:
1. ✅ **Voice activation** — Say phrase, emergency screen appears <2 seconds
2. ✅ **2-Tier escalation** — Tier 1 (3-5 contacts) → 30s silence → Tier 2 (5-10 contacts)
3. ✅ **Gemma 4 threat assessment** — Real-time analysis: "This is kidnapping, 92% confidence. Call police."
4. ✅ **Emotion detection (WOW #1)** — Local AI detects panic, shows fear gauge, triggers auto-police
5. ✅ **Social media auto-posting** — Emergency alert auto-posts to Twitter/Nextdoor on activation
6. ✅ **WhatsApp alerts with proof** — Location + audio confirmation clip to each contact

**WHAT WAS CUT TO HIT DEADLINE**:
- ❌ Continuous active tracking (one-time location only when contact responds)
- ❌ 3 contact decision buttons (simplified to 1: "I'm helping")
- ❌ Continuous Gemma re-analysis per audio clip (single threat assessment at activation)


**WHAT'S IN POST-LAUNCH ROADMAP**:
- [ ] Active tracking with continuous location + audio updates
- [ ] Multi-option contact decisions
- [ ] Continuous threat monitoring
- [ ] Social media posting
- [ ] Advanced escalation logic

---

## TRACK A: Voice Activation & Emergency Trigger (1 Developer)
**Owner**: [Assign here]
**Timeline**: Week 1-2 (10 days)
**Status**: ⬜ Not started

### Feature: Voice Phrase Recognition + Emergency Activation
**UI**: Already complete (HomeScreen with glowing orb, EmergencyActiveScreen)

**Implementation Tasks**:

1. **VoiceRecognitionService** (Days 1-3)
   - [ ] Setup `speech_to_text` package with background listener
   - [ ] Local E2B integration for Gemma 2B-IT (on-device, no Gemma API yet)
   - [ ] Record voice phrase during onboarding → store in local storage
   - [ ] Confidence threshold filtering (>85% to reduce false positives)
   - [ ] Background listener (survives app backgrounding)
   - [ ] Unit tests: phrase matching accuracy (mock audio)

   **Tech Stack**:
   ```
   Package: speech_to_text ^6.6.3
   Package: e2b ^1.0.0 (for local Gemma)
   Package: audio_session ^0.1.13
   ```

2. **EmergencyActivationManager** (Days 4-5)
   - [ ] Listen to VoiceRecognitionService phrase detected event
   - [ ] Capture audio buffer (5 seconds pre-event + 30 seconds post)
   - [ ] Record: timestamp, location, audio stream
   - [ ] Transition UI to EmergencyActiveScreen
   - [ ] Lock device interaction (prevent accidental cancellation)
   - [ ] Integration tests: state transitions

   **Tech Stack**:
   ```
   Package: record ^5.1.0 (audio capture)
   Package: geolocator ^9.1.0 (location snapshot)
   Native channel: Kotlin/Swift for audio permissions
   ```

3. **EmergencySession Model** (Day 6)
   - [ ] Model: `{audio_buffer, location, timestamp, phrase_confidence, status}`
   - [ ] SharedPreferences for session metadata
   - [ ] Pass session to Track B for notifications

**Branch**: `feature/voice-activation-mvp`

**Deliverables by May 10**:
- ✅ Voice activation working on Android/iOS devices
- ✅ Emergency trigger fires reliably
- ✅ Audio capture working (with real audio data)

---

## TRACK B: Location + Contact Notifications (1 Developer)
**Owner**: [Assign here]
**Timeline**: Week 1-2 (10 days)
**Status**: ⬜ Not started

### Feature 1: Real-Time Location Capture
**UI**: Already complete (markers on EmergencyActiveScreen)

**Implementation Tasks**:

1. **LocationTracker Service** (Days 1-3)
   - [ ] Background location updates every 10 seconds (during emergency only)
   - [ ] High-accuracy GPS fallback to WiFi triangulation
   - [ ] Permission handling (location permission already in onboarding UI)
   - [ ] Foreground service (Android: persistent notification during emergency)
   - [ ] Background modes (iOS: location background mode)
   - [ ] Unit tests: mock location providers

   **Tech Stack**:
   ```
   Package: geolocator ^9.1.0
   Package: android_intent_plus ^4.1.0 (for native Android)
   Kotlin: native foreground service
   Swift: background location modes
   ```

2. **LocationHistory Model** (Days 4-5)
   - [ ] Store: `{latitude, longitude, accuracy, timestamp}`
   - [ ] Append to incident session
   - [ ] Don't persist to database (defer to Track C)

**Branch**: `feature/location-tracking-mvp`

---

### Feature 2: SMS/WhatsApp Contact Notifications
**UI**: Alert status UI already on EmergencyActiveScreen (shows "Alerts sent: X")

**Implementation Tasks**:

1. **ContactStore** (Days 2-3, parallel with location)
   - [ ] Simple in-memory store of inner circle contacts (read from onboarding)
   - [ ] Store: name, phone, tier (Tier 1 = priority)
   - [ ] Load from SharedPreferences (set during onboarding)
   - [ ] No database needed yet (defer to Track C)

   **Tech Stack**:
   ```
   SharedPreferences only (no Hive yet)
   ```

2. **NotificationService** (Days 4-6)
   - [ ] SMS alerts via whatsapp: **"[USER NAME] is in danger at [LOCATION]. Emergency services notified. Reply SAFE when secure."**
   - [ ] WhatsApp alerts (optional, fallback to SMS)
   - [ ] Send to all Tier 1 contacts in parallel
   - [ ] Track delivery status (sent/failed)
   - [ ] Retry any failed sends (3 retries with 10s delay)
   - [ ] Unit tests: mock whatsapp API

   **Tech Stack**:
   ```
   Package: twilio_flutter ^0.2.6 (or direct HTTP to Twilio REST API)
   API: Twilio SMS Messaging API
   ```

3. **Integration with Track A** (Day 7)
   - [ ] When EmergencyActivationManager fires → call NotificationService
   - [ ] Pass EmergencySession + location to send alert
   - [ ] Update "Alerts sent" counter on UI

**Branch**: `feature/contact-notifications-mvp`

**Deliverables by May 10**:
- ✅ SMS notifications sent to inner circle
- ✅ Location included in alert
- ✅ Delivery tracking on EmergencyActiveScreen
- ✅ Twilio account configured (need API keys)

---

## TRACK C: Social Media Auto-Posting (1 Developer)
**Owner**: Esther Bawo Tsotso
**Timeline**: Week 1-2 (10 days)
**Status**: ⬜ Not started

### Feature: Emergency Alert Auto-Posted to Social Media

**Why This Matters**: When someone triggers Echo, emergency alert auto-posts to their Twitter/Nextdoor account IMMEDIATELY. This broadcasts to their followers + local community without requiring mass adoption. Contacts see post in-feed, friends can respond, neighborhood gets visibility.

**Implementation Tasks**:

1. **Twitter OAuth 2.0 Setup** (Days 1-3)
   - [ ] User authenticates with Twitter account during onboarding (added UI page)
   - [ ] Store OAuth token securely (encrypted in device keychain)
   - [ ] Refresh token handling
   - [ ] Unit tests: OAuth flow (mock Twitter endpoint)

   **Tech Stack**:
   ```
   Package: flutter_appauth ^6.1.0 (OAuth 2.0)
   OR: twitter_api (custom HTTP integration)
   Twitter API v2: POST /2/tweets
   ```

2. **Emergency Post Generation** (Days 4-6)
   - [ ] Generate post content via Gemma: "🚨 EMERGENCY: I triggered Echo emergency alert at [street address] [time]. Keyword: [threat type]. Immediate help needed. If you're nearby, call police or reply. #EmergencyAlert"
   - [ ] Max 280 characters (include simplified summary)
   - [ ] Include hashtag: #EmergencyAlert for searchability
   - [ ] Geotag location if available (Twitter location feature)
   - [ ] Unit tests: post generation, character limit enforcement

3. **Auto-Post on Activation** (Days 7-9)
   - [ ] When voice activation fires (Track A):
     - Grab user's stored OAuth token
     - Generate post via Gemma (with address + threat type)
     - Call Twitter API v2: POST to user's timeline
     - Log post URL (user can see it posted immediately)
   - [ ] Optional: Pin post for 1 hour (visibility boost)
   - [ ] Handle rate limits gracefully (queue if needed)
   - [ ] Integration tests: end-to-end post generation + sending

4. **User Control + Privacy** (Day 10)
   - [ ] Toggle in onboarding: "Auto-post emergency alerts to Twitter" (opt-in)
   - [ ] User reviews & approves Twitter post content in onboarding
   - [ ] If user declines, skip auto-post (no error)
   - [ ] Settings screen: View last post, manually delete if needed
   - [ ] Integration tests: toggle functionality

**Branch**: `feature/social-media-posting`

**Deliverables by May 10**:
- ✅ Twitter OAuth working on actual user account
- ✅ Post generated automatically on emergency activation
- ✅ Post includes location + threat type + hashtag
- ✅ User privacy: opt-in only, no data stored
- ✅ Post visible in user's timeline immediately

---

## TRACK D: Audio/Haptic Feedback + System Integration (1 Developer)
**Owner**: [Assign here]
**Timeline**: Week 1-2 (8 days)
**Status**: ⬜ Not started

### Feature 1: Confirmation Sounds & Haptics
**Reference**: `lib/services/confirmation_sound_system.dart` (already written)

**Implementation Tasks**:

1. **Audio Asset Setup** (Days 1-2)
   - [ ] Add 4 audio files to `assets/sounds/`:
     - `confirm_action.mp3` (100ms, positive tone)
     - `alert_sent.mp3` (200ms, slightly urgent)
     - `emergency_stopped.mp3` (triple beep)
     - `error.mp3` (soft warning tone)
   - [ ] Or use `flutter_tts` for text-to-speech confirmations (cheaper than assets)

   **Tech Stack**:
   ```
   Package: audioplayers ^6.1.0 (or flutter_tts)
   Package: vibration ^1.9.0 (haptic feedback)
   ```

2. **ConfirmationSoundService** (Days 3-5)
   - [ ] Copy reference implementation from `confirmation_sound_system.dart`
   - [ ] Add async playConfirmation(action) → plays sound + haptic
   - [ ] playDiscreetConfirmation() → haptic only (silent mode)
   - [ ] enums: police_called, alert_sent, emergency_stopped, contact_notified
   - [ ] Unit tests: sound playback (mock audio)

3. **Integration Points** (Days 6-8)
   - [ ] **On voice activation**: play `alert_sent` sound + vibrate
   - [ ] **On SMS sent successfully**: play `confirm_action` + light haptic
   - [ ] **On SMS failed**: play `error` sound
   - [ ] **On emergency stopped**: play `emergency_stopped` (triple beep)
   - [ ] Settings toggle: enable/disable sounds (toggle in onboarding UI)
   - [ ] Settings toggle: enable/disable haptics (toggle in onboarding UI)

**Branch**: `feature/audio-haptic-mvp`

---

### Feature 2: Background Service Glue
**Purpose**: Keep voice listener + location tracking alive even when app is backgrounded

**Implementation Tasks**:

1. **Background Service Setup** (Days 1-2)
   - [ ] Android: Foreground service (persistent notification)
   - [ ] iOS: Background modes (voip, location, processing)
   - [ ] Kotlin native code: startForegroundService()
   - [ ] Swift native code: AVAudioSession + background modes in Info.plist

2. **App Lifecycle Management** (Days 3-4)
   - [ ] Listen to app lifecycle (paused/resumed)
   - [ ] Ensure voice listener stays active when app backgrounded
   - [ ] Ensure location service survives backgrounding
   - [ ] Resume UI state correctly on app return

3. **System Integration Testing** (Days 5-8)
   - [ ] Test on actual Android device: app backgrounded, voice activation still works
   - [ ] Test on actual iOS device: app backgrounded, location still tracked
   - [ ] Integration tests: lifecycle transitions

**Branch**: `feature/background-service-mvp`

**Deliverables by May 10**:
- ✅ Confirmation sounds playing at key moments
- ✅ Haptic feedback working
- ✅ Voice activation survives backgrounding (Android/iOS)
- ✅ Location tracking continues in background

---

## TRACK E: Edge AI Wow Factor Feature (1 Developer)
**Owner**: [Assign here]
**Timeline**: Week 1-2 (10 days, choose ONE)
**Status**: ⬜ Not started

### Choose ONE of These Wow Features

#### Option A: Real-Time Gemma API Threat Analysis
**Purpose**: During emergency, Gemma analyzes audio in real-time → threat confidence + recommendation

**Implementation (Days 1-10)**:
- [ ] Stream audio capture to Gemma API (via google_generative_ai package)
- [ ] Prompt engineering: "Analyze this emergency audio. Detect: fear level (0-100), threat type, recommended action"
- [ ] Display streaming response on EmergencyActiveScreen
- [ ] Show confidence score (e.g., "92% high-threat situation")
- [ ] Send confidence to Track B for smarter contact selection
- [ ] Unit tests: mock Gemma API responses

**Tech Stack**:
```
Package: google_generative_ai ^0.4.0
Prompt: Emergency audio analysis with threat scoring
```

**Impact**: Shows police/contacts "AI says 92% real emergency" → faster response

---

#### Option B: Auto-Post to Social Media
**Purpose**: When emergency triggers, post to Twitter/Nextdoor without user tapping "post"

**Implementation (Days 1-10)**:
- [ ] Geographic context: "Emergency alert in [Neighborhood], [Address]"
- [ ] Generate post via Gemma: "Someone in [area] triggered emergency. Community members notified."
- [ ] OAuth integration with Twitter API v2 or Nextdoor API
- [ ] Post automatically on activation
- [ ] Track engagement (retweets = community validation)
- [ ] Unit tests: mock OAuth flow, mock post API

**Tech Stack**:
```
Package: twitter_api (custom, or use REST API directly via http/dio)
Gemma API for post generation
OAuth 2.0 for authentication
```

**Impact**: Community sees public alert → friends check on user → faster help arrives

---

#### Option C: Voice Emotion Detection (Offline)
**Purpose**: Analyze user's voice during emergency → detect fear/panic → trigger immediate police dispatch

**Implementation (Days 1-10)**:
- [ ] Use local ML model: emotion detection on 20-second audio sample
- [ ] Models: TensorFlow Lite emotion detection model OR Gemma 2B with emotion classification
- [ ] Detect: calm (0-30), concerned (30-60), fear/panic (60-100)
- [ ] If panic detected (>70) → auto-call police (not waiting for SMS confirmation)
- [ ] Display emotion confidence on EmergencyActiveScreen
- [ ] Unit tests: emotion detection accuracy on mock audio

**Tech Stack**:
```
Package: tflite_flutter (emotion detection model)
OR: google_generative_ai with emotion prompt
Local on-device = instant, no latency
```

**Impact**: Captures user intent even if speech is incoherent during panic

---

#### Option D: Real-Time Audio Transcription + Context
**Purpose**: Transcribe voice continuously → extract danger keywords + auto-populate police report

**Implementation (Days 1-10)**:
- [ ] Google Cloud Speech-to-Text API OR Gemma transcription
- [ ] Parse transcription for danger keywords: "knife", "gun", "assault", "shooting", "fire"
- [ ] Build auto-incident report: "User shouting about [threat type] at [location]"
- [ ] Display transcript live on EmergencyActiveScreen (for user to verify/correct)
- [ ] Send enriched transcript to Track B (SMS includes key details)
- [ ] Unit tests: keyword detection accuracy

**Tech Stack**:
```
Package: google_generative_ai (for transcription)
Package: speech_to_text (for local speech-to-text if google cloud unavailable)
```

**Impact**: Police get instant summary → faster, more accurate response

---

**Recommendation**: **Option C (Emotion Detection)** is the "wow factor" because:
- Works entirely offline (no API latency)
- Creates immediate police dispatch trigger (fastest response)
- Shows AI is understanding user intent, not just recording
- Most defensible in court ("AI detected genuine panic")

---

## TRACK F: UI Design + Brand Assets (1 Dedicated Designer)
**Owner**: [Assign here]
**Timeline**: Week 1-2 (feature design), Week 3 (polish)
**Status**: ⬜ Not started

### Week 1-2: Foundation + Feature Design (Parallel with Dev Tracks)

**Early Design Decisions**:
- [ ] Confirm color palette: Teal #0891B2 primary, soft blue secondary, no reds
- [ ] Typography: Poppins (already chosen)
- [ ] Finalize glowing orb design (breathing animation specs)
- [ ] Design emergency alert notification card (how it appears in system tray)
- [ ] Design geolocation broadcast alert (brief, non-traumatic)

**Screen-by-Screen Design**:
1. [ ] **Home Screen** — Glowing orb, voice trigger status, feature grid
   - Pass Figma to Track A for implementation
2. [ ] **Emergency Active Screen** — Timer, live status, Gemma analysis card
   - Pass Figma to Track A/E for implementation
3. [ ] **Onboarding** — 7-step flow (already has UI, needs visual design)
   - Export all 7 pages as Figma specs
4. [ ] **Contacts Screen** — Tier 1/2 contact management
   - Pass Figma to Track B for implementation
5. [ ] **Community Alert Notification** — How geolocation alert appears
   - Design for both: system tray + in-app modal
   - Pass to Track C for implementation

**Asset Deliverables (Week 1-2)**:
- [ ] App icon (192x192, 512x512, all densities)
- [ ] Splash screen (light theme, glowing orb centerpiece)
- [ ] Icon set (5-8 icons: voice, location, alert, contacts, settings)
- [ ] Notification icon (geolocation alert visual)
- [ ] Color tokens file (export for dev team)
- [ ] Figma component library (for consistency across screens)

**Design Handoff Format**:
- [ ] Create Figma file shared with all devs
- [ ] Link each component to corresponding Dart widget
- [ ] Include spacing grid, typography rules, color specs
- [ ] Include animation specs (duration, easing, curves)

### Week 3: Polish + Final Assets

**Design Review Cycle**:
- [ ] Monday: Dev team demos working screens
- [ ] Tuesday-Wednesday: Designer reviews, provides feedback
- [ ] Thursday: Designer polishes any inconsistencies
- [ ] Friday: Final asset exports, responsive layout check

**Deliverables (Week 3)**:
- [ ] All screens aligned to design system
- [ ] Responsive layout tested on:
  - iPhone SE (375px)
  - iPhone 14 Pro (390px)
  - iPhone 14 Pro Max (430px)
  - Android edge devices (360px, 720px densities)
- [ ] Dark mode palette (if time allows)
- [ ] App store screenshots (5-6 per platform, with text overlays)
- [ ] App store listing description + keywords
- [ ] Privacy policy design (web-friendly format)

---

---

## MAY 17 SPRINT BREAKDOWN

### **Day 1 (Monday, April 8): SETUP DAY — ALL ACCOUNTS + DEVICES READY BY EOD**

**IF THIS DAY FAILS → ENTIRE SPRINT FAILS. PRIORITIZE ABOVE ALL.**

| Task | Owner | MUST COMPLETE BY EOD |
|------|-------|---------------------|
| Twilio account + SMS API keys tested | DevOps | Apr 8, 5 PM |
| E2B account + Gemma 2B local model tested | DevOps | Apr 8, 5 PM |
| Firebase project + Firestore schema ready | DevOps | Apr 8, 5 PM |
| Google Cloud credentials + Gemma 4 API ready | DevOps | Apr 8, 5 PM |
| 2 Android devices + 2 iOS devices ready | DevOps | Apr 8, 5 PM |
| All 4 devs: Android Studio + Xcode + Flutter dev env | DevOps | Apr 8, 3 PM |
| All 4 devs: Clone repo, checkout feature branches | All Devs | Apr 8, 3 PM |
| Designer: Figma file shared, ready for specs | Designer | Apr 8, 3 PM |

**If DevOps setup isn't done by Apr 8 EOD:**
- 🔴 Week 1 is BLOCKED
- 🔴 Devs sit idle (can't test without accounts/devices)
- 🔴 Your May 17 deadline SHIFTS TO MAY 24 minimum

---

### **Week 1 (April 8-14): Core Features Foundation**

#### **Track A: Voice Activation + Emergency Trigger (Dev 1)**
Days 1-5 (Apr 8-12)

**Deliverables**:
- [ ] VoiceRecognitionService: E2B integration, phrase detection >95% accuracy
- [ ] EmergencyActivationManager: Trigger screen, timestamp + location capture
- [ ] Audio buffer: 5s pre-event capture
- [ ] Unit tests: phrase matching accuracy
- [ ] **Device test (Fri Apr 12)**: Speak phrase, screen changes, no crash

---

#### **Track B: Location + WhatsApp Escalation (Dev 2)**
Days 1-5 (Apr 8-12)

**Deliverables**:
- [ ] LocationTracker: GPS capture, ±20m accuracy
- [ ] EscalationManager: FSM (Tier 1 → 30s wait → Tier 2 FSM logic
- [ ] sendTierOneAlert(): Send WhatsApp to 3-5 Tier 1 contacts in parallel
- [ ] sendTierTwoAlert(): Conditional trigger after 30s silence
- [ ] 30-second timer logic: precise timeout handling
- [ ] Unit tests: state transitions, timer accuracy
- [ ] **Device test (Fri Apr 12)**: Location + Tier 1 alert sent in <5s

---

#### **Track C: Social Media Auto-Posting (Dev 3)**
Days 1-5 (Apr 8-12)

**Deliverables**:
- [ ] Twitter OAuth 2.0 setup + token storage (encrypted keychain)
- [ ] Post generation logic via Gemma (address + threat type + hashtag)
- [ ] Auto-post on activation: Call Twitter API v2 on voice trigger
- [ ] Error handling + rate limit management
- [ ] Settings page: Review/delete posts, toggle auto-post
- [ ] Unit tests: OAuth flow, post generation, API calls
- [ ] **Device test (Fri Apr 12)**: Post appears on user's timeline <5s after activation

---

#### **Track D: Audio/Haptic + Background Services (Dev 4)**
Days 1-5 (Apr 8-12)

**Deliverables**:
- [ ] ConfirmationSoundService: 4 sounds (activation, sent, success, error)
- [ ] Haptic patterns: vibration feedback for each action
- [ ] BackgroundServiceManager: Foreground service (Android), background modes (iOS)
- [ ] App lifecycle: Resume/pause handling
- [ ] Audio focus: Respect device mute + silent mode
- [ ] Unit tests: audio playback, haptic triggering
- [ ] **Device test (Fri Apr 12)**: Sounds play, haptics work, app backgrounded + listens

---

#### **Week 1 Integration (Friday, April 12)**

**All devs together, 2 hours**:
1. Merge all branches to `develop`
2. Test end-to-end: Voice → Location → Tier 1 alert sent → Social media post published
3. Fix merge conflicts IMMEDIATELY
4. Device testing: Does it work on real Android + iOS?

**Success criteria**:
- ✅ All 4 core features working together
- ✅ No crashes on either device
- ✅ End-to-end flow working (<30s from voice to alert)

**If failed**:
- 🔴 STOP. Fix until working. This is blocker #2 (after setup).

---

### **Week 2 (April 15-21): WOW Factors + Integration**

#### **Critical-Path: 2-Tier Escalation Deep Work (Days 6-7, Tue-Wed Apr 15-16)**

⚠️ **This is the hardest feature. Starts IMMEDIATELY Mon.**

**Dev 2 + Dev 3 focus**:

| Day | Task | Code | Tests |
|-----|------|------|-------|
| **Mon-Tue** | Escalation FSM: Tier 1 → wait 30s → detect response → stop OR trigger Tier 2 | `EscalationManager` with StreamControllers | State transition tests, timer accuracy tests |
| **Tue-Wed** | Tier 1 alert: Send WhatsApp to ALL Tier 1 contacts in parallel with 3-button prompt | `sendTierOneAlert()` with Twilio batch | Delivery confirmation, button state tracking |
| **Wed** | Tier 2 conditional: On T=30 silence, trigger Tier 2 alerts | `if (noResponseAt30s) → sendTierTwoAlert()` | Conditional logic tests |
| **Wed EOD** | End-to-end test: Tier 1 → silence → Tier 2 triggered correctly | Device test: Actual contacts, real timeouts | Timing precision tests |

**Success criteria by Wed EOD**:
- ✅ Tier 1 alert sent <5s of voice activation
- ✅ Tier 2 alert sent exactly at T=30s (±1s tolerance)
- ✅ If contact responds before T=30s, escalation STOPS
- ✅ Tested on real device with real contacts

---

#### **WOW #1: Emotion Detection (Dev 1, Days 7-10, Thu Apr 17 - Fri Apr 19)**

| Day | Task | Code | Tests |
|-----|------|------|-------|
| **Thu** | Load TensorFlow Lite emotion model, process audio → emotion features | Model loading + feature extraction | Model load success, feature accuracy |
| **Thu** | Emotion classification: audio features → calm/concerned/panic (0-100) | Inference engine | Classification accuracy on test audio |
| **Fri** | UI gauge: Display emotion level on EmergencyActiveScreen live-updating | `emotion_gauge.dart` | Gauge rendering tests |
| **Fri** | Auto-police trigger: if emotion >70% → send SMS to police dept | `callPolice()` on threshold | SMS delivery tests |

**Success criteria by Fri EOD**:
- ✅ Emotion detection shows live on screen (0-100 gauge)
- ✅ Panic detection (emotion >70%) triggers auto-police SMS
- ✅ Tested on real audio (screaming, panic, calm vowels)
- ✅ Response time <2 seconds

---

#### **WOW #2: Gemma 4 Threat Assessment (Dev 3, Days 8-10, Wed Apr 17 - Fri Apr 19)**

| Day | Task | Code | Tests |
|-----|------|------|-------|
| **Wed-Thu** | Gemma 4 API setup: Stream audio to Gemma, send system prompt for threat analysis | `streamAudioToGemmaAPI()` | API request/response tests |
| **Thu** | Parse Gemma response: Extract threat type + confidence + action | `parseGemmaResponse()` → JSON deserialize | Parsing accuracy tests |
| **Fri** | Display threat on UI: "Kidnapping - 92% confidence - Call police" | `threat_assessment_card.dart` | UI rendering tests |
| **Fri** | Include Gemma summary in WhatsApp alert to contact | Send to contact: "[GEMMA ALERT] Kidnapping detected - 92% - CALL POLICE" | End-to-end alert tests |

**Success criteria by Fri EOD**:
- ✅ Gemma responds with threat assessment <3 seconds
- ✅ Confidence score shown on UI
- ✅ Contact receives WhatsApp with Gemma recommendation
- ✅ Tested with multiple emergency audio samples

---

#### **Week 2 Integration (Friday, April 19)**

**All devs + Designer**:
- Full end-to-end test on real devices
- Voice → Emotion detected → Threat assessed → Tier 1 alerted with Gemma summary → Community notified
- Designer finalization: All UI screens finalized + exported

**Success criteria**:
- ✅ Both WOW factors working
- ✅ Full flow <2 minutes total
- ✅ Zero crashes
- ✅ UI polished

---

### **Week 3 (April 22-28): QA + Submission Prep**

#### **Days 11-14 (Mon-Thu Apr 22-25): Manual QA Matrix**

| Scenario | Lead Dev | Test | Pass Criterion |
|----------|----------|------|----------------|
| Quiet voice activation | Dev 1 | Say phrase in silent room | Emotion <30%, no false police alert |
| Panic activation | Dev 1 | Scream + yell help | Emotion >70%, police SMS sent |
| Tier 1 responds at T=5 | Dev 2 + 3 | Contact taps "I'm helping" fast | Tier 2 NOT contacted, state locked at T1_RESPONDED |
| Tier 1 all silent at T=30 | Dev 2 + 3 | No contact responds | Tier 2 alert sent exactly at T=30 |
| Gemma threat analysis | Dev 3 | Real emergency audio | Threat identified correctly + confidence >85% |
| Community alert within 500m | Dev 3 | Other app user nearby | Notification received <10s |
| App stress test 30 min | All | Run full flow continuously | Zero crashes in logs |

**Daily standup** (9 AM): Each dev reports tests passed/failed + blockers

**By Thu EOD**:
- ✅ P0 bugs: 0
- ✅ P1 bugs: <5 (document + fix next week only if critical)
- ✅ All core flows tested + working

---

#### **Days 15-16 (Fri-Sat Apr 26-27): Final Build + Assets**

| Owner | Task | Completion |
|-------|------|------------|
| Dev 1 | Final APK build + signed | Sat EOD |
| Dev 4 | Final IPA build + provisioned | Sat EOD |
| Designer | Final responsive layout check (4 device sizes) | Sat EOD |
| DevOps | App store assets (5+ screenshots, descriptions, privacy policy) | Sat EOD |

**By Sat EOD**:
- ✅ APK <100 MB, tested on Android
- ✅ IPA <150 MB, tested on iOS
- ✅ App store metadata complete

---

### **Week 4 (April 29-May 17): Final Buffer + Submission**

**FEATURE FREEZE: NO NEW FEATURES. ONLY CRITICAL BUG FIXES.**

#### **Days 17-21 (Mon-Fri Apr 29-May 3): Final System Test**

| Day | Task | Owner |
|-----|------|-------|
| **Mon** | End-to-end testing on both platforms | All devs |
| **Tue** | Security audit (API keys, permissions, OAuth tokens) | Dev 4 |
| **Wed** | Performance audit (battery, memory, post latency) | Dev 1 |
| **Wed** | Bug triage: P0 = fix immediately, P1 = document | PM |
| **Thu-Fri** | Final build iteration + APK/IPA generation | DevOps |

#### **Days 22-40 (May 6-17): Submission Window**

| Date | Task | Owner |
|------|------|-------|
| **May 6** | Submit to Google Play + Apple App Store | DevOps |
| **May 7-9** | Monitor for approval (typically 24-48h) | DevOps + PM |
| **May 10-15** | Buffer: If rejections, fix + resubmit | All as needed |
| **May 16-17** | Final confirmation both apps live | All |

---

### Week 1-2 (April 7-20): Features + Design Parallel
**All 5 dev tracks + 1 design track work simultaneously**

**Daily Standups**: 9 AM, 15 minutes
- Each track: 1 shipped deliverable per day
- Designer: 1 finalized screen per day

**Key Milestones**:
| Date | Milestone | Owner |
|------|-----------|-------|
| April 9 | E2B account + Twilio account setup | DevOps |
| April 10 | Android/iOS devices ready, env setup | DevOps |
| April 12 | All 5 feature branches code-complete | All devs |
| April 13 | First integration test: voice → SMS → broadcast | All |
| April 15 | Feature complete, first build on devices | All |
| April 17 | All features working on real Android + iOS | All |

**What Ships by April 20**:
- ✅ Voice activation works on devices
- ✅ Location tracking + SMS sent
- ✅ Community alerts broadcast to nearby users
- ✅ Wow factor feature (choice of A/B/C/D) integrated
- ✅ Audio/haptic feedback implemented
- ✅ All 5 screens designed in Figma + handoff specs
- ✅ All app icons + splash screen + notification assets ready

---

### Week 3 (April 21-May 10): Polish + Testing + Submission Prep

**Focus**: Turn working prototype into submission-ready app

**Monday-Wednesday (April 21-24)**: Design Polish
- [ ] Designer polishes all 5 screens (spacing, typography, consistency)
- [ ] Export all assets (PNG, SVG, all densities)
- [ ] Create app store screenshots + descriptions
- [ ] Verify responsive layout on 4+ device sizes

**Thursday-Friday (April 25-26)**: QA & Bug Fixes
- [ ] Manual end-to-end testing on 2 Android + 2 iOS devices
- [ ] Test scenarios:
  - Voice activation in quiet room
  - Voice activation with background noise
  - Geolocation broadcast within 500m
  - Geolocation broadcast outside 500m
  - SMS delivery to 5 contacts simultaneously
  - Wow factor feature under stress (100+ events)
  - App backgrounded for 10+ minutes
  - Low battery mode
  - No network → offline degradation
- [ ] Log all bugs with priority (P0=blocker, P1=critical, P2=nice-to-have)

**Following Week (April 28-May 8)**: Bug Fixes + Hardening
- [ ] Fix all P0 bugs (day 1-2)
- [ ] Fix all P1 bugs (day 3-4)
- [ ] Performance tuning (reduce APK size, optimize memory)
- [ ] Security review (permissions, encryption, API keys)
- [ ] Final build + test

**May 9-10**: Submission Prep
- [ ] Create privacy policy
- [ ] Write app store descriptions (5+ screenshots with text)
- [ ] Build final APK + IPA
- [ ] Test both builds on devices
- [ ] Prepare submission docs

**May 11-17**: Submission Window
- [ ] May 11-13: Submit to Google Play + Apple App Store
- [ ] May 14-16: Monitor for approval (both typically 24-48 hours)
- [ ] May 17: Confirm both apps live

**May 18**: Final Deadline — Only critical hotfixes at this point

---

### Success Metrics by May 17

**All 6 must-haves ✅**:
1. Voice activation triggers within 1-2 seconds of phrase
2. Location captured accurately (within 20m)
3. SMS sent to all inner circle contacts within 3 seconds
4. Geolocation broadcasts to nearby users within 0.5km radius
5. Wow factor feature works reliably (>95% success rate)
6. App runs 30+ minutes without crashes

**Performance Targets**:
- APK size <100 MB (Android)
- IPA size <150 MB (iOS)
- Voice detection latency <3 seconds
- SMS delivery latency <5 seconds
- Community alert latency <10 seconds

**Quality Gates**:
- 0 compiler errors
- 0 P0 bugs
- <5 P1 bugs
- Unit test coverage >60%
- Manual QA pass on 4+ devices

---

## DEFER TO POST-LAUNCH (P2/P3)

These features are **NOT SHIPPED** by May 17. They're nice-to-have, but kill the MVP:

| Feature | Why Defer | Estimated Work |
|---------|-----------|-----------------|
| Gemma API Analysis | API integration complexity, Tracks A-C work without it | 5 days |
| Auto-Post to Social | OAuth complexity, Gemma API dependency | 5 days |
| Proximity Services | Google Places API integration, not critical | 3 days |
| Proximity Suggestions | Depends on Proximity Services | 2 days |
| Contact Management UI | Users set up during onboarding, can edit later | 2 days |
| Fake Call Feature | Not critical for MVP, nice-to-have anti-harassment | 4 days |
| Settings Screen | Can be minimal/hidden in first release | 2 days |
| Export/Backup | Users can export later via admin panel | 3 days |

**Total deferred work**: ~29 days of development
**Total MVP work**: ~40 days of parallel development (achievable)

---

## BRANCH STRUCTURE FOR TEAM ASSIGNMENTS

```
main (production-ready by May 17)
├── feature/voice-activation-mvp [TRACK A]
│   ├── VoiceRecognitionService.dart
│   ├── EmergencyActivationManager.dart
│   └── test/ (unit tests)
├── feature/location-tracking-mvp [TRACK B, Part 1]
│   ├── LocationTracker.dart
│   └── test/
├── feature/contact-notifications-mvp [TRACK B, Part 2]
│   ├── ContactStore.dart
│   ├── NotificationService.dart
│   └── test/
├── feature/local-database-mvp [TRACK C]
│   ├── models/IncidentModel.dart
│   ├── repositories/IncidentRepository.dart
│   ├── services/EncryptionService.dart
│   └── test/
└── feature/audio-haptic-mvp [TRACK D]
    ├── services/ConfirmationSoundService.dart
    ├── services/BackgroundServiceManager.dart
    ├── assets/sounds/
    └── test/
```

**Merge Schedule**:
- **EOD Friday (April 12)**: Each track merges to develop branch
- **Monday (April 15)**: Merged develop → main for first integration test
- **Daily**: Teams pull latest main, merge conflicts resolved immediately
- **May 17**: Final main branch = submission version

---

## BLOCKERS & PREREQUISITES

### Before Starting Any Track:

1. **Twilio Account Setup** (needed by Track B, Day 1)
   - [ ] Create Twilio account (free trial works for MVP)
   - [ ] Create SMS-capable phone number
   - [ ] Generate API credentials (Account SID + Auth Token)
   - [ ] Test SMS send via curl/Postman
   - [ ] **Owner**: [Assign]
   - [ ] **Timeline**: Day 1 (2 hours)

2. **E2B Account Setup** (needed by Track A, Day 1)
   - [ ] Create E2B account (e2b.dev)
   - [ ] Get API key for Gemma 2B access
   - [ ] Test local model startup
   - [ ] **Owner**: [Assign]
   - [ ] **Timeline**: Day 1 (2 hours)

3. **Android/iOS Device Setup** (needed by all tracks, Week 2)
   - [ ] Procure 4 devices minimum (2 Android, 2 iOS)
   - [ ] Setup dev environment (Android Studio, Xcode)
   - [ ] Configure code signing
   - [ ] **Owner**: [Assign]
   - [ ] **Timeline**: Day 1 (full day)

4. **GitHub Repo Setup** (needed by all, Day 1)
   - [ ] Create 5 branches listed above
   - [ ] Configure branch protection rules
   - [ ] Setup CI/CD for tests on push
   - [ ] **Owner**: [Assign]
   - [ ] **Timeline**: Day 1 (1 hour)

---

## METRICS FOR SUCCESS

### MVP Acceptance Criteria (ALL must be ✅ by May 17):

1. **Voice Activation**: Say phrase → EmergencyActiveScreen appears within 2 seconds
2. **Location Tracking**: Location updated every 10 seconds during emergency
3. **Contact Notifications**: SMS sent to all Tier 1 contacts within 5 seconds
4. **Audio/Haptic**: Confirmation feedback on all critical actions
5. **Background Operation**: Voice + location survive backgrounding on Android/iOS
6. **No Crashes**: App survives 30 minutes of emergency simulation without crashes
7. **Device Compatibility**: App runs on Android 10+ and iOS 14+
8. **Team Submission**: APK/IPA ready for app store submission

### Definition of Done for Each Track:

**Track A**: VoiceRecognitionService + EmergencyActivationManager fully tested on device
**Track B**: LocationTracker + NotificationService sending SMS reliably
**Track C**: Hive database storing/retrieving incidents without error
**Track D**: Audio + haptic feedback working, background service staying alive

---

## DAILY STANDUP FORMAT (15 min, 9 AM)

Each developer answers 3 questions:

1. **What did you ship yesterday?** (1 specific deliverable)
2. **What's your blocker today?** (be honest, ask for help)
3. **What will you ship today?** (one specific deliverable)

**Pattern**: If anyone is blocked, entire team helps resolve it ASAP (parallel work pauses).

---

## DECISION: Test on Chrome or Real Devices?

**Chrome testing is NOT enough.** You must test on actual Android/iOS devices because:
- Voice recognition works differently on-device vs. browser
- Background services don't exist in browser
- Haptic feedback requires native plugins
- Location permissions work differently on mobile

**Timeline impact**: You lose 2-3 days in Week 2 getting devices set up, but you SAVE 5 days later by catching integration bugs early.

---

## If You Fall Behind Schedule

**Priority override order** (drop features in this order if timeline slips):

1. **Day 15 (April 22)**: If location isn't working → drop location tracking, use phone GPS only
2. **Day 20 (April 27)**: If Hive database isn't stable → use SharedPreferences only (no complex queries)
3. **Day 25 (May 2)**: If SMS notifications failing → send only to first contact, not all Tier 1
4. **May 10 onwards**: Only critical bug fixes, no new features

---

## Submission Checklist (May 15-17)

Before hitting "submit" to app stores:

- [ ] All 4 tracks merged to main
- [ ] No compiler errors or warnings
- [ ] All unit tests passing
- [ ] Manual end-to-end test passed (voice → SMS )
- [ ] App runs for 30 minutes without crashes
- [ ] Android APK built and signed
- [ ] iOS IPA built and signed
- [ ] Privacy policy written and included
- [ ] Onboarding covers all permissions
- [ ] README.md includes setup instructions
- [ ] GitHub repo contains all code (no binaries in git)
- [ ] Git history is clean (no merge conflicts left)

---

## Post-Launch Roadmap (May 18+)

Once MVP ships, immediately start work on:

1. **Gemma API Integration** (Week 1 post-launch)
   - Real-time incident analysis during emergency
   - Threat assessment

2. **Auto-Post Alerts** (Week 2 post-launch)
   - Social media integration (Twitter/Nextdoor)
   - Community notification

3. **Advanced Features** (Week 3+ post-launch)
   - Fake Call feature
   - Settings/preferences UI
   - Map visualization
   - Export incidents as PDF

---

## Key Assumptions

1. **E2B/Gemma 2B works locally** - if API latency issues arise, switch to cloud Gemma API immediately
2. **Twilio SMS is reliable** - have WhatsApp backup if SMS fails
3. **Android/iOS devices available** - team procures or borrows devices by April 10
4. **Team works 8-10 hours/day simultaneously** - no staggered schedules (hard deadline)
5. **No scope creep** - if user requests new feature, it goes to post-launch roadmap

---

## Contact Person for Blockers

Assign one person as **Technical Lead** who:
- Resolves cross-track dependency issues
- Decides feature scope questions
- Updates this doc as timeline changes
- Coordinates daily standups

**Suggested**: Most experienced developer or project manager

---

---

# 🎯 CAN YOU DELIVER IN 3 WEEKS? YES, BUT WITH CAVEATS

## Honest Assessment: Attainability of 3-Week Timeline

### ✅ YES, you can deliver a functional MVP by May 17 because:

1. **Heavy UI work is DONE** (7 screens already built)
   - Core screens exist: HomeScreen, EmergencyActiveScreen, OnboardingFlow, ContactsScreen
   - No need to rebuild from scratch
   - Designer focus = polish, not creation

2. **Voice activation is low-complexity** (Track A)
   - `speech_to_text` package is mature + well-documented
   - E2B integration is straightforward (API call to hosted model)
   - No fancy ML training needed

3. **Location + SMS is battle-tested** (Track B)
   - `geolocator` + `twilio_flutter` are production-ready packages
   - Thousands of apps use this exact stack
   - Simple integration if Twilio account ready

4. **Geolocation community alerts is NEW but not complex** (Track C)
   - Firebase FCM is industry standard
   - Geohash-based queries are well-documented
   - Biggest risk: backend Cloud Function (but can use Firebase template)

5. **Wow factor features are achievable in parallel** (Track E)
   - All 4 options (Gemma analysis, auto-post, emotion detection, transcription) are 8-10 day jobs
   - **Option C (emotion detection)** is fastest: existing TensorFlow Lite models, just load + infer

6. **Team size is now ideal** (6 people)
   - 4 devs = 4 simultaneous tracks (no bottlenecks)
   - 1 designer = polishes screens while devs code (no blocking)
   - 1 product/ops = handles DevOps, Firebase setup, Twilio config, device management

### ⚠️ CRITICAL ASSUMPTIONS (must be true):

| Assumption | If False → Problem |
|-----------|-------------------|
| Android/iOS devices available by April 10 | Can't test background services, lose 3 days |
| Twilio account + E2B account ready by April 8 | Blocks Track B + Track A from starting |
| Team member commitment (8-10 hours/day continuous) | Falls behind on Week 1, cascades to Week 2 |
| No scope creep ("just add this feature...") | Kills timeline by May 5 |
| Designer available full-time Week 1-3 | Screens delivered late, devs waiting for specs |
| Firebase/Cloud Function knowledge on team | Backend setup takes 3-4 days instead of 1 |
| No major Android/iOS OS-level bugs discovered | A single native API issue costs 2-3 days |

### 🔴 BIGGEST RISKS (Ranked by Likelihood):

1. **Background services on iOS** — Apple's backgrounding model is unpredictable
   - Voice listener may get killed after 5 minutes
   - Location tracking may pause unexpectedly
   - Solution: Test on real device by April 12, pivot to fallback if needed
   - **Time risk**: +3 days if major rework needed

2. **Geohash queries at scale** — Firebase geohash performance untested in your context
   - If 100+ users in 500m radius, query may timeout
   - Solution: Load-test early (April 10), use Redis geospatial index if needed
   - **Time risk**: +2 days if DB optimization needed

3. **Gemma API latency** — If running Gemma analysis during emergency:
   - Network latency could exceed 5 seconds
   - Solution: Test April 12, have offline fallback ready
   - **Time risk**: +1 day if fallback implementation needed

4. **Designer availability slippage** — If designer context-switches to other work:
   - Devs waiting for Figma specs by April 15
   - QA phase delayed
   - Solution: Shield designer from other distractions, stagger Figma delivery
   - **Time risk**: +2-3 days

5. **Text-to-speech or audio playback bugs** — Mobile audio APIs are finicky
   - Android: AudioManager focus issues
   - iOS: AVAudioSession interruptions
   - Solution: Test audio by April 13
   - **Time risk**: +1 day

### 🟢 WHAT MITIGATES RISK:

✅ **Parallel work** — All 5 dev tracks independent = if 1 slips, others keep moving
✅ **Pre-built UI** — Devs focused on backend logic, not UI engineering
✅ **Proven packages** — No custom ML models, no novel algorithms
✅ **Feature simplicity** — No social graphs, no complex state management
✅ **Team size** — 6 people can divide work evenly (no over-dependence on 1 person)

### 📊 PROBABILITY SCORING:

| Scenario | Likelihood | Contingency |
|----------|-----------|-------------|
| **All features done + polished by May 10** | **60%** | Aggressive but possible if no blockers |
| **Core 3 features done, wow factor partial** | **85%** | Most likely scenario—cut wow factor polish |
| **Core 3 features done, wow factor deferred** | **95%** | Safe option—submit July with wow factor |
| **Miss May 17 deadline entirely** | **8%** | Only if 2+ major blockers (iOS backgrounding + Firebase scaling) |

---

## THE VERDICT: 3-Week Timeline is **ACHIEVABLE but AGGRESSIVE**

### Decision Framework:

**Choose this plan IF**:
- [ ] You have 4 committed devs + 1 full-time designer + 1 DevOps person
- [ ] You can procure Android/iOS devices by April 10
- [ ] Twilio + E2B accounts are set up by April 8
- [ ] Team can sustain 8-10 hour days for 3 weeks
- [ ] You're OK with "beta quality" at May 17 (not polished)
- [ ] You want ONE wow factor, not perfection

**Contingency Plan IF timeline slips**:

| Date | Action |
|------|--------|
| April 15 | If voice activation not working → pivot to 4-week timeline, extend Week 3 to May 24 |
| April 20 | If both voice + location failing → drop wow factor, focus on core 3 features only |
| April 28 | If Geolocation alerts not working → delete community feature, ship inner circle only |
| May 5 | If more than 10 P1 bugs → accept "beta" label, fix critical bugs post-launch |
| May 10 | Feature freeze: NO NEW FEATURES after this, only bugfixes |

---

## IMMEDIATE ACTION ITEMS (Next 48 Hours)

### Day 1 (Today):
- [ ] Confirm all 6 team members + their commitment level
- [ ] Assign Track owners (A, B, C, D, E, F)
- [ ] Choose ONE wow factor (A/B/C/D) — **Recommend C: Emotion Detection**
- [ ] Create GitHub branches (5 feature branches)
- [ ] Schedule 1-hour kickoff meeting with all 6

### Day 2 (Tomorrow):
- [ ] Setup external accounts:
  - [ ] Twilio account + SMS API keys
  - [ ] E2B account + Gemma 2B API connection
  - [ ] Firebase project + Firestore setup
  - [ ] GitHub Actions CI/CD (if not already done)
- [ ] Procure devices (order now, arrive by April 10)
- [ ] Setup dev environment (all 4 devs running Flutter on Android Studio + Xcode)
- [ ] Designer: start with HomeScreen + EmergencyActiveScreen Figma specs

**Once these are done, you're READY TO START the 3-week sprint.**

---

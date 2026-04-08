# Guardian App: Team Brief — May 17 Kaggle Deadline

**Meeting**: Tomorrow (April 9, 9 AM)
**Duration**: 30 minutes
**Attendees**: 4 developers + 1 designer + 1 DevOps lead

---

## Your Mission (30 Seconds)

Build Guardian: An AI-powered emergency safety app that detects danger in real-time and alerts your community. **Ship by May 17 to Kaggle.**

---

## Hard Constraints

| Constraint | Why | Impact |
|-----------|-----|--------|
| **May 17 deadline** | Kaggle submission closes | **NO EXTENSION** |
| **2 weeks to code** (Apr 8-21) | Get all features working on devices | Must ship features, not polish |
| **Parallel tracks** (4 devs) | The only way we fit everything | **NO DEPENDENCIES** between tracks |
| **Setup day is Apr 8** | Accounts/devices are the blocker | **If Apr 8 fails → May 24 becomes deadline** |

---

## What We're Building (User Flow)

1. **Download + Setup** (5 min)
   - Add 3-5 emergency contacts (Tier 1)
   - Record voice phrase ("Gemma help me")
   - Grant permissions (location, mic, background)

2. **Background Listening** (always on)
   - App listens for voice phrase in background
   - Silent operation, no battery drain

3. **Emergency Activation**
   - Say phrase → Voice detected in <2s
   - EmergencyActiveScreen appears with timer
   - Gemma starts analyzing live audio

4. **Escalation (THE COMPLEX PART)**
   - **T=0-5s**: Send Tier 1 WhatsApp alert to all 3-5 contacts
     - Message: "Esther in danger at [LOCATION]"
     - Proof: 15-second audio clip
     - Gemma analysis: "Kidnapping detected - 92% confidence - CALL POLICE"
   - **T=5-30s**: Wait for Tier 1 response
     - Contact sees: "I'm helping" button (they tap to activate tracking)
     - If contact helps → STOP escalation, enter active tracking
   - **T=30s**: If NO Tier 1 response, escalate to Tier 2
     - Send same alert to 5-10 secondary contacts
     - Same format, more urgency
   - **T=60s**: If NO response, Twitter auto-post (if set up)

5. **Active Tracking** (if contact responds)
   - Contact location shared periodically
   - Audio clips sent for analysis
   - Responding contact gets live updates

6. **Close Emergency**
   - User marks safe OR contact confirms rescue
   - Emergency ends, all contacts notified

7. **Community Layer** (runs in background)
   - Nearby app users (<500m) get silent notification
   - "Esther triggered emergency near you. Can you help?"
   - Users can respond or dismiss

---

## Team Assignments (Choose your track)

### Developer Track A: Voice Activation (Dev 1)
**Your role**: Make the app hear "Gemma help me" and respond immediately

**What you build**:
- `VoiceRecognitionService`: Recognize voice phrase with E2B local model
- `EmergencyActivationManager`: Show emergency screen, capture audio buffer
- `EmotionDetectionService` (Week 2): Analyze user's voice for fear/panic

**Success metric**: 
- Voice detected in <2 seconds
- Emotion gauge showing fear level on screen
- Auto-police SMS on panic >70%

**Timeline**: 
- Week 1 (Apr 8-12): Voice activation working end-to-end
- Week 2 (Apr 17-19): Emotion detection integrated + police trigger
- Week 3: QA + bug fixes

---

### Developer Track B: Location + Tier 1 Escalation (Dev 2)
**Your role**: Get location and send emergency alert to inner circle contacts

**What you build**:
- `LocationTracker`: GPS capture, ±20m accuracy
- `EscalationManager`: State machine (Tier 1 → 30s wait → Tier 2)
- `TierOneAlertService`: WhatsApp to 3-5 contacts with proof

**Success metric**:
- Location captured <5 seconds
- Tier 1 WhatsApp sent to all contacts <5 seconds
- Tier 2 alert triggers precisely at T=30s (if no response)

**Timeline**:
- Week 1 (Apr 8-12): Location + basic Tier 1 alert working
- Week 2 (Apr 15-16): 2-tier escalation FSM perfected
- Week 3: QA + bug fixes

---

### Developer Track C: Gemma + Community Alerts (Dev 3)
**Your role**: Analyze emergency with Gemma, alert nearby community

**What you build**:
- `GemmaThreatAssessmentService`: Stream audio to Gemma 4 API, get threat type + confidence
- `GeolocationAlertService`: Firebase/geohash queries for nearby users
- `CommunityAlertService`: FCM broadcast to nearby users within 500m

**Success metric**:
- Gemma responds with threat assessment <3 seconds
- WhatsApp alert includes Gemma summary ("92% kidnapping confidence")
- Community notifications sent within 10 seconds
- No false positives (0.1% error rate max)

**Timeline**:
- Week 1 (Apr 8-12): Firebase setup + community alerts working
- Week 2 (Apr 17-19): Gemma threat assessment integrated + WhatsApp includes summary
- Week 3: QA + optimization

---

### Developer Track D: Audio/Native (Dev 4)
**Your role**: Make sounds, vibrations, and background services work

**What you build**:
- `ConfirmationSoundService`: 4 sounds (activation, sent, success, error)
- Haptic feedback patterns for every critical action
- `BackgroundServiceManager`: Foreground service (Android) + background modes (iOS)
- App lifecycle handling (pause/resume)

**Success metric**:
- Sounds play at right moments
- Haptic feedback works on both Android + iOS
- Voice listener survives background for 30+ minutes
- No crashes when app backgrounded

**Timeline**:
- Week 1 (Apr 8-12): Sounds + haptics + background listener working
- Week 2 (Apr 15-21): Integration + optimization
- Week 3: QA + device testing

---

### Designer: UI Polish (Designer)
**Your role**: Make it beautiful and usable

**What you build**:
- Finalize all 5 screens in Figma (home, emergency-active, onboarding, contacts, alert)
- Design emotion detection gauge
- Design geolocation alert notification card
- Export assets (icons, splash screen, launch assets)
- App store screenshots + descriptions

**Success metric**:
- All screens follow brand (teal #0891B2, Poppins font)
- Responsive on 4+ device sizes
- All assets exported by Week 3

**Timeline**:
- Week 1-2: Parallel with devs, deliver Figma specs daily
- Week 3: Final polish + app store assets

---

### DevOps: Setup + Unblocking (DevOps)
**Your role**: Everything works, no excuses

**What you do**:
- **Apr 8 EOD (CRITICAL)**: Twilio + E2B + Firebase + GCP credentials all live
- Daily: Unblock developers (permissions, API keys, device issues)
- Week 3: App store builds, submission, monitoring

**Success metric**:
- Zero setup delays
- All tools accessible by Apr 8 EOD
- Both APK + IPA buildable by Week 3

---

## Daily Standup (9 AM, 15 Minutes)

**Every single day**, each person answers:

1. **What did I ship yesterday?** (One specific code artifact)
2. **What's blocking me?** (Be honest, we'll fix it TODAY)
3. **What will I ship today?** (One specific goal)

**Pattern**:
- If blocker reported → entire team pauses to fix it (same hour, not next day)
- No standup = automatic escalation to PM

---

## Weekly Milestones (Hit These or We Miss May 17)

| Week | Milestone | Status |
|------|-----------|--------|
| **Week 1 (Apr 12)** | All 4 core tracks working together on device, zero crashes | ✅ MUST HAVE |
| **Week 2 (Apr 19)** | Both WOW factors integrated + tested, full flow <2 min | ✅ MUST HAVE |
| **Week 3 (Apr 25)** | P0 bugs: 0, P1 bugs: <5, APK + IPA ready | ✅ MUST HAVE |

---

## What Happens If You Fall Behind?

### **By April 15 (Day 8): Red Flag**
If core features (voice + location + escalation) not working on device → escalate to PM, reduce scope

### **By April 22 (Day 15): Feature Freeze**
No new features after this. Only bug fixes:
- **P0** (crashes, core safety issues): Fix immediately
- **P1** (core flow broken): Fix same day
- **P2** (cosmetic): Document for post-launch

### **By May 10 (Day 33): Last Chance**
Final build ready. If app store rejects → resubmit same day. No second submissions after May 15.

---

## Success = All of These at May 17

- [ ] Voice activation works <2 seconds
- [ ] Location captured accurately
- [ ] Tier 1 + Tier 2 escalation works (30s timeout precise)
- [ ] WhatsApp alert sent <5 seconds
- [ ] Emotion detection shows fear level
- [ ] Gemma threat assessment explains threat to contacts
- [ ] Community alerts sent <10 seconds
- [ ] App runs 30+ minutes without crash
- [ ] APK <100 MB, IPA <150 MB
- [ ] Both apps live on Google Play + Apple App Store

---

## Team Commitments (Required for May 17)

**I commit to:**
- [ ] Showing up to standup every day (9 AM, sharp)
- [ ] Shipping 1 deliverable per day
- [ ] Telling PM immediately if blocked (don't wait)
- [ ] Testing on device every Friday
- [ ] No new features after Apr 22
- [ ] 10-hour days if needed in final week

**Team commitment**: All 6 of us, no exceptions, **until May 17**

---

## Questions Before We Start?

**Ask NOW, not later.**

- Questions about your track?
- Questions about integration?
- Questions about API credentials?
- Questions about dev environment?

**After we start, we only have questions during standup.**

---

## The Reality

**This is AGGRESSIVE and DOABLE.**

- Parallel work (4 devs) means no waiting
- 2-week build + 1-week QA + 1-week buffer is tight but structured
- If everyone hits their milestones, May 17 is guaranteed

**But if anyone slips:**
- Day 1 setup → May 24 becomes deadline
- Week 1 integration → May 24 becomes deadline
- Week 2 WOW factors → May 24 becomes deadline

**So the question is: Are all 6 of us ready to commit 100% for 6 weeks?**

If no → we change deadline to May 24 (more comfortable, still competitive)
If yes → let's ship May 17 and WIN

---

**Your call. Let's build something incredible.**


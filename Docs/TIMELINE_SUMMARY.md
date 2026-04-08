# 3-Week Delivery Plan — Guardian App MVP

## TL;DR: Is 3 Weeks Possible?

**✅ YES, 60-85% probability of success** if:
- 6-person team (4 devs + 1 designer + 1 devops) works 8-10 hours/day
- Devices + accounts set up by April 10
- NO scope creep after April 15
- All tracks stay in parallel (not sequential)

**🟢 Most Likely Outcome**: Core 3 features shipped by May 17, wow factor 80% complete or deferred to post-launch

---

## The Team (6 People)

| Track | Owner | Role | Feature |
|-------|-------|------|---------|
| **A** | Dev 1 | Voice Lead | Voice activation + emergency trigger (E2B integration) |
| **B** | Dev 2 | Location Lead | Location tracking + SMS alerts (Twilio) |
| **C** | Dev 3 | Backend Lead | Geolocation community alerts (Firebase FCM + Cloud Function) |
| **D** | Dev 4 | Native Lead | Audio/haptic + background services (Android/iOS native code) |
| **E** | Dev 1-4 | Wow Factor | Choose 1: Emotion detection, Gemma analysis, auto-post, or transcription |
| **F** | Designer 1 | Design Lead | UI polish, Figma specs, app store assets |
| — | DevOps 1 | Ops | Twilio setup, E2B setup, Firebase, devices, GitHub actions |

---

## 3-Week Timeline at a Glance

```
WEEK 1-2 (April 7-20): CODE + DESIGN PARALLEL
├─ Work: Every dev ships 1-2 features, designer ships 1 Figma screen/day
├─ Monday: E2B + Twilio accounts ready
├─ Wednesday: Device setup complete
├─ Friday (Apr 12): All code merged, ready for integration test
└─ Wednesday (Apr 17): Features working on real devices

WEEK 3 (April 21-May 10): POLISH + QA
├─ Monday-Wed: Designer polishes all screens (spacing, fonts, consistency)
├─ Thursday-Fri: QA team manually tests end-to-end on 4 devices
├─ Following week (Apr 28-May 8): Bug fixes (P0 + P1)
└─ May 9-10: Final build, privacy policy, app store listings

SUBMISSION (May 11-17): GET APPS LIVE
├─ May 11-13: Submit to Google Play + Apple App Store
├─ May 14-16: Wait for approval (24-48 hours typically)
└─ May 17: Confirm both apps live
```

---

## What Ships by May 17

### ✅ CORE FEATURES (100%)

1. **Voice Activation** — Say phrase → Emergency screen appears in <2 seconds
2. **Location Tracking** — GPS updated every 10 seconds, survives backgrounding
3. **Inner Circle SMS** — Alert 3-5 trusted contacts with location via Twilio
4. **Geolocation Community Alerts** — Nearby users (<500m) notified silently within 10 seconds

### ✅ AUDIO/HAPTIC (100%)

- Confirmation sounds: voice detected, SMS sent, emergency stopped
- Haptic feedback: taps + vibrations for all critical actions
- Silent mode: haptics-only when phone muted

### ✅ WOW FACTOR (80-100%, choose 1)

**Option A: Emotion Detection** ← Recommended
- Local AI analyzes user's voice during emergency
- Detects fear/panic in audio (confidence 0-100)
- Auto-trigger police dispatch if panic >70%
- Display emotion gauge on emergency screen

**Option B: Gemma Threat Analysis**
- Real-time Gemma API analysis of audio
- Generates threat assessment + recommendation
- Shows confidence score (e.g., "92% high-threat")

**Option C: Auto-Post to Social**
- Tweet + Nextdoor post automatically on activation
- Location-based alert for community visibility
- OAuth integration with Twitter/Nextdoor APIs

**Option D: Real-Time Transcription**
- Live speech-to-text of emergency audio
- Extract danger keywords (knife, gun, fire, etc.)
- Auto-populate police report with details

### ✅ DESIGN & POLISH (100%)

- All 5 screens designed in Figma (hand-off specs to devs)
- App icon + splash screen + notification assets
- Responsive layout tested on 4+ device sizes
- App store screenshots + descriptions ready
- Privacy policy written

---

## What's DEFERRED to Post-Launch (May 18+)

- [ ] Advanced incident history (users don't want trauma replay)
- [ ] Fake call system
- [ ] Settings/preferences screens
- [ ] Export incidents as PDF
- [ ] Proximity services (hospitals, police stations)
- [ ] Dark mode theme
- [ ] Advanced analytics/crash reporting

---

## Key Dates & Milestones

| Date | What | Owner | Status |
|------|------|-------|--------|
| **Today** | Assign team + choose wow factor | PM | ⬜ |
| **Apr 8** | Twilio + E2B accounts ready | DevOps | ⬜ |
| **Apr 10** | Devices + dev environment setup | DevOps | ⬜ |
| **Apr 12** | All code merged to main | All devs | ⬜ |
| **Apr 13** | First integration test (voice→SMS→alert) | All | ⬜ |
| **Apr 17** | Features working on Android + iOS devices | All | ⬜ |
| **Apr 20** | Design complete, ready for polish | Designer | ⬜ |
| **Apr 28** | All P0 bugs fixed | All | ⬜ |
| **May 5** | Final app store builds ready | Build team | ⬜ |
| **May 10** | Privacy policy + store listings done | Writer | ⬜ |
| **May 11** | Submit to app stores | DevOps | ⬜ |
| **May 17** | DEADLINE—confirm both apps live | All | 🎯 |

---

## Risks & Contingencies

### 🔴 Top Risks (Ranked)

1. **iOS Background Services** (Likelihood: High)
   - Problem: Apple kills voice listener after 5 minutes
   - Detection: Apr 12 device testing
   - Fallback: Periodic wake-ups instead of continuous listening
   - Cost if happens: +2-3 days

2. **Geohash Queries at Scale** (Likelihood: Medium)
   - Problem: Firebase query timeouts with 100+ users in 500m
   - Detection: Apr 15 load testing
   - Fallback: Use simple distance calculation instead of geohash
   - Cost if happens: +1-2 days

3. **Designer Context Switching** (Likelihood: Medium)
   - Problem: Designer pulled for other work → devs waiting for specs
   - Prevention: Shield designer from distractions Week 1-3
   - Cost if happens: +2-3 days

4. **Scope Creep** (Likelihood: High)
   - Problem: "Just add this small feature" after Apr 15
   - Prevention: Feature freeze after Apr 15, defer everything
   - Cost if happens: +3-5 days

### 🟡 Contingency Plan

**If you fall behind:**

- **April 20**: If voice activation failing → extend wow factor by 1 week, still ship core 3 features
- **April 28**: If geolocation alerts failing → ship inner circle SMS only, community feature becomes post-launch
- **May 5**: If 10+ bugs remain → accept "beta label", prioritize P0 critical bugs only
- **May 10**: Feature freeze → NO new features, only bugfixes

---

## Success Checklist (May 17)

Before submitting:

- [ ] All 4 core tracks code-complete + tested
- [ ] Wow factor feature working (>95% reliability)
- [ ] Designer polished all 5 screens
- [ ] App runs 30+ minutes without crashes
- [ ] Voice activation <2 seconds latency
- [ ] SMS sent within 5 seconds
- [ ] Community alerts broadcast within 10 seconds
- [ ] APK size <100 MB, IPA <150 MB
- [ ] 0 compiler errors, 0 P0 bugs, <5 P1 bugs
- [ ] Privacy policy included
- [ ] All app store assets ready
- [ ] Final build tested on Android + iOS devices

---

## Next Steps (RIGHT NOW)

### Today:
1. [ ] Confirm 6-person team + commitment
2. [ ] Assign track owners (A, B, C, D, E, F)
3. [ ] **Choose WOW FACTOR**: Emotion Detection (fastest), Gemma Analysis (most impressive), Auto-Post (most social impact), or Transcription (most practical)
4. [ ] Create 5 GitHub branches

### Tomorrow:
1. [ ] Setup Twilio account + get SMS API keys
2. [ ] Setup E2B account + get Gemma 2B API key
3. [ ] Setup Firebase project + Firestore
4. [ ] Order Android/iOS devices (DHL priority if available)
5. [ ] Kick off design (Figma HomeScreen + EmergencyActiveScreen specs)

### This Week:
1. [ ] DevOps: complete all environment setup
2. [ ] All devs running Flutter, connected to GitHub
3. [ ] Designer: deliver HomeScreen + onboarding first 2 screens Figma specs
4. [ ] Tracks A-E: start coding

---

## Why This Works

✅ **Parallel tracks** — No dependencies between voice, location, and community alerts
✅ **Proven packages** — `speech_to_text`, `geolocator`, `firebase_messaging` are production-ready
✅ **Pre-built UI** — 7 screens already exist, designer just polishes
✅ **Team balance** — 4 devs + 1 designer = no bottlenecks
✅ **Wow factor in parallel** — Doesn't block core features
✅ **Clear prioritization** — If behind, drop wow factor not core features

---

## Final Verdict

**3-week timeline = ACHIEVABLE but AGGRESSIVE**

You can deliver a functional, polished MVP by May 17 IF:
- Team is 100% committed (no context-switching)
- Accounts + devices ready by April 10
- You accept "good" not "perfect" (beta quality)
- You stick to 1 wow factor, not all 4

**Expected outcome:** May 17 submission with core 3 features + 1 wow factor ✅
**Contingency:** If major blocker (iOS + geohash), ship June 1 with all features polished 🟡

**Go/No-Go decision needed TODAY.** Let me know what you choose!

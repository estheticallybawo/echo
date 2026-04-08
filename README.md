# Guardian - AI-Powered Emergency Response System

**Mission:** Guardian uses Gemma 4 AI to provide instant emergency alerts, location sharing, and automated contact notification. Built to honor Iniubong "Hiny" Umoren and prevent tragedies.

**Status:** May 17 MVP (Feature-complete, design refinement phase)

---

## 🚀 Quick Start

### Prerequisites
- **Flutter:** 3.19+ ([install](https://flutter.dev/docs/get-started/install))
- **Dart:** 3.3+ (included with Flutter)
- **Git:** For version control
- **Figma:** For design reference (optional)

### 1. Clone & Setup
```bash
git clone <[repo-url](https://github.com/estheticallybawo/the-gemma-4-good-project.git)> hi_gemma
cd hi_gemma
flutter pub get
```

### 2. Run the App
```bash
# Development (Chrome for fast iteration)
flutter run -d chrome

# Mobile (iOS)
flutter run -d ios

# Mobile (Android)
flutter run -d android
```

### 3. Key File References

**For Developers:**
-  [ARCHITECTURE.md](ARCHITECTURE.md) - Service layer, state management, workflow docs
-  [lib/screens/](lib/screens/) - All UI screens
-  [lib/theme.dart](lib/theme.dart) - Color palette & typography

**For Designers:**
-  [DESIGN_BRIEF.md](DESIGN_BRIEF.md) - Brand guidelines, color system, design philosophy
-  [DESIGN_CHECKLIST.md](DESIGN_CHECKLIST.md) - Screen specifications & wireframes

**For Project Manager:**
-  FEATURES.md - Feature list & MVP scope (if exists)
-  TASK_TRACKING.md - Sprint tracking & task assignments (if exists)

---

##  Project Structure

```
lib/
├── main.dart                 # App entry point
├── theme.dart               # Design system (colors, fonts)
├── screens/
│   ├── onboarding_flow.dart  # 7-page onboarding journey
│   ├── emergency_active_screen.dart  # Real-time emergency UI
│   ├── home_screen.dart      # Main dashboard (TODO)
│   └── ...
└── services/
    ├── voice_recognition_service.dart    # (Placeholder)
    ├── location_tracker_service.dart     # (Placeholder)
    ├── gemma_analysis_service.dart       # (Placeholder)
    └── notification_service.dart         # (Placeholder)
```

---

##  Common Commands

| Command | Purpose |
|---------|---------|
| `flutter run` | Run on emulator/device |
| `flutter run -d chrome` | Web browser (fastest for iteration) |
| `flutter analyze` | Check code issues |
| `flutter format lib/` | Auto-format code |
| `flutter clean` | Clear build cache |
| `flutter pub upgrade` | Update dependencies |

---

##  Getting Oriented

### First Time Here?
1. Read [ARCHITECTURE.md](ARCHITECTURE.md) (5-10 min overview)
2. Explore [lib/screens/onboarding_flow.dart](lib/screens/onboarding_flow.dart) to see page structure
3. Check [DESIGN_BRIEF.md](DESIGN_BRIEF.md) for color/font usage

### Adding a Feature?
1. Reference the service pattern in ARCHITECTURE.md
2. Create new service file in `lib/services/`
3. Wire into state manager (EmergencyStateManager)
4. Add UI in appropriate screen file

### Fixing a Bug?
1. Run `flutter analyze` to spot issues
2. Check [ARCHITECTURE.md](ARCHITECTURE.md) workflow section
3. Test in Chrome first (faster reload cycles)

### Design Changes?
1. Update colors/fonts in [lib/theme.dart](lib/theme.dart)
2. Reference [DESIGN_BRIEF.md](DESIGN_BRIEF.md) for rules
3. Run `flutter format` to keep code clean

---

##  Current Template Status

###  Completed
- Onboarding flow (7 pages)
- Emergency active screen (3 WOW widgets)
- Theme system (colors, typography)
- Voice phrase recording UI
- Twitter OAuth template (Page 5)
- Audio/haptic preview (Page 6)

###  In Progress
- Home screen design
- Contact management UI
- Settings / preferences

###  Deferred (Post-Launch)
- IncidentRepository (local storage)
- Actual service implementations (voice, location, Gemma)
- Incident history screen

---

##  Documentation

| Document | For | Purpose |
|----------|-----|---------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Developers | Service layer, state management, workflows |
| [DESIGN_BRIEF.md](DESIGN_BRIEF.md) | Designers | Brand guidelines, color system, design philosophy |
| [DESIGN_CHECKLIST.md](DESIGN_CHECKLIST.md) | Designers | Screen specs, wireframes, to-do lists |
| [lib/theme.dart](lib/theme.dart) | Developers | Color palette (copy exact values from here) |

---

##  Issues?

**App won't run?**
- `flutter clean` → `flutter pub get` → `flutter run -d chrome`

**Colors look wrong?**
- Check [lib/theme.dart](lib/theme.dart) — use GuardianColors constants, not hardcoded values

**Design questions?**
- Reference [DESIGN_BRIEF.md](DESIGN_BRIEF.md) sections

**Architecture questions?**
- Check [ARCHITECTURE.md](ARCHITECTURE.md) service patterns

---


**Questions? Read the docs first, then ask in Whatsapp Group.** 

Good luck! 🚀

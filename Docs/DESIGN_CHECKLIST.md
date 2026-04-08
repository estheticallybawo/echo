# Guardian App - Designer Checklist & Screen Specs

**Quick Reference Guide for Design Deliverables**

---

## 🎯 Priority 1: ONBOARDING FLOW (Pages 1-7)

### Page 1: Hiny's Story
**Status:** Placeholder needs refinement  
**Decision Needed:** Use illustration or photo of Hiny?

```
Layout:
┌─────────────────────────────────────┐
│                                     │
│    INIUBONG "HINY" UMOREN          │ (48px Poppins, Blue)
│           (name tagline)            │
│                                     │
│        [Profile Avatar]             │ (100x100px circle, Light gray BG)
│        (Icon placeholder)            │
│                                     │
│    "26 years old. 2021. A fake     │ (18px Inter, centered, dark gray)
│     job offer in Uyo. One last     │ (line-height 1.8)
│     phone call. No one could        │
│     reach her in time."             │
│                                     │
│    Guardian exists so this never    │ (32px Poppins, Blue, bold)
│    happens again.                   │
│                                     │
│         [NEXT Button]               │ (Primary blue, 300ms animation)
│                                     │
└─────────────────────────────────────┘

Colors: Light gray bg, blue text for emphasis
Spacing: 48px top padding, 24px between sections
Typography: Poppins/Inter hierarchy established
```

**TODO:**
- [ ] Design Hiny's profile image (illustration or photography style?)
- [ ] Ensure emotional tone is respectful (not sensationalized)
- [ ] High contrast check (A level on female faces in illustrations)

---

### Page 2: Permissions
**Status:** Functional, needs visual refinement

```
Layout:
┌─────────────────────────────────────┐
│ APP PERMISSIONS                      │ (48px Poppins)
│ Guardian needs access to keep safe  │ (Subtitle, gray)
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 📍 Location           [Toggle] ⊙│ │ (Card: light gray bg, border)
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 🎤 Microphone         [Toggle] ⊙│ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 👥 Contacts           [Toggle] ⊙│ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 🔔 Notifications      [Toggle] ⊙│ │
│ └─────────────────────────────────┘ │
│                                     │
│ "You can change these in Settings    │ (Small text, gray, bottom)
│  anytime."                           │
│                                     │
│  [  BACK  ]        [  NEXT  ]       │
│                                     │
└─────────────────────────────────────┘

Card specs:
- Padding: 12px inside
- Border: 1px solid light gray
- Border-radius: 12px
- Toggle switch: Primary blue when ON
```

**TODO:**
- [ ] Icon designs for each permission (Location, Mic, Contacts, Push)
- [ ] Toggle ON state animation (smooth slide + color change)
- [ ] Test toggle accessibility (keyboard navigation)

---

### Page 3: Voice Phrase Recording
**Status:** Core UI done, needs animation refinement

```
Layout:
┌─────────────────────────────────────┐
│ YOUR SAFETY PHRASE                   │ (48px)
│ Create a unique phrase you'll say   │ (Subtitle)
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ e.g., "I need help now"         │ │
│ │ [________________]              │ │ (Input field, 16px)
│ └─────────────────────────────────┘ │
│                                     │
│           ┌─────────┐               │
│           │         │               │
│        ┌──┤  🎤    ├──┐             │ (120x120px circle)
│        │  │         │  │             │ Status: REST (light gray border)
│        │  └─────────┘  │             │ Status: RECORDING (orange border + red dot)
│        │               │             │ Status: COMPLETED (green checkmark)
│        │   TAP TO      │             │
│        │   START       │             │
│        └───────────────┘             │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ ✓ Phrase recorded successfully  │ │ (Green bg, only visible after recording)
│ │   [Checkmark Icon]              │ │
│ └─────────────────────────────────┘ │
│                                     │
│  [  BACK  ]        [  NEXT  ]       │
│                                     │
└─────────────────────────────────────┘

Recording button states:
- Rest: Light gray circle, blue border (2px), centered icon
- Recording: Light orange circle (warning opacity), orange border, red dot pulsing
- Complete: Green checkmark overlay
```

**TODO:**
- [ ] Design pulsing red dot animation (recording indicator)
- [ ] Design recording success checkmark animation (fade in + scale up)
- [ ] Audio waveform visualization during recording (optional nice-to-have)
- [ ] Test: Can speak into phone without hitting button twice

---

### Page 4: Inner Circle Contacts
**Status:** Functional, needs contact management refinement

```
Layout:
┌─────────────────────────────────────┐
│ INNER CIRCLE                         │ (48px)
│ Who'll be notified immediately?     │ (Subtitle)
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ [Avatar]  Mom                  ✓ │ │ (Contact card, selected)
│ │ mom@phone.com                    │ │ (Card: blue bg, checkmark)
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ [Avatar]  Sister                 │ │ (Contact card, unselected)
│ │ sister@phone.com                │ │ (Card: light gray bg, no checkmark)
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ [Avatar]  Best Friend            │ │
│ │ bestfriend@phone.com            │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ [Avatar]  Trusted Colleague      │ │
│ │ colleague@phone.com             │ │
│ └─────────────────────────────────┘ │
│                                     │
│  [  BACK  ]        [  NEXT  ]       │
│                                     │
└─────────────────────────────────────┘

Contact card:
- Padding: 12px
- Border-radius: 12px
- Selected: Primary blue background, white text, checkmark icon (right)
- Unselected: Light gray background, dark text, no icon
- Tap feedback: Slight scale-down (100% → 98%), press state color change
```

**TODO:**
- [ ] Design avatar generation algorithm (initials in colored circles)
- [ ] Contact import UI (import from device contacts)
- [ ] "Add more contacts" button design
- [ ] Tier indicator (visual diff between Tier 1 & Tier 2)

---

### Page 5: Public Alert Network (Twitter OAuth + Post Template)
**Status:** ENHANCED - Full 3-step design complete

```
Layout:
┌─────────────────────────────────────┐
│ PUBLIC ALERT NETWORK                 │ (48px)
│ Set up auto-posting with Gemma 4    │ (Subtitle)
│                                     │
│ ═══ STEP 1: Review Gemma Sample ═══  │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 🌐 Gemma 4 (AI Generated)       │ │ (Blue card bg)
│ │    2 mins ago                    │ │
│ │                                  │ │
│ │ 🚨 EMERGENCY ALERT 🚨            │ │ (Monospace font)
│ │ I need immediate help at         │ │ (Sample post preview)
│ │ 42nd & Broadway, NYC             │ │
│ │ Threat Level: HIGH               │ │
│ │ Panic Level: 9/10                │ │
│ │ Police contacted ✓               │ │
│ │                                  │ │
│ │ ℹ️ This is auto-generated by AI   │ │
│ │    analysis of your voice        │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ═══ STEP 2: Customize Template ═══   │
│                                     │
│ Default Threat Level               │ (Label)
│ [LOW] [MEDIUM] [HIGH*] [CRITICAL] │ (ChoiceChips - HIGH selected/highlighted)
│                                     │
│ Post Template (use [PLACEHOLDERS])  │
│ ┌─────────────────────────────────┐ │
│ │ 🚨 EMERGENCY                    │ │ (Text input, 6 lines)
│ │ [THREAT_LEVEL] danger at        │ │
│ │ [LOCATION]                      │ │
│ │ Panic: [PANIC_LEVEL]/10         │ │
│ │ Police contacted ✓              │ │
│ │ [CONTACT_INFO]Help needed!      │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ☑ Include location in post         │
│ ☑ Include emergency contact info   │
│   (Phone number will be visible)   │
│                                     │
│ ═══ STEP 3: Preview Example ═══      │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 👤 Your Post (when posted)      │ │ (Green card bg)
│ │    During emergency              │ │
│ │                                  │ │
│ │ 🚨 EMERGENCY                    │ │ (Live preview - updates as user edits)
│ │ HIGH danger at Downtown, City   │ │
│ │ Panic: 8/10                     │ │
│ │ Police contacted ✓              │ │
│ │ +1 (555) 123-4567 Emergency     │ │
│ │                                  │ │
│ │ ✓ This preview updates as you   │ │
│ │   customize your template       │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ╔═══════════════════════════════════╗ │
│ ║ [Twitter logo] CONNECT TWITTER    ║ │ (OAuth button, blue)
│ ╚═══════════════════════════════════╝ │
│                                     │
│ OR                                  │
│                                     │
│ ╔═══════════════════════════════════╗ │ (After OAuth success)
│ ║ ✓ Twitter Connected               ║ │ (Green bg)
│ ║ [Disconnect]                      ║ │
│ ╚═══════════════════════════════════╝ │
│                                     │
│ ☑ I approve this template for       │
│   auto-posting                      │
│   Gemma 4 will generate posts using │
│   this template during emergencies  │
│                                     │
│ 🔐 Your Privacy                     │ (Small text box)
│ Twitter OAuth uses secure auth...   │
│                                     │
│  [  BACK  ]        [  NEXT  ]       │
│                                     │
└─────────────────────────────────────┘

Color scheme:
- Gemma sample: Light blue (#3B82F6 @ 0.05 opacity) background, blue border
- Live preview: Light green (#10B981 @ 0.05 opacity) background, green border
- Threat level chips: White text when selected (HIGH highlighted in blue)
- Template editor: Border, no background
```

**TODO:**
- [ ] Real Twitter OAuth integration UI (OAuth provider button standards)
- [ ] Placeholder text rendering in preview box
- [ ] Live update animation when user changes template
- [ ] Copy-to-clipboard button for post template
- [ ] Responsive font sizing for preview text on small screens

---

### Page 6: Confirmation Sounds
**Status:** ENHANCED - Audio preview + haptic feedback visible

```
Layout:
┌─────────────────────────────────────┐
│ CONFIRMATION SOUNDS                  │ (48px)
│ Hear alerts when events happen      │ (Subtitle)
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ [🔊] Serene Chime               │ │ (Sound option card)
│ │      Calm, melodic alert        │ │
│ │      (best for focus)           │ │
│ │                          [▶]    │ │ (Selected: blue bg, play button)
│ │  ▁ ▂ ▃ ▅ ▆ █ ▇ ▆ ▄ ▃ ▁      │ │ (EQ bars - animating when playing)
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ [🔊] Digital Bell               │ │ (Unselected: light gray bg)
│ │      Sharp, modern tone         │ │
│ │      (high clarity)             │ │
│ │                          [▶]    │ │ (Play button)
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ [🔊] Subtle Pulsing             │ │
│ │      Soft, rhythmic pattern     │ │
│ │      (discreet)                 │ │
│ │                          [▶]    │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ [📳] Haptic Feedback            │ │ (Separate section, light gray card)
│ │      Vibration along with       │ │
│ │      sounds              [Toggle]⊙ │ (Toggle ON by default)
│ └─────────────────────────────────┘ │
│                                     │
│ 🔊 Audio files play via             │ (Implementation note, small text)
│    ConfirmationSoundSystem...       │
│                                     │
│  [  BACK  ]        [  NEXT  ]       │
│                                     │
└─────────────────────────────────────┘

Sound card states:
- Selected: Light blue bg, bold title, blue speaker icon in box
- Unselected: Light gray bg, normal text, gray speaker icon
- Playing: EQ bars animate (bars grow/shrink in sequence)
- Icon bar chart: 10 bars, heights 8-14px, 3px wide, 3px gap

Haptic card:
- Same light gray as unselected sound cards
- Toggle switch: Primary blue when ON
```

**TODO:**
- [ ] Design EQ bar animation (lottie file or CSS keyframes)
- [ ] Play/pause icon transition (smooth rotation/swap)
- [ ] Haptic feedback icon (vibration ripple effect?)
- [ ] Sound description text sizing (ensure readable on mobile)

---

### Page 7: System Test
**Status:** Done, could use celebration animation

```
Layout - BEFORE Test:
┌─────────────────────────────────────┐
│                                     │
│        [⚡ 60px icon]               │ (Lightning bolt, primary blue)
│                                     │
│      Run a test to verify           │ (18px body text, centered)
│      everything works               │
│                                     │
│                                     │
│    [  START TEST DRILL  ]           │ (Large CTA button, primary blue)
│                                     │
│                                     │
└─────────────────────────────────────┘

Layout - AFTER Test Complete:
┌─────────────────────────────────────┐
│                                     │
│       [✓ 60px icon]                 │ (Checkmark in circle, green)
│       (with celebratory animation?)  │
│                                     │
│    Guardian is ready                │ (Green text, 18px)
│                                     │
│                                     │
│  All systems tested and verified.   │ (Gray subtitle text)
│                                     │
│                                     │
│         [  COMPLETE  ]              │ (Button text changes)
│                                     │
│                                     │
└─────────────────────────────────────┘

Animations needed:
- Green checkmark circle fade-in + scale (200ms, Curves.easeOut)
- Success state shows automatically after test button tap
```

**TODO:**
- [ ] Design checkmark circle (green fill, white checkmark)
- [ ] Celebration animation (confetti, pulse, bounce - optional, choose one)
- [ ] Sound effect on success (short ding/chime)
- [ ] Transition to home screen on button tap (navigation handled by dev)

---

## 🎯 Priority 2: EMERGENCY ACTIVE SCREEN (Real-time Display)

**Location:** lib/screens/emergency_active_screen.dart  
**Status:** Three widgets implemented, needs refinement

### Widget 1: Emotion Gauge (WOW FACTOR #1)
**Track:** A (Dev 1)

```
┌─────────────────────────────────────────────┐
│ ♥ Emotion Level                       45%   │ (Title + percentage)
│                                             │
│ ███░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  │ (Linear progress bar)
│ (Green: <30%, Blue: 30-70%, Orange: >70%) │
│                                             │
│ ✅ Monitoring stress levels                 │ (Normal state)
│ ⚠️ High stress detected                    │ (Elevated)
│ 🚨 PANIC DETECTED                          │ (>70%: auto-police call)
│                                             │
└─────────────────────────────────────────────┘

Status text color coding:
- ✅ Green: Calm
- ⚠️ Orange: Elevated stress
- 🚨 Red/Orange: Panic mode (auto-escalate)

Border thickness: 2px (increases urgency as level rises)
Colors:
- <30%: Green (#10B981)
- 30-70%: Blue (#2563EB)
- >70%: Orange (#F97316)
```

**TODO:**
- [ ] Design smooth color transitions as percentage changes
- [ ] Test responsive font sizing on iPhone SE (small screen)
- [ ] Ensure progress bar is accessible (include aria labels)

---

### Widget 2: Escalation Timer (WOW FACTOR #2)
**Track:** B (Dev 2)

```
┌─────────────────────────────────────────────┐
│ 👥 Escalation Status                         │ (Header icon + title)
│                                             │
│ ┌──────────────────────────────────────┐   │
│ │ ✓ TIER 1 - ACTIVE                   │   │ (When T1 is active, blue bg)
│ │ 3 contacts notified                 │   │ (Subtext: who's been called)
│ └──────────────────────────────────────┘   │
│                                             │
│ ┌──────────────────────────────────────┐   │ (Progress bar + countdown)
│ │ ███████░░░░░░░░░░░░░░░░░░  18s      │   │
│ │ (Orange color for warning)           │   │
│ └──────────────────────────────────────┘   │
│                                             │
│ ┌──────────────────────────────────────┐   │
│ │ ◯ TIER 2 - STANDBY                  │   │ (When T2 is standby, gray)
│ │ 5-10 extended contacts              │   │ (Subtext: potential contacts)
│ └──────────────────────────────────────┘   │
│                                             │
└─────────────────────────────────────────────┘

Tier row styling:
- Active: Blue background (opacity 0.1), blue border, checkmark icon
- Standby: Gray background (opacity 0.05), gray border, empty radio icon
- Completed: Green background, success icon

Countdown bar:
- Orange fill color (warning theme)
- Label on right: "18s" in bold, orange text
- Animation: Smooth width decrease as seconds tick down
```

**TODO:**
- [ ] Design countdown timer animation (smooth linear decrease)
- [ ] Design tier completion transition (from ACTIVE to COMPLETED)
- [ ] Animate TIER 2 activation (scale-up or fade effect)

---

### Widget 3: Social Post Status (WOW FACTOR #3)
**Track:** C (Dev 3)

```
┌─────────────────────────────────────────────┐
│ ✓ Emergency Alert Posted                    │ (Header + green icon)
│                                             │
│ ┌──────────────────────────────────────┐   │ (Post preview card)
│ │ 🚨 EMERGENCY ALERT                  │   │ (Sample post content)
│ │                                      │   │
│ │ Posted to Twitter • Emergency       │   │
│ │ services notified • Help needed     │   │
│ └──────────────────────────────────────┘   │
│                                             │
│ 🕐 Posted 14:32    [View Post] →           │ (Timestamp + action link)
│                                             │
└─────────────────────────────────────────────┘

Container styling:
- Background: Green (#10B981) @ 0.1 opacity
- Border: 2px solid green (#10B981)
- Border-radius: 16px

Post preview:
- Background: White @ 0.5 opacity
- Padding: 12px
- Monospace font for post content
- All text left-aligned

Icons:
- Success checkmark (green, 24px)
- Clock icon (secondary gray, 16px)
- Link arrow on "View Post" (primary blue)
```

**TODO:**
- [ ] Design "View Post" link interaction (ripple effect, underline on hover)
- [ ] Design timestamp formatting (12/24 hour preference)
- [ ] Loading state (before post is sent - orange spinner)
- [ ] Error state (red X, "Post failed - retry" link)

---

## 🎯 Priority 3: HOME SCREEN & NAVIGATION

**Status:** Not yet designed - highly essential for MVP

```
Bottom Tab Navigation:
┌─────────────────────────────────────────────┐
│                                             │
│            [HOME CONTENT]                   │
│                                             │
│                                             │
│                                             │
├─────────────────────────────────────────────┤
│ [⊙] Home │ [⚙] Settings │ [?] Help         │ (3-tab system)
│                                             │
└─────────────────────────────────────────────┘

Home Tab Design (Priority):
┌─────────────────────────────────────────────┐
│ Guardian - Safety Dashboard                 │ (Header)
│                                             │
│ ┌─────────────────────────────────────┐    │
│ │  STATUS: READY ✓                    │    │ (Status card)
│ │  All systems online & monitoring    │    │
│ └─────────────────────────────────────┘    │
│                                             │
│           ┌──────────────┐                  │
│          ╱  S   O   S   ╲                  │ (Large SOS button)
│        │     ACTIVATE     │                │ 120px diameter minimum
│          ╲             ╱                  │ Pulsing animation
│           └──────────────┘                  │ Primary blue + shadow
│                                             │
│ Quick Contacts:                            │ (Recent inner circle)
│ ┌──────────────┐ ┌──────────────┐         │
│ │ Mom  📞 Call │ │ Sister 📞... │         │
│ └──────────────┘ └──────────────┘         │
│                                             │
│ Recent Incidents:                          │ (If any)
│ None recorded yet                          │ (Empty state)
│                                             │
└─────────────────────────────────────────────┘

SOS Button Details:
- Shape: Circle (120x120px minimum)
- Color: Primary blue with shadow depth 8
- Animation: Pulse effect (scale 1.0 → 1.1 → 1.0) every 1.5s
- Text: "S O S" in large white font (36px)
  or "ACTIVATE" below "GUARDIAN"
- On press: Haptic feedback (strong vibration) + scale animation feedback (98%)
```

**TODO:** Full design for home screen (high priority)
- [ ] Design SOS button pulsing animation
- [ ] Design status card (different states: Ready, Recording, Police Notified)
- [ ] Design empty state illustrations
- [ ] Design recent contacts shortcut layout

---

## 📋 General Accessibility Checklist

For ALL screens:

- [ ] Text contrast ratio ≥ 4.5:1 (use WebAIM checker)
- [ ] All icons have semantic labels (aria-label / Semantics in Flutter)
- [ ] Touch targets ≥ 44x44px (all buttons tested)
- [ ] Font size ≥ 16px for body text
- [ ] Color not the only indicator (use icons + text + shape)
- [ ] No animations with flash rate ≥ 3 Hz (photosensitive safety)
- [ ] Keyboard navigation works (Tab through all interactive elements)
- [ ] Screen reader compatibility (tested on iOS/Android screen readers)

---

## 🎨 Figma File Structure (Recommended)

```
Guardian Design System
├── Design Tokens
│   ├── Colors
│   ├── Typography
│   ├── Spacing
│   └── Shadows
├── Components
│   ├── Buttons (Primary, Secondary, Danger)
│   ├── Cards
│   ├── Inputs
│   ├── Toggles & Switches
│   ├── Icons
│   └── Progress Bars
├── Screens
│   ├── Onboarding (Pages 1-7)
│   ├── Emergency Active
│   ├── Home
│   ├── Settings
│   └── Help
└── Animations & Interactions
    ├── Button states
    ├── Loading spinners
    └── Transitions
```

---

## 📦 Handoff Files Needed

Before handing off to developers:

1. **Figma design file** (shared read-only link)
2. **Exported PNGs** (2x resolution for mobile)
3. **SVG icon pack** (for all custom icons)
4. **Lottie animation files** (for complex animations)
5. **Color palette JSON** (hex values + opacity values)
6. **Typography specs document** (font names + sizes + weights)
7. **Animation specs** (duration + easing curve for each animation)
8. **Accessibility audit report** (contrast checks, screen reader tested)

---

**Ready to start designing? Pick one screen and build from there! 🚀**


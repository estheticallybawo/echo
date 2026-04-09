# Echo App - Designer's Brief & Style Guide

**Project:** Echo - AI-Powered Emergency Response System  
**Version:** May 17 MVP  
**Status:** Design Phase (Foundation Complete, Components Need Polish)  
**Design Lead:** [Your Name]  
**Last Updated:** April 8, 2026

---

## 1. Design Philosophy & Mission

Echo is built around **Hiny's Story** - a young woman (Iniubong Umoren) whose life could have been saved with real-time emergency alerts. Every design decision must reflect:

- **Trust**: Users give Echo their location, voice, emergency contacts - design must feel secure
- **Speed**: In emergencies, every millisecond matters - UI must guide users intuitively
- **Empathy**: This app is used in life-or-death moments - design should feel supportive, not clinical
- **Accessibility**: Not all emergency victims are able-bodied or sighted - alt text, high contrast, voice-first

---

## 2. Current Design System (In Production)

### Color Palette
```dart
// Echo Brand Colors (lib/theme.dart)

EchoColors.primary        = Color(0xFF2563EB)  // Primary Blue (Trust, Action)
EchoColors.primary90      = Color(0xFF1E40AF)  // Darker Blue (Pressed)
EchoColors.primary80      = Color(0xFF3B82F6)  // Light Blue (Hover)

EchoColors.warning        = Color(0xFFF97316)  // Orange (Urgency, Alerts)
EchoColors.success        = Color(0xFF10B981)  // Green (Confirmation, Safe)
EchoColors.textPrimary    = Color(0xFF1F2937)  // Dark Gray (Readable)
EchoColors.textSecondary  = Color(0xFF6B7280)  // Medium Gray (Sub-text)
EchoColors.textTertiary   = Color(0xFFD1D5DB)  // Light Gray (Disabled)

EchoColors.surfacePrimary    = Color(0xFFFFFFFF)  // White (Main BG)
EchoColors.surfaceSecondary  = Color(0xFFF3F4F6)  // Light Gray (Card BG)
EchoColors.surfaceTertiary   = Color(0xFFE5E7EB)  // Lighter Gray (Borders)
```

**Color Usage Rules:**
- ✅ Primary blue for actionable buttons, navigation, success states
- ✅ Orange/warning only for HIGH-priority alerts or time-sensitive info
- ✅ Green for user confirmations ("Phone contact reached", "Police en route")
- ✅ NEVER use yellow/green together (accessibility issue for colorblind users)
- ✅ High contrast: 4.5:1 minimum for all text (WCAG AA compliant)

### Typography
```dart
// Theme Stack (Google Fonts integration)

displayMedium    = 48px, w600, primary-color    // Page titles ("Public Alert Network")
titleLarge       = 32px, w600, text-primary     // Section headers
titleMedium      = 20px, w600, text-primary     // Small headers
bodyLarge        = 18px, w400, text-primary     // Body text + CTAs
bodyMedium       = 16px, w400, text-primary     // Standard paragraphs
bodySmall        = 14px, w400, text-secondary   // Supporting text
labelLarge       = 14px, w600, text-primary     // Labels, small buttons
labelSmall       = 12px, w500, text-tertiary    // Captions, timestamps
```

**Font Pairs:**
- Headers: Google Fonts "Poppins" (friendly, modern)
- Body: Google Fonts "Inter" (high readability, accessibility)
- Monospace: "Courier" for code samples, post previews

### Spacing System
```
4px   = xs (micro spacing)
8px   = sm (small gaps)
12px  = md (default padding)
16px  = lg (card padding)
24px  = xl (section spacing)
32px  = 2xl (major section breaks)
48px  = 3xl (page spacing)
```

**Rule:** Always use multiples of 4px for consistency

### Component Library (Existing)

#### Buttons
```dart
// Primary CTA
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: EchoColors.primary,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  ),
  child: Text('NEXT'),
)

// Outline/Secondary
OutlinedButton(
  style: OutlinedButton.styleFrom(
    side: BorderSide(color: EchoColors.primary),
  ),
  child: Text('BACK'),
)

// Danger/Warning (Orange background)
ElevatedButton.styleFrom(
  backgroundColor: EchoColors.warning.withOpacity(0.15),
  foregroundColor: EchoColors.warning,
)
```

#### Cards
```dart
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: EchoColors.surfaceSecondary,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: EchoColors.textPrimary.withOpacity(0.08),
      width: 1,
    ),
  ),
  child: // content
)
```

#### Input Fields
```dart
TextField(
  decoration: InputDecoration(
    hintText: 'Enter...',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  ),
)
```

#### Checkboxes / Toggles
```dart
Checkbox(
  value: true,
  activeColor: EchoColors.primary,
)

Switch(
  value: true,
  activeColor: EchoColors.primary,
)
```

#### Icons
- Material Icons (3.0 weight, 20-24px standard size)
- Usage: Status indicators, navigation, actions
- Never use emojis except in social media post examples

---

## 3. Screens Requiring Design (Priority Order)

### COMPLETED ✅
- [x] Page 1: Hiny's Story (Onboarding intro)
- [x] Page 2: Permissions (Toggle list)
- [x] Page 3: Voice Phrase Recording (Mic input)
- [x] Page 4: Inner Circle (Contact selector)
- [x] Page 5: Public Alert Network (Twitter OAuth + Post Template)
- [x] Page 6: Confirmation Sounds (Audio selector)
- [x] Page 7: System Test (Drill verification)
- [x] Emergency Active Screen (3 widgets: emotion gauge, escalation timer, social post status)

### IN PROGRESS / NEEDS REFINEMENT 🔄

#### Landing Page / Auth Flows
```
HOME_SCREEN_ICON_TAB_LAYOUT
├─ Home Tab: "SOS Activated - Ready" status card
├─ Settings Tab: User preferences, contact management
├─ Help Tab: Emergency guide, system status
└─ Account Tab: Profile, login info, subscription
```
**Design Notes:**
- Large, glowing SOS button (primary blue, 120px diameter)
- Real-time status indicator (dot + text): "Ready", "Recording", "Police Notified"
- Quick-access contacts preview (3 most recent)
- **TODO**: Mockup these tabs with proper spacing

#### Contact Management Screen
```
CONTACTS_SCREEN
├─ Tier 1 (Inner Circle) - Red/Warning accent
│  └─ [Name, Phone, Status: "Called at 3:45pm"]
├─ Tier 2 (Extended Network) - Blue accent
│  └─ [Name, Phone, Status: "Not yet contacted"]
└─ Add Contact Button
```
**Design Notes:**
- Two-tier visual hierarchy (different badge colors)
- Swipe-to-edit, swipe-to-delete (iOS-style)
- Search by name/phone at top
- **TODO**: Design the contact card layout with encryption badge

#### Settings / Preferences Screen
```
SETTINGS_SCREEN
├─ Voice Phrase Management
│  └─ Current phrase (masked), Record new button
├─ Notification Preferences
│  └─ SMS / WhatsApp / Push toggles
├─ Location Sharing
│  └─ High accuracy / Battery saver mode
├─ Theme
│  └─ Light / Dark mode toggle
└─ Privacy & Security
   └─ Encryption status, Backup options
```
**Design Notes:**
- Settings should use SettingsTile pattern (toggle on right)
- Encryption badge: small lock icon + "AES-256 Encrypted" label
- **TODO**: Full mock with all setting sections

#### Incident History Screen (POST-LAUNCH ⏸️)
```
INCIDENT_LOG_SCREEN (Deferred to post-launch)
├─ Timeline view: [Date] - [Type] - [Status]
│  └─ Tap to expand: Full analysis, people notified, duration
├─ Filter by: Date, Status (active/resolved/false-alarm), Type
└─ Export as PDF
```
**Design Notes:**
- Date picker for custom ranges
- Status badges (green = resolved, orange = false-alarm, red = critical)
- **TODO**: This is post-launch, deprioritize for now

---

## 4. UI/UX Patterns to Maintain

### Pattern 1: Progressive Disclosure (Onboarding)
**Where:** Pages 1-7 (OnboardingFlow)  
**Why:** Users are overwhelmed during safety app setup - show only what's needed per step  
**How:** Each page focuses on ONE task with clear navigation

✅ **Good:** Page 5 shows Gemma sample → customize template → Twitter connect → approve
❌ **Bad:** All settings on one screen (overwhelming)

### Pattern 2: Real-time Feedback
**Where:** Emergency Active Screen  
**Why:** During emergency, user anxiety is HIGH - show them progress  
**How:** Animation + status text + color coding

✅ **Examples:**
- Emotion gauge: "🚨 PANIC DETECTED - Auto-contacting police..."
- Escalation timer: Visual countdown + "15s until Tier 2 activation"
- Social post: Green checkmark + "Posted 2 mins ago"

❌ **Bad:** Silent loading states without feedback

### Pattern 3: Accessibility-First
**Where:** Entire app  
**Why:** Emergency situations affect people with disabilities disproportionately  
**How:**
- All buttons + text have min 44px touch target
- Voice-first interface (Gemma voice activation)
- High contrast mode support
- Screen reader labels on all icons

### Pattern 4: Confirmation Before Action
**Where:** Sensitive actions (Cancel emergency, Disconnect Twitter)  
**Why:** Users are stressed - prevent accidental taps  
**How:** AlertDialog with clear confirm/cancel buttons

✅ **Example:** "Cancel Emergency?" → "Are you sure? Recording and alerts will stop."

---

## 5. Design Tokens for Implementation

### Shadows
```dart
// Card shadow (light ambient)
elevation: 2,
shadowColor: Colors.black.withOpacity(0.08),

// Alert shadow (urgent)
elevation: 8,
shadowColor: EchoColors.warning.withOpacity(0.3),
```

### Border Radius
```
8px   = input fields, small elements
12px  = cards, buttons
16px  = large sections
50px  = circles (profile pics, status badges)
```

### Opacity Values
```
0.08  = subtle borders, disabled text
0.1   = light backgrounds
0.15  = medium opacity highlights
0.2   = semi-transparent overlays
0.5   = strong overlays (modals)
```

---

## 6. Responsive Design Breakpoints

```
Mobile (default)      : < 600px          (Phone screens)
```

---

## 7. Animation & Microinteractions

### Page Transitions
```dart
// Between onboarding pages
duration: 300ms, curve: Curves.easeInOut
// Smooth slide effect, not jarring
```

### Button States
```
Rest:     Primary blue, shadow elevation 2
Hover:    Slightly darker blue (primary90)
Pressed:  Darkest blue (primary80), shadow elevation 1
Disabled: Gray text, no shadow
Loading:  Spinner overlay on button
```

### Pulsing Animation (SOS Button)
```dart
// Breathing effect to draw attention
AnimationController(duration: 1.5s)
// Scale: 1.0 → 1.1 → 1.0 (repeat)
// Opacity: 1.0 → 0.7 → 1.0 (repeat)
```

---

## 8. Accessibility Checklist

Before handing off to dev, verify:

- [ ] All text has min 16px font size (readable on phone)
- [ ] Color contrast ratio 4.5:1 for body text (use WebAIM contrast checker)
- [ ] All buttons 44x44px minimum (accessible tap target)
- [ ] All images have descriptive alt text
- [ ] Keyboard navigation works throughout app
- [ ] Screen reader friendly (semantic HTML/Dart widgets)
- [ ] No audio-only warnings (include visual indicators)
- [ ] No flashing/strobing (safe for photosensitive users)
- [ ] Dark mode support (system preference detection)

**Tools:**
- Contrast Checker: https://webaim.org/resources/contrastchecker/
- Accessibility Audit: ChromeDevTools → Lighthouse → Accessibility

---

## 9. Design Assets to Create

### Icons
```
✅ COMPLETED 


⏳ TODO:

```

### Illustrations
```
⏳ TODO:
- Hiny's portrait (Page 1 - consider illustrated style vs photo)
- Emergency scenario illustrations (3-4 for help screens)
- Success state illustration (confetti, checkmark animation)
- Empty state illustrations (no contacts, no incidents)
```

### Screens to Mock (Figma/Adobe XD)
```
Priority 1 (MVP):
- Home Screen (SOS + status)
- Emergency Active Screen (live emotion meter, escalation, social post)
- Onboarding Pages 1-7 (refine existing designs)

Priority 2 (Post-Launch):
- Contact Management
- Settings / Preferences
- Incident History
- Help / Emergency Guide
```

---

## 10. Brand Voice & Tone

### When to Use Each Tone

**Calm & Reassuring** (most of the time)
*"Echo is here. You're safe."*
- Used in: Confirmation screens, help text, success states
- Avoid panic language

**Urgent & Direct** (emergency only)
*"Police contacted. Stay calm."*
- Used in: Emergency active screen, high-threat alerts
- Short sentences, action-oriented

**Empathetic & Supportive** (onboarding)
*"We're here to help you stay safe."*
- Used in: Hiny's story, permissions requests
- Acknowledge user anxiety

### Copywriting Rules
- ✅ Active voice: "Police notified" not "Notification sent to police"
- ✅ Action verbs: "Connect Twitter", "Record phrase", "Approve template"
- ✅ No jargon: "Emergency contacts" not "Alert recipients"
- ✅ Short & scannable: Use bullet points in help text
- ❌ Never trivialize: No jokes in emergency contexts
- ❌ Avoid passive-aggressive: "You forgot to add a contact" → "Add a contact to get started"

---

## 11. Quality Assurance Checklist for Design

**Before Dev Handoff:**

- [ ] All screens follow color palette (no random colors)
- [ ] Typography consistent (no custom font sizes)
- [ ] Spacing follows 4px grid (use Figma plugins to verify)
- [ ] All buttons are clickable (44px+ tap targets)
- [ ] Hover/active states designed for all interactive elements
- [ ] Dark mode alternatives created (if applicable)
- [ ] Offline state designed (graceful degradation)
- [ ] Error states designed (empty results, API failures)
- [ ] Loading states designed (spinners, skeleton screens)
- [ ] Success states designed (confirmations, celebrations)

---

## 12. Design Tools & Exports

**Design Software:** Figma (preferred) or Adobe XD

**Export Formats:**
- PNG @ 2x resolution (retina screens)
- SVG for icons (scalable)
- Lottie files for animations

**Handoff to Devs:**
- Generate Figma specs (distances, colors, fonts auto-extracted)
- Document all animation durations & curves
- List all icon names & sizes
- Create component library in Figma (buttons, cards, inputs)

---

## 13. Design Debt / Known Issues

Current problems to address:

1. **Emotion Gauge Widget**: Text is small on mobile (< 5.5" screen) - needs responsive sizing
2. **Social Post Preview**: Monospace font doesn't wrap well on narrow screens - test on iPhone SE
3. **Onboarding Pages**: Last page (System Test) could use celebratory animation
4. **Dark Mode**: Not fully implemented - system preference detection needed
5. **Offline State**: No design for when police API is down or no internet

---

## 14. Future Design Roadmap (Post-MVP)

**Q2 2026:**
- Incident history screen with timeline
- Advanced contact management (groups, tiers, relationship labels)
- Customizable emergency guide (injury first aid, safety tips)

**Q3 2026:**
- Echo API landing page + integration guide
- Partner dashboard (for ride-sharing, dating apps)
- Emergency response analytics (heat map of reported incidents)

**Q4 2026:**
- AR integration (mark safe zones, danger zones on map)
- Community feature (public safety tips, incident reports)
- Voice customization (choose accent for verbal confirmations)

---

## 15. Designer Resources & References

### Inspiration
- **Twilio SMS Dashboard:** Clean, functional design for critical alerts
- **Apple Health App:** Emotional state & vitals tracking (emotion gauge reference)
- **Life360 Family Locator:** Contact-based UI patterns
- **Lime Scooter App:** Emergency button design (large, prominent)

### Color Tools
- Coolors.co (palette generator)
- WebAIM Contrast Checker (accessibility)
- Color Blindness Simulator (verify colorblind-safe palette)

### Accessibility
- WCAG 2.1 AA standards (required for emergency app)
- Deque University (free courses on accessible design)
- WebAIM (color contrast, typography guides)

### Fonts
- Google Fonts: Poppins (headers), Inter (body)
- Download from: fonts.google.com

---

## 16. Final Notes for Design Team

### The "Why" Behind Every Decision

**Hiny died because:**
1. No one knew she was in danger (no SOS signal)
2. She couldn't reach her phone (app needs voice activation)
3. Responders didn't know her location (GPS critical)
4. Nobody called police automatically (Gemma AI must act autonomously)

**Our design must:**
- Make it impossible to miss an emergency (SOS button dominates home screen)
- Work with one hand (large touch targets, voice-first)
- Send location instantly (no extra taps to confirm)
- Feel trustworthy (professional, not militaristic)

### Design Quality Standard

This isn't a fintech app or social network. **Lives depend on your design decisions.** Every pixel, every animation, every word matters.

- Is this button obviously clickable? (Do doctors, seniors, kids understand it?)
- Can this screen be understood in 2 seconds? (In panic, users can't read small text)
- Does this design add to safety or distract from it? (No unnecessary flourishes)

---

## Questions for Design Team

1. Should the app have a dark mode? (Pro: battery saving; Con: less visibility of critical alerts)
2. How animated should the SOS button be? (More animation = more visible, but might distract)
3. Should we show real incident data in mock-ups? (Privacy consideration)
4. What should the "Echo" logo look like? (Shield? Location pin? Heart rate monitor?)

---

**Ready to design? Start with Page 1 through 7 (OnboardingFlow) - these set the foundation for the entire app.**

Good luck! 🚀


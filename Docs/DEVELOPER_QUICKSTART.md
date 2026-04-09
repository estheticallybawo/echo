# Echo App - Developer Quick Start Guide

## Getting Started in 5 Steps

### Step 1: Clone & Setup (5 minutes)

```bash
# Clone the repository
git clone https://github.com/estheticallybawo/the-gemma-4-good-project.git

cd hi_gemma

# Install dependencies
flutter pub get

# Check Flutter setup
flutter doctor

# Open in VS Code
code .
```

### Step 2: Verify It Runs (2 minutes)

```bash
# Run on web (fastest for development)
flutter run -d chrome

# Or on Android emulator
flutter emulator --launch <emulator_name>
flutter run -d emulator-5554
```

You should see the Echo app with:
- ✓ Light theme (soft blue-white background)
- ✓ Teal primary color (#0891B2)
- ✓ Poppins typography
- ✓ Onboarding flow or home screen with glowing orb

### Step 3: Create Your Feature Branch

```bash
# First, pull latest main
git checkout main
git pull origin main

# Create your feature branch (use one from FEATURES.md)
git checkout -b feature/voice-activation

# Or if it's a fix:
git checkout -b fix/color-scheme-issue

# Or if it's documentation:
git checkout -b docs/api-documentation

# Verify you're on the right branch
git branch  # Should show * feature/voice-activation
```

### Step 4: Familiarize Yourself with Codebase

```
lib/
├── main.dart                          # App entry point, routes
├── theme.dart                         # Echo design system
├── screens/                           # UI screens (already built)
│   ├── home_screen.dart
│   ├── emergency_active_screen.dart
│   ├── onboarding_flow.dart
│   ├── contacts_screen.dart
│   ├── ai_intel_screen.dart
│   ├── fake_call_screen.dart
│   ├── incident_log_screen.dart
│   └── settings_screen.dart
├── services/                          # Business logic (you'll add most here)
│   ├── confirmation_sound_system.dart (ALREADY EXISTS)
│   ├── voice_recognition_service.dart (TODO: create)
│   ├── location_tracker_service.dart (TODO: create)
│   ├── gemma_analysis_service.dart (TODO: create)
│   ├── notification_service.dart (TODO: create)
│   ├── audio_recorder_service.dart (TODO: create)
│   └── encryption_service.dart (TODO: create)
├── data/
│   ├── repositories/                  # Data access layer
│   │   ├── incident_repository.dart
│   │   └── contact_repository.dart
│   └── models/                        # Data classes
│       ├── incident.dart
│       ├── contact.dart
│       ├── emergency_session.dart
│       └── notification_log.dart
├── state/                             # State management
│   └── emergency_state_manager.dart
└── utils/                             # Helpers
    ├── location_utils.dart
    └── constants.dart
```

### Step 5: Read the Documentation (15 minutes)

In this order:
1. **FEATURES.md** - What you're building (your specific feature)
2. **ARCHITECTURE.md** - System design and how services integrate
3. **TASK_TRACKING.md** - Your team assignment and timeline

---

## Development Workflow

### Before You Start Coding

1. **Read your feature spec** from FEATURES.md
   - Understand all "Implementation Requirements"
   - Note the "Tech Stack" packages needed
   - See the "Deliverables" checklist

2. **Check dependencies** in pubspec.yaml
   ```bash
   # If you need new packages (e.g., geolocator for location):
   flutter pub add geolocator
   flutter pub get
   ```

3. **Review similar code**
   - Study `ConfirmationSoundSystem` (already exists) for patterns
   - Follow the same structure for new services
   - Use provider + ChangeNotifier for state

### While You Code

#### Create Service Classes

```dart
// lib/services/voice_recognition_service.dart

class VoiceRecognitionService {
  // 1. Define initialization
  Future<void> initialize() async {
    // Setup code here
  }
  
  // 2. Define main methods
  Stream<VoiceRecognitionEvent> startListening() {
    // Main functionality
  }
  
  // 3. Define cleanup
  Future<void> dispose() async {
    // Cleanup resources
  }
}
```

#### Create Data Models

```dart
// lib/data/models/voice_recognition_event.dart

class VoiceRecognitionEvent {
  final String phrase;
  final double confidence;
  final DateTime timestamp;
  
  VoiceRecognitionEvent({
    required this.phrase,
    required this.confidence,
    required this.timestamp,
  });
}
```

#### Create Repository Pattern

```dart
// lib/data/repositories/incident_repository.dart

abstract class IncidentRepository {
  Stream<List<Incident>> watchIncidents(IncidentFilter filter);
  Future<void> createIncident(EmergencySession session);
  Future<Incident?> getIncident(String id);
  Future<void> deleteIncident(String id);
}

class HiveIncidentRepository implements IncidentRepository {
  // Implementation using Hive
}
```

#### Add Unit Tests

```dart
// test/services/voice_recognition_service_test.dart

void main() {
  group('VoiceRecognitionService', () {
    late VoiceRecognitionService service;
    
    setUp(() {
      service = VoiceRecognitionService();
    });
    
    test('initializes successfully', () async {
      await service.initialize();
      // Assert initialization
    });
    
    test('detects voice phrase with high confidence', () async {
      final events = <VoiceRecognitionEvent>[];
      service.startListening().listen(events.add);
      
      // Simulate voice input
      // Assert
    });
  });
}
```

### Before Committing

```bash
# 1. Format your code
dart format lib/

# 2. Analyze for issues
dart analyze

# Or with Flutter:
flutter analyze

# 3. Run your tests
flutter test

# 4. Verify the app still runs
flutter run -d chrome
```

### Making Commits

```bash
# Add files
git add lib/services/voice_recognition_service.dart
git add test/services/voice_recognition_service_test.dart

# Commit with good message
git commit -m "[FEAT] Add voice recognition service with E2B integration

- Implement VoiceRecognitionService class
- Add phrase matching with confidence threshold
- Support background listening with microphone
- Include 85% confidence filtering for false positives

Closes #42"

# Multiple commits for bigger features is OK:
git commit -m "[TEST] Add unit tests for voice recognition"
git commit -m "[REFACTOR] Extract confidence calculation to helper method"
```

### Push & Create Pull Request

```bash
# Push to GitHub
git push origin feature/voice-activation

# GitHub will show: "Create Pull Request" - click it
# Or use GitHub CLI:
gh pr create --title "Add voice recognition service" \
  --body "Closes #42 - Implements E2B Gemma 2B-IT for emergency activation"
```

---

## Code Style & Conventions

### Follow Dart Conventions

```dart
// ✓ Good
class VoiceRecognitionService {
  final StreamController<VoiceEvent> _eventController = StreamController();
  
  Future<void> initialize() async { }
  
  Stream<VoiceEvent> get events => _eventController.stream;
}

// ✗ Avoid
class voiceRecognitionService {  // Class names are PascalCase
  var _event;  // Declare type
  voidInitialize() { }  // Use Future<void>, not void
}
```

### Naming Conventions

```dart
// Classes: PascalCase
class VoiceRecognitionService { }
class EmergencySession { }

// Methods/Variables: lowerCamelCase
void startListening() { }
String userPhoneNumber = "";
bool isEmergencyActive = false;

// Constants: lowerCamelCase (start with _)
const defaultTimeout = Duration(seconds: 30);
const _maxReconnectAttempts = 5;

// Private: prefix with underscore
class _OrbPainter extends CustomPainter { }
Future<void> _initializeEncryption() async { }
```

### File Organization

```dart
// 1. Imports
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';  // Relative imports for local files

// 2. Constants
const defaultTimeout = Duration(seconds: 30);

// 3. Class/Function Definition
class VoiceRecognitionService {
  // 3a. Fields
  final String apiKey;
  
  // 3b. Constructor
  VoiceRecognitionService({required this.apiKey});
  
  // 3c. Methods (public first, then private)
  Future<void> initialize() async { }
  void dispose() { }
  
  // 3d. Private methods
  Future<void> _setupAudioSession() async { }
}
```

### Error Handling

```dart
// ✓ Good - specific exceptions
Future<void> startListening() async {
  try {
    await _audioSession.prepare();
  } on PlatformException catch (e) {
    print('Audio session error: ${e.code}');
    rethrow;  // Re-throw if critical
  } catch (e) {
    print('Unexpected error: $e');
  }
}

// ✗ Avoid - generic exceptions
Future<void> startListening() async {
  try {
    // code
  } catch (e) {
    // Too vague
  }
}
```

---

## Debugging Tips

### Enable Debug Logging

```dart
// In main.dart
void main() {
  // Enable debug printing
  debugPrint('Echo App Starting');
  
  // ... rest of initialization
}

// In your service
void debugLog(String message) {
  debugPrint('[VoiceRecognitionService] $message');
}
```

### Use DevTools

```bash
# Open Flutter DevTools for debugging
flutter pub global activate devtools
devtools

# Then in another terminal:
flutter run -d chrome

# DevTools will open in browser - inspect widgets, logs, etc.
```

### Hot Reload for Instant Feedback

```bash
# While running: flutter run -d chrome
# In terminal, type 'r' and press Enter to hot reload
# (or press 'R' for full restart)

# This is much faster than rebuilding the whole app
```

### Check Logs in Real-Time

```bash
# Watch logs as they happen
flutter logs

# Or filter by tag
flutter logs | grep VoiceRecognition
```

---

## Common Issues & Solutions

### Issue: "Package not found"
```bash
# Solution:
flutter pub get
flutter pub upgrade

# If still failing:
flutter clean
flutter pub get
```

### Issue: "Hot reload not working"
```bash
# Full restart needed for some changes (native code, dependencies)
# Press 'R' in terminal (instead of 'r')
# Or:
flutter run -d chrome
```

### Issue: "Type 'X' is not a subtype of type 'Y'"
```dart
// Usually a type mismatch. Check:
// 1. Variable types match function parameters
// 2. Generic types (List<X>, Stream<Y>) match
// 3. Null safety (?? operators work correctly)
```

### Issue: "Permission denied on Android"
```bash
# Check if permissions are in AndroidManifest.xml
# already handled by permission_handler package
# But verify location/microphone/etc. are declared

# For development, you can grant permissions:
adb shell pm grant com.example.hi_gemma android.permission.ACCESS_FINE_LOCATION
```

---

## Testing Checklist

Before marking your feature done:

- [ ] **Unit Tests**: Run `flutter test` - all pass
- [ ] **Coverage**: >80% code coverage for your service
- [ ] **Integration Test**: Feature works end-to-end
- [ ] **Manual Test**: Tested on actual device/emulator
- [ ] **Edge Cases**: 
  - [ ] Network fails
  - [ ] Permission denied
  - [ ] Device backgrounded
  - [ ] Low battery
  - [ ] No storage space
- [ ] **UI**: Screens render without errors
- [ ] **Accessibility**: Readable text sizes, color contrast OK

---

## Example: Building a Service from Scratch

Let's say you're implementing `feature/location-tracking`. Here's your checklist:

### 1. Create Service File
```bash
# Create the service
mkdir -p lib/services
touch lib/services/location_tracker_service.dart
```

### 2. Implement Service
```dart
// lib/services/location_tracker_service.dart
import 'package:geolocator/geolocator.dart';

class LocationTrackerService {
  Future<void> initialize() async {
    // Request permissions
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw PermissionException('Location permission denied');
    }
  }
  
  Stream<LocationSnapshot> startTracking() {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      ),
    ).map((position) => LocationSnapshot.fromPosition(position));
  }
}
```

### 3. Create Model
```dart
// lib/data/models/location_snapshot.dart
class LocationSnapshot {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  
  LocationSnapshot({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
  });
  
  factory LocationSnapshot.fromPosition(Position position) {
    return LocationSnapshot(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      timestamp: DateTime.now(),
    );
  }
}
```

### 4. Write Tests
```dart
// test/services/location_tracker_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('LocationTrackerService', () {
    late LocationTrackerService service;
    
    setUp(() {
      service = LocationTrackerService();
    });
    
    test('initializes and requests permissions', () async {
      await service.initialize();
      // Assert permissions were requested
    });
    
    test('streams location updates', () async {
      await service.initialize();
      final locations = <LocationSnapshot>[];
      
      service.startTracking().listen(locations.add);
      
      await Future.delayed(Duration(seconds: 1));
      expect(locations.isNotEmpty, true);
    });
  });
}
```

### 5. Integrate with UI
```dart
// In emergency_active_screen.dart (use StreamBuilder)
StreamBuilder<LocationSnapshot>(
  stream: Provider.of<LocationTrackerService>(context).startTracking(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return Text('Location: ${snapshot.data!.latitude}');
    }
    return CircularProgressIndicator();
  },
)
```

### 6. Commit & Push
```bash
git add lib/services/location_tracker_service.dart
git add lib/data/models/location_snapshot.dart
git add test/services/location_tracker_service_test.dart

git commit -m "[FEAT] Add location tracking service with geolocator

- Implement LocationTrackerService with high-accuracy GPS
- Add LocationSnapshot model for location data
- Support streaming location updates every 5-30 seconds
- Include fallback to cell triangulation if GPS unavailable
- Add comprehensive unit tests

Closes #58"

git push origin feature/location-tracking

# Then create PR on GitHub
```

---

## Help & Support

### Getting Unstuck?

1. **Check ARCHITECTURE.md** for system design
2. **Look at existing code** (ConfirmationSoundSystem) for patterns
3. **Search GitHub issues** for similar problems
4. **Ask in team chat/Discord** - someone's probably solved it
5. **Read Flutter docs** for package-specific questions

### Common Documentation

- **Flutter Docs**: https://flutter.dev/docs
- **Dart Docs**: https://dart.dev/guides
- **Provider Package**: https://pub.dev/packages/provider
- **Hive Database**: https://hivedb.dev

### Your Team

| Role | Contact |
|------|---------|
| Voice/Audio Features | Team Member 1 |
| Location/Notifications | Team Member 2 |
| AI/Data Processing | Team Member 3 |
| Native/Security | Team Member 4 |

---

## Success Criteria for Your Feature

Your feature is ready when:

✅ **Code Quality**
- Follows the style guide above
- No analyzer warnings
- >80% test coverage

✅ **Functionality**
- Implements all requirements from FEATURES.md
- Works on Chrome, Android, iOS (if not platform-specific)
- Integrates cleanly with other services

✅ **Testing**
- All unit tests pass
- Integration tests pass
- Manual testing verified

✅ **Documentation**
- Public methods have dartdoc comments
- Complex logic has explanatory comments
- README updated if needed

✅ **Git**
- Commits have clear, descriptive messages
- PR linked to GitHub issue
- Ready for code review

---

## Celebrate Your Win! 🎉

Once your PR is merged:
1. Delete your local branch: `git branch -d feature/voice-activation`
2. Delete remote branch: `git push origin --delete feature/voice-activation`
3. Pull latest main: `git checkout main && git pull origin main`
4. Move on to your next feature!

---

**Good luck! You've got this.** 🚀

If anything's unclear, ask your teammates or refer back to this guide.
The Echo community is counting on you! ❤️

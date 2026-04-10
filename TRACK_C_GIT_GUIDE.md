# Track C: Git Branch Setup & Push Guide

**Branch Name**: `feature/track-c-mvp`

---

## 🔧 Local Setup

### Step 1: Create your Track C branch
```bash
git checkout -b feature/track-c-mvp
```

### Step 2: Verify your changes
```bash
git status
```

**Expected output:**
```
On branch feature/track-c-mvp
Untracked files:
  lib/providers/gemma_provider.dart
  lib/providers/social_media_provider.dart
  lib/services/gemma_threat_assessment_service.dart
  lib/services/social_media_posting_service.dart
  lib/services/twitter_oauth_service.dart
  TRACK_C_SETUP.md

Modified files:
  lib/main.dart
  pubspec.yaml
```

### Step 3: Add files to staging
```bash
git add lib/providers/
git add lib/services/gemma_threat_assessment_service.dart
git add lib/services/social_media_posting_service.dart
git add lib/services/twitter_oauth_service.dart
git add lib/main.dart
git add pubspec.yaml
git add TRACK_C_SETUP.md
```

### Step 4: Commit with clear message
```bash
git commit -m "Track C: Add Gemma provider, Twitter OAuth service, and social media pipeline

- Add GemmaProvider for threat assessment state management
- Add SocialMediaProvider for Twitter posting state
- Implement GemmaThreatAssessmentService with mock + real API
- Implement TwitterOAuthService for OAuth 2.0 flow
- Implement SocialMediaPostingService as main pipeline
- Integrate Provider in main.dart (MultiProvider setup)
- Add http package dependency
- All Week 1 mocks ready for testing

Ready for Friday (Apr 12) integration with Track A"
```

### Step 5: Push to remote
```bash
git push -u origin feature/track-c-mvp
```

---

## 📋 Files Changed Summary

| File | Type | Status | Notes |
|------|------|--------|-------|
| `lib/providers/gemma_provider.dart` | NEW | ✅ Ready | Mock + real Gemma API |
| `lib/providers/social_media_provider.dart` | NEW | ✅ Ready | Twitter OAuth + posting |
| `lib/services/gemma_threat_assessment_service.dart` | NEW | ✅ Ready | Threat analysis service |
| `lib/services/twitter_oauth_service.dart` | NEW | ✅ Ready | Twitter OAuth service |
| `lib/services/social_media_posting_service.dart` | NEW | ✅ Ready | Main pipeline orchestrator |
| `lib/main.dart` | MODIFIED | ✅ Ready | Added Provider setup (minimal changes) |
| `pubspec.yaml` | MODIFIED | ✅ Ready | Added http dependency |
| `TRACK_C_SETUP.md` | NEW | ✅ Ready | This documentation |

---

## 🔑 Next Steps (Friday Apr 12 - Merge Day)

### For Other Track Leads
```bash
# Other devs pull your branch
git checkout feature/track-c-mvp
git pull

# Run tests
flutter pub get
flutter run -d chrome  # Test mocks work
```

### For You (Integration Friday)
```bash
# When Track A audio buffer is ready
git fetch origin
git rebase origin/develop  # Update with main changes

# Merge into develop
git checkout develop
git merge feature/track-c-mvp

# Push merged develop
git push origin develop
```

---

## 🚨 Conflict Prevention Strategy

**Your changes are isolated to:**
- NEW: `lib/providers/` (no conflicts, completely new directory)
- NEW: `lib/services/` (only Track C services, no conflicts)
- MINIMAL: `lib/main.dart` (only added imports + MultiProvider wrap)
- MINIMAL: `pubspec.yaml` (only added http package)

**Other tracks should NOT modify:**
- ✅ `lib/providers/` (yours exclusively)
- ✅ `lib/services/gemma_*.dart` (yours exclusively)
- ✅ `lib/services/social_media_*.dart` (yours exclusively)
- ✅ `lib/services/twitter_*.dart` (yours exclusively)

---

## ✅ Pre-Push Checklist

Before pushing to remote:

- [ ] All files created locally
- [ ] `flutter pub get` runs without errors
- [ ] `flutter run -d chrome` builds successfully
- [ ] Mock data displays correctly on screen
- [ ] No merge conflicts with `develop` branch
- [ ] Commit message is clear and descriptive
- [ ] `.env` file NOT pushed (contains API keys)

---

## 🆘 If Conflicts Occur (Mon Apr 15+)

### Check what changed on main
```bash
git diff develop feature/track-c-mvp
```

### If conflicts in main.dart
```bash
# Your imports are at top of file
# Other tracks' imports won't affect yours
# Manually merge if needed: keep both imports separate
```

### Resolve conflicts
```bash
git mergetool  # Use VS Code's conflict resolver
# OR manually fix conflicting files
git add resolved-file.dart
git rebase --continue
```

---

## 📞 Questions?

If you encounter any git issues:
1. Run: `git status` (shows current state)
2. Run: `git log --oneline` (shows recent commits)
3. Ask in team standup
4. Don't force push to shared branches

---

**Status: Ready to push to `feature/track-c-mvp` ✅**

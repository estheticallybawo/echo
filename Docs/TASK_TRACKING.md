# Guardian App - Branch & Task Tracking

## Quick Reference: Feature Branches by Phase

### Phase 1: Critical Path (Weeks 1-3)

| Branch | Owner | Status | Priority | Est. Hours | Blocking |
|--------|-------|--------|----------|-----------|----------|
| `feature/voice-activation` | TBD | 🟦 Ready | P0 | 40 | YES |
| `feature/emergency-activation` | TBD | 🟦 Ready | P0 | 30 | YES |
| `feature/location-tracking` | TBD | 🟦 Ready | P0 | 35 | YES |
| `feature/audio-capture` | TBD | 🟦 Ready | P0 | 25 | Partial |
| `feature/contact-management` | TBD | 🟦 Ready | P1 | 20 | NO |
| `feature/local-database` | TBD | 🟦 Ready | P1 | 30 | NO |
| `feature/permissions-management` | TBD | 🟦 Ready | P1 | 20 | NO |

### Phase 2: Integration Features (Weeks 3-5)

| Branch | Owner | Status | Priority | Est. Hours | Blocking |
|--------|-------|--------|----------|-----------|----------|
| `feature/gemma-analysis` | TBD | 🟦 Ready | P0 | 35 | Depends: voice-activation |
| `feature/contact-notifications` | TBD | 🟦 Ready | P1 | 30 | Depends: contact-management |
| `feature/audio-feedback` | TBD | 🟦 Ready | P1 | 20 | NO |
| `feature/haptic-feedback` | TBD | 🟦 Ready | P1 | 40 | NO |
| `feature/speech-transcription` | TBD | 🟦 Ready | P1 | 30 | Depends: audio-capture |
| `feature/incident-persistence` | TBD | 🟦 Ready | P1 | 25 | Depends: local-database, audio-capture |
| `feature/encryption` | TBD | 🟦 Ready | P1 | 35 | NO |

### Phase 3: Polish & Testing (Weeks 5-6)

| Branch | Owner | Status | Priority | Est. Hours | Blocking |
|--------|-------|--------|----------|-----------|----------|
| `feature/auto-post-alerts` | TBD | 🟦 Ready | P1 | 35 | Depends: gemma-analysis |
| `feature/proximity-services` | TBD | 🟦 Ready | P2 | 25 | Depends: location-tracking |
| `feature/system-test` | TBD | 🟦 Ready | P1 | 30 | Depends: all services |
| `feature/user-settings` | TBD | 🟦 Ready | P2 | 25 | NO |
| `feature/fake-call` | TBD | 🟦 Ready | P2 | 15 | NO |
| `feature/background-services` | TBD | 🟦 Ready | P1 | 40 | NO |
| `feature/local-notifications` | TBD | 🟦 Ready | P2 | 20 | NO |

### Phase 4: Polish & Documentation (Week 6+)

| Branch | Owner | Status | Priority | Est. Hours | Blocking |
|--------|-------|--------|----------|-----------|----------|
| `feature/testing-infrastructure` | TBD | 🟦 Ready | P1 | 45 | NO |
| `feature/crash-reporting` | TBD | 🟦 Ready | P3 | 15 | NO |
| `feature/analytics` | TBD | 🟦 Ready | P3 | 20 | NO |
| `feature/battery-optimization` | TBD | 🟦 Ready | P2 | 30 | NO |
| `feature/remote-notifications` | TBD | 🟦 Ready | P2 | 25 | NO |
| `docs/api-documentation` | TBD | 🟦 Ready | P2 | 20 | NO |
| `docs/contributor-guidelines` | TBD | 🟦 Ready | P2 | 10 | NO |

**Status Indicators**:
- 🟦 Ready (Not Started)
- 🟨 In Progress
- 🟩 Completed
- 🔴 Blocked
- ⚠️ Needs Review

---

## Team Assignment Template

### Team Member 1: ________________
**Assigned Branches**:
- [ ] `feature/voice-activation` - Voice recognition (E2B)
- [ ] `feature/audio-capture` - Audio recording
- [ ] `feature/speech-transcription` - Voice-to-text
- [ ] `feature/background-services` - Background listener

**Sprint 1**: voice-activation + audio-capture
**Sprint 2**: speech-transcription, assist with contact-notifications
**Sprint 3**: background-services, testing & polish

---

### Team Member 2: ________________
**Assigned Branches**:
- [ ] `feature/location-tracking` - GPS tracking
- [ ] `feature/contact-management` - Contact storage
- [ ] `feature/contact-notifications` - SMS/WhatsApp alerts
- [ ] `feature/proximity-services` - Nearby services

**Sprint 1**: location-tracking + contact-management
**Sprint 2**: contact-notifications + proximity-services
**Sprint 3**: system-test, assist with AI analysis

---

### Team Member 3: ________________
**Assigned Branches**:
- [ ] `feature/gemma-analysis` - AI incident analysis
- [ ] `feature/local-database` - Hive/Isar setup
- [ ] `feature/incident-persistence` - Persistence layer
- [ ] `feature/auto-post-alerts` - Social media posting

**Sprint 1**: local-database + incident-persistence
**Sprint 2**: gemma-analysis + auto-post-alerts
**Sprint 3**: user-settings, documentation

---

### Team Member 4: ________________
**Assigned Branches**:
- [ ] `feature/haptic-feedback` - Native haptics
- [ ] `feature/audio-feedback` - Audio playback
- [ ] `feature/encryption` - Data encryption
- [ ] `feature/permissions-management` - Permission flows

**Sprint 1**: permissions-management + encryption
**Sprint 2**: haptic-feedback + audio-feedback
**Sprint 3**: system-test, testing-infrastructure

---

## Sprint Planning Template

### Weekly Standup Checklist
```
Date: ________

Team Member 1 (________________):
✓ Completed last week: ___________
↓ Working on this week: ___________
⚠ Blockers: ___________
📊 % Complete: ___________

Team Member 2 (________________):
✓ Completed last week: ___________
↓ Working on this week: ___________
⚠ Blockers: ___________
📊 % Complete: ___________

Team Member 3 (________________):
✓ Completed last week: ___________
↓ Working on this week: ___________
⚠ Blockers: ___________
📊 % Complete: ___________

Team Member 4 (________________):
✓ Completed last week: ___________
↓ Working on this week: ___________
⚠ Blockers: ___________
📊 % Complete: ___________

Next Week's Focus:
- ___________
- ___________
- ___________
```

---

## Adding Features as GitHub Issues

Create issues from the FEATURES.md list using this template:

### Issue Template: `FEATURE_<name>.md`

```markdown
---
title: "[FEATURE] <Feature Name>"
labels: feature
assignee: <team-member>
---

## Description
[Copy from FEATURES.md]

## Requirements
- [ ] Requirement 1
- [ ] Requirement 2
- [ ] Requirement 3

## Tech Stack
- Package 1
- Package 2

## Acceptance Criteria
- [ ] Fully implemented
- [ ] Unit tests (>80% coverage)
- [ ] Integration tests pass
- [ ] Code review approved
- [ ] CI/CD passes

## Blocking
- Depends on: [if any]
- Blocks: [if any]

## Implementation Notes
[Add as work progresses]

## Time Estimate
~40 hours

## Resources
- [Link to relevant docs]
```

### Quick GitHub Issue Creation

You can bulk create issues with GitHub CLI:

```bash
# Install GitHub CLI if not already done
# (already available in most dev environments)

# Create feature as issue
gh issue create --title "[FEATURE] Voice Activation" \
  --body "See FEATURES.md line 50-100" \
  --label feature \
  --assignee @teamMember1

# Or create multiple at once:
gh issue create --title "[FEATURE] Emergency Activation" --label feature
gh issue create --title "[FEATURE] Location Tracking" --label feature
# ... etc
```

---

## Pull Request Template

Create `.github/pull_request_template.md`:

```markdown
## 🔗 Related Issue
Closes #<issue_number>

## 📝 Description
Brief description of changes.

## 🎯 Type of Change
- [ ] New feature
- [ ] Bug fix
- [ ] Refactor
- [ ] Documentation
- [ ] Dependency update

## ✅ Checklist
- [ ] Tests added/updated
- [ ] Code follows style guide
- [ ] No new warnings generated
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] All CI/CD checks pass

## 🧪 Testing
Describe how this was tested:
- [ ] Unit tests
- [ ] Integration tests
- [ ] Manual testing

## 📸 Screenshots (if UI changes)
[Add screenshots here]

## 📚 Additional Context
[Any other context about the PR]
```

---

## GitHub Actions CI/CD Setup

Create `.github/workflows/flutter-test.yml`:

```yaml
name: Flutter Test & Analyze

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.35.6'
    
    - name: Get dependencies
      run: flutter pub get
    
    - name: Analyze code
      run: flutter analyze
    
    - name: Run tests
      run: flutter test --coverage
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        files: ./coverage/lcov.info
```

---

## Progress Tracking Dashboard

Update this weekly during standups:

### Overall Progress
```
Week 1: ████░░░░░░ 40%
Week 2: ██████░░░░ 60%
Week 3: ████████░░ 80%
Week 4: ██████████ 100%
```

### By Feature Area
```
Voice/Audio Features:           ████░░░░░░ 45%
Location/Notification:          ███░░░░░░░ 35%
AI/Data Processing:             ██░░░░░░░░ 25%
Native/Security:                ░░░░░░░░░░ 0%
Testing/Documentation:          ░░░░░░░░░░ 0%
```

### Critical Path Status
```
✓ Voice Activation:             [----------] Start by Day 3
  Emergency Activation:         [----------] Start by Day 7
  Location Tracking:            [----------] Start by Day 10
  → Gemma Analysis:             [----------] Start by Day 15
  → Contact Notifications:      [----------] Start by Day 15
  → Audio/Haptic Feedback:      [----------] Start by Day 15
```

---

## Blockers Log

| Date | Feature | Blocker | Resolution | Owner |
|------|---------|---------|------------|-------|
| TBD | voice-activation | E2B API key setup | Request from team | TBD |
| TBD | contact-notifications | Twilio account setup | Create account, add keys | TBD |
| TBD | gemma-analysis | Gemma API key | Create API key via Google | TBD |

---

## Success Metrics

By end of Phase 1 (Week 3):
- ✓ Voice activation working end-to-end
- ✓ Location tracking functional
- ✓ Emergency activation triggering correctly
- ✓ Contacts stored locally
- ✓ All Phase 1 branches merged to main

By end of Phase 2 (Week 5):
- ✓ Gemma AI analysis generating
- ✓ SMS/WhatsApp notifications working
- ✓ Audio/haptic feedback integrated
- ✓ Incident database storing logs
- ✓ >80% unit test coverage

By end of Phase 3 (Week 6):
- ✓ System self-test passing
- ✓ Auto-post alerts working
- ✓ All services integrated
- ✓ Zero critical bugs
- ✓ Documentation complete

---

## Key Dates & Milestones

| Date | Milestone | Owner |
|------|-----------|-------|
| Day 1 | Team assignment & setup | Project Lead |
| Day 3 | Phase 1 development begins | All |
| Day 10 | Phase 1 code review | All |
| Day 15 | Phase 1 merge to main | All |
| Day 22 | Phase 2 development begins | All |
| Day 35 | Phase 2 merge to main | All |
| Day 42 | Phase 3 begins | All |
| Day 49 | MVP ready for testing | All |

---

## Resources & Links

- **Figma Design**: [Add link when ready]
- **Hiny's Story**: [Add reference link]
- **Flutter Docs**: https://flutter.dev
- **Dart Docs**: https://dart.dev
- **Google Fonts**: https://fonts.google.com
- **Gemma API**: https://ai.google.dev
- **E2B**: https://e2b.dev
- **Hive Database**: https://hivedb.dev
- **Firebase**: https://firebase.google.com

---

## Questions & Support

For questions about:
- **Voice features**: Reach out to Team Member 1
- **Location/Notifications**: Reach out to Team Member 2
- **AI/Data**: Reach out to Team Member 3
- **Native/Security**: Reach out to Team Member 4
- **Overall**: Reach out to Project Lead

Regular sync meetings: [Schedule to be confirmed]
Emergency channel: [Slack/Discord to be set up]

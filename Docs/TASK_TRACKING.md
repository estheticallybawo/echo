# Echo App - Branch & Task Tracking

## Quick Reference: Feature Branches by Phase

### Phase 1: Critical Path 

| Branch | Owner | Status | Priority | Est. Hours | Blocking |
|--------|-------|--------|----------|-----------|----------|
| `feature/voice-activation` | TBD | 🟦 Ready | P0 | 40 | YES |
| `feature/emergency-activation` | TBD | 🟦 Ready | P0 | 30 | YES |
| `feature/location-tracking` | TBD | 🟦 Ready | P0 | 35 | YES |
| `feature/audio-capture` | TBD | 🟦 Ready | P0 | 25 | Partial |
| `feature/contact-management` | TBD | 🟦 Ready | P1 | 20 | NO |
| `feature/local-database` | TBD | 🟦 Ready | P1 | 30 | NO |
| `feature/permissions-management` | TBD | 🟦 Ready | P1 | 20 | NO |

### Phase 2: Integration Features 

| Branch | Owner | Status | Priority | Est. Hours | Blocking |
|--------|-------|--------|----------|-----------|----------|
| `feature/gemma-analysis` | TBD | 🟦 Ready | P0 | 35 | Depends: voice-activation |
| `feature/contact-notifications` | TBD | 🟦 Ready | P1 | 30 | Depends: contact-management |
| `feature/audio-feedback` | TBD | 🟦 Ready | P1 | 20 | NO |
| `feature/haptic-feedback` | TBD | 🟦 Ready | P1 | 40 | NO |
| `feature/speech-transcription` | TBD | 🟦 Ready | P1 | 30 | Depends: audio-capture |
| `feature/incident-persistence` | TBD | 🟦 Ready | P1 | 25 | Depends: local-database, audio-capture |
| `feature/encryption` | TBD | 🟦 Ready | P1 | 35 | NO |

### Phase 3: Polish & Testing 

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

### Team Member 1: Naema
**Assigned Branches**:
- [ ] `feature/voice-activation` - Voice recognition (E2B)
- [ ] `feature/audio-capture` - Audio recording
- [ ] `feature/speech-transcription` - Voice-to-text
- [ ] `feature/background-services` - Background listener

**Sprint 1**: voice-activation + audio-capture
**Sprint 2**: speech-transcription, assist with contact-notifications
**Sprint 3**: background-services, testing & polish

---

### Team Member 2: Precious
**Assigned Branches**:
- [ ] `feature/location-tracking` - GPS tracking
- [ ] `feature/contact-management` - Contact storage
- [ ] `feature/contact-notifications` - SMS/WhatsApp alerts
- [ ] `feature/proximity-services` - Nearby services

**Sprint 1**: location-tracking + contact-management
**Sprint 2**: contact-notifications + proximity-services
**Sprint 3**: system-test, assist with AI analysis

---

### Team Member 3: Esther
**Assigned Branches**:
- [ ] `feature/gemma-analysis` - AI incident analysis
- [ ] `feature/local-database` - Hive/Isar setup
- [ ] `feature/incident-persistence` - Persistence layer
- [ ] `feature/auto-post-alerts` - Social media posting

**Sprint 1**: local-database + incident-persistence
**Sprint 2**: gemma-analysis + auto-post-alerts
**Sprint 3**: user-settings, documentation

---

### Team Member 4: Rola
**Assigned Branches**:
- [ ] `feature/haptic-feedback` - Native haptics
- [ ] `feature/audio-feedback` - Audio playback
- [ ] `feature/encryption` - Data encryption
- [ ] `feature/permissions-management` - Permission flows

**Sprint 1**: permissions-management + encryption
**Sprint 2**: haptic-feedback + audio-feedback
**Sprint 3**: system-test, testing-infrastructure

---

## Questions & Support

For questions about:
- **Voice features**: Reach out to Team Naema
- **Location/Notifications**: Reach out to Team Precious
- **AI/Data**: Reach out to Team Esther
- **Native/Security**: Reach out to Team Rola
- **Overall**: Reach out to Product Lead 



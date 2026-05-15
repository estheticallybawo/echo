# Echo

Echo is a Flutter safety assistant built for the Gemma 4 Good Hackathon. The current submission path is a Chrome-first demo that uses a local Gemma/llama.cpp server, local emergency state, an Echo Feed, optional ElevenLabs speech, and an optional Telegram bridge for Tier 1/Tier 2 contact responses.

Echo is intentionally designed with graceful degradation: if speech recognition, Gemma, ElevenLabs, or Telegram is unavailable, the emergency UI, local state, typed fallback, and escalation timers should still keep moving.

## What Works Now

- Chrome demo with voice SOS, typed fallback, and listening/thinking/speaking states.
- Local Gemma reasoning through `llama.cpp` on `http://localhost:8080`.
- Tier 1, Tier 2, and Tier 3/Echo Feed escalation flow.
- Local storage for returning demo users and emergency/feed state.
- Optional ElevenLabs TTS through a local proxy. Do not put the ElevenLabs API key in Flutter code.
- Optional Telegram bot bridge for contact alerts and SAFE/HELP/CALL replies.
- APK-facing model catalog/download UI for teammate testing.

## Current Constraints

- Chrome is the reliable test surface for the hackathon demo.
- Direct Gemma WAV/audio understanding works through `llama-mtmd-cli` experiments, but it is slow on the current laptop. The app therefore uses transcript-first Gemma reasoning by default.
- On-device Gemma inference is architecturally prepared, but not claimed as fully validated without Android device/runtime testing.
- Telegram and ElevenLabs require internet and local secrets.

## Prerequisites

- Flutter 3.19+ and Dart 3.3+
- Node.js 18+ for local proxy scripts
- A running `llama.cpp` server with a Gemma GGUF model
- Chrome for the main demo

## Start Gemma

Start your local `llama.cpp` server before running Echo. Example:

```powershell
cd C:\llama.cpp\build\bin\Release
.\llama-server.exe -m C:\llama.cpp\models\gemma-4-E2B-it-Q8_0.gguf --host 127.0.0.1 --port 8080 --ctx-size 131072
```

Echo checks both `/completion` and `/v1/chat/completions` depending on the path being tested.

## Optional ElevenLabs Voice

Use the local proxy so your long-lived ElevenLabs key never ships in Flutter web or APK code.

```powershell
cd C:\Users\DELL\gemma4good\echo
$env:ELEVENLABS_API_KEY="your_elevenlabs_key"
$env:ELEVENLABS_VOICE_ID="EYQ7WzWOUhRLHwL7i08O"
node scripts\elevenlabs_tts_proxy.mjs
```

## Optional Telegram Contact Bridge

Create a Telegram bot, get the chat ID for your demo contact/group, then run:

```powershell
cd C:\Users\DELL\gemma4good\echo
$env:TELEGRAM_BOT_TOKEN="your_telegram_bot_token"
$env:TELEGRAM_TIER1_CHAT_ID="your_chat_id"
$env:TELEGRAM_TIER2_CHAT_ID="your_chat_id_or_backup_group"
node scripts\telegram_escalation_bridge.mjs
```

If these variables are missing, the bridge prints a message preview instead of sending real Telegram alerts.

## Run The Chrome Demo

```powershell
cd C:\Users\DELL\gemma4good\echo
flutter pub get
flutter run -d chrome `
  --dart-define=ECHO_DEMO_CLOUD_TTS=true `
  --dart-define=ELEVENLABS_PROXY_URL=http://localhost:8787/tts `
  --dart-define=ELEVENLABS_VOICE_ID=EYQ7WzWOUhRLHwL7i08O `
  --dart-define=ECHO_TELEGRAM_BRIDGE_URL=http://localhost:8790
```

For a local-only run without ElevenLabs or Telegram:

```powershell
flutter run -d chrome
```

The app supports demo OTP `000000` for local sign-up/testing.

## Health Check Before Recording

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\check_demo_health.ps1"
```

Expected healthy output:

```text
Gemma: ready and active
ElevenLabs: ready
Telegram bridge: ready
Echo demo context: loaded
```

Gemma audio is optional and may show unavailable unless you also start the experimental audio proxy.

## Experimental Gemma Audio Path

Direct WAV understanding is intentionally opt-in because it can take minutes on CPU.

```powershell
$env:GEMMA_SERVER_URL="http://127.0.0.1:8080"
$env:GEMMA_MODEL_NAME="gemma-4-E2B-it-Q8_0"
node scripts\gemma_audio_proxy.mjs
```

Then run Flutter with:

```powershell
flutter run -d chrome --dart-define=GEMMA_AUDIO_PROXY_URL=http://localhost:8788/audio/analyze --dart-define=ECHO_ENABLE_GEMMA_AUDIO_FALLBACK=true
```

For the demo, keep this disabled unless you specifically want to show the slower audio experiment.

## Build And Checks

```powershell
flutter analyze
flutter test
flutter build web
flutter build apk
```

`flutter build apk` is for internal/team testing. The hackathon submission story should center on the functional web demo and repo, not a guaranteed production Android on-device inference runtime.

## Secrets Policy

Do not commit `.env`, API keys, Telegram tokens, generated credential exports, model files, or downloaded GGUF/mmproj assets. Use PowerShell environment variables or local ignored config files for personal secrets.

## Key Paths

- `lib\screens\home\home_screen.dart` - voice SOS and conversation entry point
- `lib\screens\home\emergency_active_screen.dart` - escalation UI and bridge polling
- `lib\services\gemma` - local Gemma/llama.cpp integration
- `lib\services\sound` - speech, transcription, and TTS services
- `lib\services\model` - model catalog and download-state simulation
- `scripts\check_demo_health.ps1` - demo readiness check
- `scripts\elevenlabs_tts_proxy.mjs` - local ElevenLabs proxy
- `scripts\telegram_escalation_bridge.mjs` - local Telegram bridge

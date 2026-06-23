# The Salon App

Flutter salon app with a local AR Mirror try-on flow and a NestJS backend for
premium AI image edits.

## What Is In This App

### Free AR Mirror

- Photo upload from gallery
- Camera capture
- 2D hairstyle overlay
- 2D beard overlay
- Nail art overlay
- Tattoo overlay
- Manual adjust controls: move, resize, rotate, opacity, hide/show, reset
- Save result to gallery
- Share result
- Google ML Kit face detection for face-based placement
- Google ML Kit face mesh / pose support for better placement
- MediaPipe Hand Landmarker on Android for five-finger nail positioning

### Premium AI Try-On

- Premium Studio UI
- One premium unlock covers AI hair, AI beard, and AI nails
- Mock payment flow for development/demo
- NestJS endpoint for premium AI image generation
- fal.ai Nano Banana integration prepared for realistic image edits
- Mock mode available when fal.ai credits are not available

Important: the premium payment flow is a development/demo flow. Production
payments still need real Google Play Billing, App Store, or approved payment
provider receipt verification.

## Requirements

- Git
- Flutter SDK with Dart `3.12` or newer
- Android Studio with Android SDK
- Node.js and npm
- PostgreSQL if running backend database features
- Android phone/emulator for AR Mirror testing

Check your setup:

```powershell
flutter doctor
flutter devices
node --version
npm --version
```

## First-Time Setup

```powershell
git clone <repository-url>
cd the_salon_app
git switch artryon
flutter pub get
npm install
Copy-Item .env.example .env
```

Do not commit `.env`.

## Environment

Default free/demo setup:

```env
AI_TRYON_PROVIDER=mock
AI_TRYON_MOCK_ENABLED=true
PREMIUM_PAYMENT_MOCK_ENABLED=true
```

Real premium AI setup with fal.ai Nano Banana:

```env
AI_TRYON_PROVIDER=fal
AI_TRYON_MOCK_ENABLED=false
FAL_KEY=your_fal_key
```

fal.ai is credit-based. If your fal.ai balance is zero, keep mock mode enabled.

## Run Flutter App

List devices:

```powershell
flutter devices
```

Run app:

```powershell
flutter run
```

Run on a specific device:

```powershell
flutter run -d <device-id>
```

Example:

```powershell
flutter run -d ef30fa262287
```

The free 2D AR Mirror works without starting the backend.

## Android Phone Setup

On Xiaomi/Redmi/Android devices, enable:

```text
Developer options > USB debugging
Developer options > Install via USB
Developer options > USB debugging (Security settings)
```

If the phone shows `unauthorized`, tap:

```text
Developer options > Revoke USB debugging authorizations
```

Then reconnect USB and allow the debugging popup.

## Run Backend

Start NestJS:

```powershell
npm run start:dev
```

Build backend:

```powershell
npm run build
```

Backend base URL:

```text
http://localhost:3000
```

If testing from a real phone, Flutter must call the laptop IP address, not
`localhost`.

## Validate Before Push

```powershell
npm run build
flutter build apk --debug --no-pub
```

Optional checks:

```powershell
flutter analyze
flutter test
```

## Main Feature Files

```text
lib/features/ai_salon/presentation/pages/ai_smart_mirror_workspace.dart
lib/features/ai_salon/domain/services/face_detection_service.dart
lib/features/ai_salon/domain/services/ar_overlay_renderer.dart
lib/features/ai_salon/domain/services/advanced_tryon_detection_service.dart
lib/features/ai_salon/data/repositories/three_d_model_repository.dart
lib/features/premium/
src/modules/ar-tryon/services/three-d-tryon.service.ts
src/modules/ar-tryon/services/premium-entitlement.service.ts
android/app/src/main/kotlin/com/infusion/the_salon_app/MainActivity.kt
android/app/src/main/assets/hand_landmarker.task
assets/tryon/
```

## Git Push

```powershell
git status
git add .
git commit -m "Add AR mirror and premium AI try-on flow"
git push origin artryon
```

Do not commit:

```text
.env
node_modules/
dist/
build/
.dart_tool/
```

## Production Notes

- Free 2D AR Mirror is local/offline except normal app permissions.
- Premium AI depends on fal.ai credits and backend configuration.
- Payment is not production-ready until real receipt verification is connected.
- `.env.example` is safe to commit; `.env` is not safe to commit.

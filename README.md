# The Salon App

Flutter salon application with a local virtual try-on feature and an optional
NestJS backend.

## Requirements

- Git
- Flutter SDK with Dart `3.12` or newer
- Android Studio with Android SDK
- Node.js and npm
- PostgreSQL only when running the backend
- A physical Android device or emulator

Check the local setup:

```powershell
flutter doctor
flutter devices
node --version
npm --version
```

## Clone And Set Up

```powershell
git clone <repository-url>
cd the_salon_app
git switch artryon
flutter pub get
npm install
```

Create the local backend environment file:

```powershell
Copy-Item .env.example .env
```

Do not commit `.env`.

## Run Flutter App

List available devices:

```powershell
flutter devices
```

Run on the selected device:

```powershell
flutter run -d <device-id>
```

Example:

```powershell
flutter run -d ef30fa262287
```

The AR Mirror works locally without starting the backend.

## Validate Flutter Changes

```powershell
dart format lib test
flutter analyze
flutter test
```

## Run Optional Backend

Update `.env` with the local PostgreSQL configuration before starting the
backend.

```powershell
npm run build
npm run start:dev
```

The backend runs at:

```text
http://localhost:3000
```

## Git Workflow

Get the latest branch changes:

```powershell
git switch artryon
git pull origin artryon
```

Commit and push changes:

```powershell
git status
git add .
git commit -m "Describe the change"
git push origin artryon
```

Do not commit:

- `.env`
- `node_modules/`
- `dist/`
- `build/`
- `.dart_tool/`

## AR Try-On Files

```text
lib/features/ai_salon/presentation/pages/ai_smart_mirror_workspace.dart
lib/features/ai_salon/domain/services/face_detection_service.dart
lib/features/ai_salon/domain/services/ar_overlay_renderer.dart
assets/tryon/
```

## Gradle SSL Troubleshooting

If Gradle reports `PKIX path building failed`, antivirus HTTPS scanning may be
using a certificate that Android Studio Java does not trust. Add that verified
certificate to a user-local Java trust store and configure it in:

```text
%USERPROFILE%\.gradle\gradle.properties
```

Never disable SSL certificate verification.

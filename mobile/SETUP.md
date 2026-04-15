# Cadence Mobile — Setup Guide

Flutter app for Cadence (cloud users only — Supabase auth).

## 1. Prerequisites

- Flutter SDK ≥ 3.22 (`flutter --version`)
- Dart SDK ≥ 3.4
- Xcode 15+ (iOS) / Android Studio (Android)

## 2. Create the Flutter project scaffold

Run this once in the `mobile/` directory to generate the `ios/`, `android/`, and platform files:

```bash
cd mobile
flutter create --project-name cadence --org com.cadence --platforms ios,android .
flutter pub get
```

## 3. Platform permissions

### iOS — `ios/Runner/Info.plist`

Add inside the `<dict>` tag:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Cadence needs microphone access to score your pronunciation.</string>
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <false/>
</dict>
```

### Android — `android/app/src/main/AndroidManifest.xml`

Add before `<application>`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

Set `minSdkVersion` to 21 in `android/app/build.gradle`:

```gradle
defaultConfig {
    minSdkVersion 21
    ...
}
```

## 4. Environment variables

Pass Supabase credentials and API base URL at build time:

```bash
# Development
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key \
  --dart-define=API_BASE_URL=https://your-cadence-app.com

# Release build (iOS)
flutter build ios \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=API_BASE_URL=...

# Release build (Android)
flutter build apk \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=API_BASE_URL=...
```

## 5. Fonts (optional — bundled vs. CDN)

The app uses Google Fonts (Funnel Display / Sour Gummy) fetched at runtime.
For offline-first, download the .ttf files and place them in `assets/fonts/`:

```
assets/fonts/FunnelDisplay-Regular.ttf
assets/fonts/FunnelDisplay-Bold.ttf
assets/fonts/SourGummy-Regular.ttf
assets/fonts/SourGummy-Bold.ttf
```

Then update `pubspec.yaml` to use the `fonts:` section instead of `google_fonts`.

## 6. Deep links (Supabase email auth)

For password reset links to open the app, configure deep links:

**iOS** — Add to `Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array><string>cadence</string></array>
  </dict>
</array>
```

**Android** — Add intent filter in `AndroidManifest.xml`:
```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="https" android:host="your-cadence-app.com" />
</intent-filter>
```

In your Supabase dashboard → Auth → URL Configuration, add:
```
cadence://auth/callback
```

## 7. Run

```bash
flutter run
```

## Architecture

```
lib/
├── main.dart               # Supabase init, app entry
├── app.dart                # MaterialApp + GoRouter
├── core/
│   ├── config/             # AppConfig (dart-define env vars)
│   ├── theme/              # Colors, typography, spacing, theme
│   ├── router/             # GoRouter with auth guards
│   ├── services/           # ApiService (Dio), AudioService
│   └── models/             # Module, Lesson, AssessmentResult, CoachMessage
├── features/
│   ├── auth/               # Login, Signup, ForgotPassword + AuthProvider
│   ├── onboarding/         # Name + goals setup
│   ├── shell/              # Bottom nav shell
│   ├── home/               # Dashboard with stats + quick actions
│   ├── learn/              # Module grid → lesson list → practice
│   ├── conversation/       # Conversation modules + session
│   ├── coach/              # AI Coach chat with voice
│   └── profile/            # Stats, subscription, sign out
└── shared/
    └── widgets/            # CadenceButton, CadenceCard, AudioRecorder, etc.
```

## Design system

All colors, typography, and spacing match the Cadence web app exactly:

- Background: `#F2E8CF` (Vanilla Cream)
- Primary: `#386641` (Hunter Green)
- Accent: `#A7C957` (Yellow Green)
- Fonts: Funnel Display (body) + Sour Gummy/Baloo 2 (headings)
- All buttons: `StadiumBorder` (pill shape)
- All cards: `BorderRadius.circular(24)` (rounded-3xl)

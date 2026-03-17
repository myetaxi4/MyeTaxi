# 🚖 MyeTaxi Tracker v1.0

**Professional GPS Fleet Management Platform**  
Real-time tracking · Driver behaviour · Revenue estimation · Document expiry alerts

---

## 📱 Platforms
| Platform | Status | Build Output |
|----------|--------|--------------|
| Android  | ✅ Ready | APK + AAB |
| iOS      | ✅ Ready | IPA |
| Web PWA  | ✅ Ready | Static bundle |

---

## 🚀 Get Your APK in 3 Steps (GitHub Actions — FREE)

### Step 1 — Push to GitHub

```bash
# In your terminal:
git init
git add .
git commit -m "feat: MyeTaxi Tracker v1.0 initial commit"
git remote add origin https://github.com/YOUR_USERNAME/myetaxi-tracker.git
git push -u origin main
```

### Step 2 — Watch the build
1. Go to your repo on GitHub
2. Click the **Actions** tab
3. You'll see **"MyeTaxi Tracker — Build & Release"** running automatically
4. Wait ~8–12 minutes for it to complete ✅

### Step 3 — Download your APK
1. Click the completed workflow run
2. Scroll down to **Artifacts**
3. Click **MyeTaxiTracker-release-apk** → downloads a ZIP
4. Unzip → install **MyeTaxiTracker-v1.0.X-release.apk** on your Android device

---

## ⚡ Alternative: Codemagic (No GitHub needed)

1. Go to **[codemagic.io](https://codemagic.io)** → Sign up free
2. Click **Add application** → Upload ZIP or connect GitHub
3. Select **"Use codemagic.yaml"**
4. Click **Start build**
5. Download APK from build artifacts when complete

---

## 🔧 Required Setup Before Building

### 1. Firebase Project (Required for full functionality)
1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Create project named **myetaxi-tracker**
3. Enable: **Authentication** · **Firestore** · **Storage** · **Cloud Messaging**
4. Add Android app with package `com.myetaxi.tracker`
5. Download `google-services.json` → replace `android/app/google-services.json`

### 2. Google Maps API Key (Required for live map)
1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Enable **Maps SDK for Android** and **Maps SDK for iOS**
3. Create an API key
4. In `android/app/src/main/AndroidManifest.xml` replace:
   ```
   YOUR_GOOGLE_MAPS_API_KEY_HERE
   ```
   with your actual key

### 3. GitHub Secrets (for automated CI/CD builds)
Go to: **GitHub repo → Settings → Secrets and variables → Actions → New secret**

| Secret Name | Value |
|-------------|-------|
| `GOOGLE_MAPS_API_KEY` | Your Google Maps API key |
| `FIREBASE_ANDROID_GOOGLE_SERVICES` | Full contents of `google-services.json` |
| `KEYSTORE_BASE64` | `base64 -i release.jks` output (optional, for signed APK) |
| `KEYSTORE_PASSWORD` | Your keystore password (optional) |
| `KEY_ALIAS` | Your key alias (optional) |
| `KEY_PASSWORD` | Your key password (optional) |

> **Note:** Without the keystore secrets, a debug-signed APK is still built and works fine for testing.

---

## 🏗️ Project Structure

```
MyeTaxi_Tracker/
├── lib/
│   ├── main.dart                    # App entry, Firebase init, auth, navigation
│   ├── theme/app_theme.dart         # Dark telematics colour palette
│   ├── models/                      # Vehicle, Driver, Trip, Alert data models
│   ├── services/
│   │   ├── gps_service.dart         # SMS + Internet GPS packet processor
│   │   ├── sms_listener_service.dart # Android SMS receiver
│   │   ├── expiry_checker_service.dart # Daily document expiry alerts
│   │   └── notification_service.dart   # Push + local notifications
│   ├── providers/fleet_provider.dart    # Riverpod state (Firestore streams)
│   ├── screens/                     # 6 main screens
│   └── widgets/shared_widgets.dart  # Reusable components
├── android/                         # Full Android project
├── ios/                             # iOS project
├── web/                             # PWA manifest + index
├── .github/workflows/build.yml      # GitHub Actions CI/CD
├── codemagic.yaml                   # Codemagic CI/CD
└── pubspec.yaml                     # Flutter dependencies
```

---

## 📡 GPS Device Configuration

### SMS Format (send to the Android phone running the app)
```
GPS-TK-001,25.2048,55.2708,87.5,180,2026-03-14T10:22:00,HB=0,HA=1
```
Fields: `SERIAL, LAT, LNG, SPEED(km/h), HEADING, TIMESTAMP, HB=harsh_brake, HA=harsh_accel`

### Internet Format (HTTP POST to your relay server)
```json
{
  "serial": "GPS-TK-001",
  "lat": 25.2048,
  "lng": 55.2708,
  "speed": 87.5,
  "heading": 180,
  "ts": "2026-03-14T10:22:00Z",
  "hb": false,
  "ha": false
}
```

---

## 🔔 Alert Thresholds
| Days Until Expiry | Severity | Documents |
|-------------------|----------|-----------|
| 60 days | Info (Yellow) | Registration, Insurance, License |
| 42 days (6 weeks) | Warning (Orange) | Registration, Insurance, License |
| 14 days | Critical (Red) | Registration, Insurance, License |
| Expired | Critical (Red) | Registration, Insurance, License |

---

## 🛠️ Local Development

```bash
# Prerequisites: Flutter 3.19+ · Android Studio or VS Code
flutter pub get
flutter run                    # Run on connected device or emulator
flutter build apk --debug      # Build debug APK locally
flutter build apk --release    # Build release APK locally
flutter build web              # Build PWA locally
```

---

## 📋 Version History
| Version | Date | Notes |
|---------|------|-------|
| v1.0.0 | March 2026 | Initial release — GPS tracking, driver mgmt, expiry alerts, revenue |

---

*MyeTaxi Tracker v1.0 · Built with Flutter + Firebase*

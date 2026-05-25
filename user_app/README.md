# 🩸 Blood Connect — Flutter Blood Donation App

> A full-stack Flutter app connecting blood donors with recipients in real-time.
> Built with **Flutter + Firebase + Provider + Material 3**.

---

## 📁 Complete Project Structure

```
blood_donation_app/
├── android/
│   ├── app/
│   │   ├── build.gradle                  ← Firebase google-services plugin
│   │   ├── google-services.json          ← ⚠️ YOU GENERATE THIS (see Step 2)
│   │   └── src/main/AndroidManifest.xml  ← INTERNET permission
│   └── build.gradle                      ← Project-level Gradle
│
├── lib/
│   ├── main.dart                         ← App entry, Firebase init, providers
│   ├── firebase_options.dart             ← ⚠️ YOU GENERATE THIS (see Step 2)
│   │
│   ├── models/
│   │   └── models.dart                   ← UserModel, DonorModel, RequestModel
│   │
│   ├── services/
│   │   ├── auth_service.dart             ← Firebase Auth (login/register/logout)
│   │   └── firestore_service.dart        ← Firestore CRUD + search queries
│   │
│   ├── providers/
│   │   ├── auth_provider.dart            ← AppAuthProvider (ChangeNotifier)
│   │   ├── donor_provider.dart           ← DonorProvider + RequestProvider
│   │   └── request_provider.dart         ← Re-exports RequestProvider
│   │
│   ├── utils/
│   │   └── app_theme.dart                ← Material 3 theme, colors, AppConstants
│   │
│   ├── widgets/
│   │   ├── blood_group_badge.dart         ← Reusable blood group chip
│   │   └── request_card.dart              ← Request list card (donor & recipient)
│   │
│   └── screens/
│       ├── auth/
│       │   ├── auth_wrapper.dart          ← Auth state router + splash
│       │   ├── login_screen.dart
│       │   ├── register_screen.dart       ← Role selection (Donor / Recipient)
│       │   └── forgot_password_screen.dart
│       │
│       ├── donor/
│       │   ├── donor_nav.dart             ← Bottom nav (Dashboard/Requests/Profile)
│       │   ├── donor_dashboard.dart       ← Profile card, availability, pending reqs
│       │   └── donor_profile_screen.dart  ← Create / Edit full donor profile
│       │
│       ├── recipient/
│       │   ├── recipient_nav.dart         ← Bottom nav (Home/Search/Requests/Profile)
│       │   ├── recipient_home.dart        ← Quick actions, recent requests
│       │   ├── donor_search_screen.dart   ← Real-time search by blood group + city
│       │   ├── donor_detail_screen.dart   ← Full donor profile + Send Request button
│       │   ├── create_request_screen.dart ← Blood request form (normal + emergency)
│       │   └── recipient_profile_screen.dart
│       │
│       └── shared/
│           └── requests_screen.dart       ← Tabbed request history (donor & recipient)
│
├── pubspec.yaml
├── firestore.rules                        ← Security rules (deploy to Firebase)
└── firestore.indexes.json                 ← Composite indexes (deploy to Firebase)
```

---

## 🚀 Step-by-Step Setup

### Step 1 — Install Flutter Dependencies

```bash
flutter pub get
```

---

### Step 2 — Configure Firebase  (**most important step**)

#### 2a. Create a Firebase Project
1. Go to [https://console.firebase.google.com](https://console.firebase.google.com)
2. Click **Add project** → name it `blood-connect` → Continue
3. Disable Google Analytics (optional) → **Create project**

#### 2b. Enable Authentication
1. Firebase Console → **Authentication** → Get Started
2. **Sign-in method** tab → Enable **Email/Password** → Save

#### 2c. Create Firestore Database
1. Firebase Console → **Firestore Database** → Create database
2. Choose **Production mode** (we'll add rules) → Select a region → Enable
3. Once created, go to **Rules** tab and paste the contents of `firestore.rules`

#### 2d. Register Android App
1. Firebase Console → Project Overview → **Add app** → Android icon
2. **Android package name**: `com.example.blood_donation_app`
3. App nickname: `Blood Connect` → Register app
4. Download **`google-services.json`** → place it at:
   ```
   android/app/google-services.json
   ```
5. Skip the "Add Firebase SDK" steps (already in `build.gradle`)

#### 2e. Generate `firebase_options.dart` (recommended method)

```bash
# Install FlutterFire CLI once
dart pub global activate flutterfire_cli

# Log in to Firebase
firebase login

# Run from your project root — select your project when prompted
flutterfire configure
```

This auto-generates `lib/firebase_options.dart` with your real credentials.
It also updates `android/app/google-services.json`.

---

### Step 3 — Deploy Firestore Indexes

```bash
# Install Firebase CLI if not already installed
npm install -g firebase-tools

firebase login
firebase init firestore     # select your project, accept defaults
firebase deploy --only firestore
```

Or manually create the indexes via Firebase Console → Firestore → Indexes.

---

### Step 4 — Run the App

```bash
flutter run
```

For release build:
```bash
flutter build apk --release
```

---

## 🗄️ Firestore Collections Schema

### `users/{uid}`
| Field       | Type      | Description              |
|-------------|-----------|--------------------------|
| uid         | String    | Firebase Auth UID        |
| email       | String    | User email               |
| fullName    | String    | Display name             |
| role        | String    | `"donor"` or `"recipient"` |
| phone       | String?   | Optional phone           |
| city        | String?   | Optional city            |
| bloodGroup  | String?   | Optional blood group     |
| createdAt   | Timestamp | Account creation time    |

### `donors/{uid}`
| Field            | Type       | Description                    |
|------------------|------------|--------------------------------|
| uid              | String     | Same as Firebase Auth UID      |
| fullName         | String     |                                |
| age              | Number     | 18–65                          |
| gender           | String     | Male / Female / Other          |
| phone            | String     |                                |
| city             | String     |                                |
| bloodGroup       | String     | A+, A-, B+, B-, AB+, AB-, O+, O- |
| weight           | Number     | kg (min 50)                    |
| healthStatus     | String     | Healthy / Not Healthy          |
| diseases         | String?    | Optional                       |
| lastDonationDate | Timestamp? | Nullable                       |
| isAvailable      | Boolean    | Shown in search results only if true |
| totalDonations   | Number     | Auto-incremented on completion |
| email            | String     |                                |
| updatedAt        | Timestamp  |                                |

### `requests/{requestId}`
| Field            | Type       | Description                          |
|------------------|------------|--------------------------------------|
| recipientId      | String     | UID of the requesting user           |
| recipientName    | String     |                                      |
| recipientContact | String     |                                      |
| donorId          | String     | UID of the target donor              |
| donorName        | String     |                                      |
| patientName      | String     |                                      |
| bloodGroup       | String     |                                      |
| hospital         | String     |                                      |
| city             | String     |                                      |
| urgency          | String     | Normal / Emergency                   |
| status           | String     | pending → accepted/rejected → completed |
| additionalNotes  | String?    |                                      |
| unitsNeeded      | Number     | Default 1                            |
| createdAt        | Timestamp  |                                      |
| respondedAt      | Timestamp? | Set when donor accepts/rejects       |
| completedAt      | Timestamp? | Set when marked completed            |

---

## 🔄 Request Lifecycle

```
Recipient finds donor via Search Screen
    ↓
Recipient taps "Send Blood Request" on Donor Detail Screen
    ↓
CreateRequestScreen → stored in Firestore with status: "pending"
    ↓
Donor sees it on Dashboard (pending count badge) + Requests tab
    ↓
Donor taps Accept → status: "accepted"  |  Reject → status: "rejected"
    ↓
Recipient sees update in real-time on My Requests screen
    ↓
Recipient taps "Mark as Completed" → status: "completed"
   + donor.totalDonations += 1
   + donor.lastDonationDate = now
```

---

## 🎨 Design System

| Token             | Value            |
|-------------------|------------------|
| Primary           | `#E53935` (Blood Red) |
| Primary Dark      | `#B71C1C`        |
| Primary Light     | `#EF9A9A`        |
| Accent            | `#FF1744`        |
| Surface (light)   | `#FFFAFA`        |
| Background (dark) | `#0D0D0D`        |
| Font              | Poppins (Google Fonts) |
| Card Radius       | 16 dp            |
| Button Height     | 56 dp            |
| Min Touch Target  | 48 × 48 dp       |

Dark mode is **automatic** — follows system setting via `ThemeMode.system`.

---

## 🔐 Security Rules Summary

| Collection  | Read                          | Write                               |
|-------------|-------------------------------|-------------------------------------|
| `users`     | Any authenticated user        | Owner only                          |
| `donors`    | Any authenticated user        | Owner (donor role) only             |
| `requests`  | Donor or Recipient involved   | Recipient creates; Donor updates status |

---

## 🛠️ Troubleshooting

| Issue | Fix |
|-------|-----|
| `google-services.json not found` | Download from Firebase Console and place in `android/app/` |
| `firebase_options.dart` missing values | Run `flutterfire configure` |
| Firestore queries fail with "index required" | Deploy `firestore.indexes.json` or click the link in the error log |
| Build fails on `minSdk` | Ensure `minSdk 21` in `android/app/build.gradle` |
| `DuplicateProviderError` | Check you're using `context.read<>()` not `Provider.of<>()` in build methods |
| Auth state not persisting | Firebase Auth persists by default on Android — no extra config needed |

---

## 📦 Key Packages

| Package              | Version  | Purpose                     |
|----------------------|----------|-----------------------------|
| `firebase_core`      | ^2.24.2  | Firebase initialization     |
| `firebase_auth`      | ^4.16.0  | Email/password auth         |
| `cloud_firestore`    | ^4.14.0  | Real-time database          |
| `provider`           | ^6.1.1   | State management            |
| `google_fonts`       | ^6.1.0   | Poppins font                |
| `flutter_animate`    | ^4.3.0   | Smooth animations           |
| `intl`               | ^0.19.0  | Date formatting             |
| `shimmer`            | ^3.0.0   | Loading skeletons           |

---

## ✅ Feature Checklist

- [x] Email/Password Authentication
- [x] Role selection at registration (Donor / Recipient)
- [x] Forgot Password (email reset)
- [x] Auth state persistence (auto-login)
- [x] Role-based navigation (different bottom nav per role)
- [x] Donor profile CRUD (all required fields)
- [x] Availability toggle (real-time Firestore update)
- [x] Recipient blood request form (normal + emergency)
- [x] Real-time donor search (blood group + city filters)
- [x] Full donor detail view with Send Request button
- [x] Duplicate request prevention
- [x] Donor Accept / Reject incoming requests
- [x] Mark request as Completed
- [x] Auto-increment donor.totalDonations on completion
- [x] Request history for both roles (tabbed)
- [x] System dark / light mode
- [x] Material 3 with blood-red theme
- [x] Firestore security rules
- [x] Composite indexes for all queries

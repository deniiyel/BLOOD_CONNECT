# BLOOD CONNECT

A complete blood donation management system built using Flutter and Firebase.
This project contains two separate applications:

* User App
* Admin App

Both applications use the same Firebase backend while remaining fully separated in structure, functionality, and interface.

---

# Project Overview

Blood Connect is designed to help donors, recipients, and administrators manage blood donation activities efficiently.

The system allows users to:

* Search blood donors
* Create blood requests
* Manage profiles
* Connect donors and recipients

The admin application provides management and monitoring tools for handling users, requests, and system activity.

---

# Applications Included

## 1. User App

The user application is designed for:

* Blood donors
* Blood recipients
* General users

### Main Features

* User authentication
* Register/Login
* Search donors by blood group
* Search donors by city
* Create blood requests
* Donor profile management
* Recipient profile management
* Real-time database updates
* Firebase integration
* Clean Flutter UI

---

## 2. Admin App

The admin application is completely separated from the user application.

### Main Features

* Admin dashboard
* Manage users
* View donor records
* View recipient records
* Monitor blood requests
* User activity management
* Firebase data management
* Administrative controls

---

# Tech Stack

## Frontend

* Flutter
* Dart

## Backend & Services

* Firebase Authentication
* Cloud Firestore
* Firebase Storage

## Tools & Platforms

* Git
* GitHub
* Android Studio
* VS Code

---

# Project Structure

```text
BLOOD_CONNECT/
│
├── user_app/
│   ├── lib/
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
│
├── admin_app/
│   ├── lib/
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
│
└── README.md
```

---

# Firebase Setup

This project uses Firebase services.

To run the project locally:

1. Create your own Firebase project
2. Enable Authentication
3. Enable Cloud Firestore
4. Enable Firebase Storage
5. Add Firebase configuration files

Required files:

```text
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
lib/firebase_options.dart
```

These files are excluded from the public repository for security purposes.

---

# Installation

## Clone Repository

```bash
git clone https://github.com/deniiyel/BLOOD_CONNECT.git
```

---

# Run User App

```bash
cd user_app
flutter pub get
flutter run
```

---

# Run Admin App

```bash
cd admin_app
flutter pub get
flutter run
```

---

# Requirements

* Flutter SDK
* Dart SDK
* Android Studio or VS Code
* Firebase account
* Android Emulator or Physical Device

---

# Features Summary

## User Side

* Authentication
* Blood donor search
* Blood request creation
* Profile management
* Real-time updates

## Admin Side

* Dashboard
* User management
* Request monitoring
* Data management

---

# Security Notes

Firebase configuration files are not included in this repository.

Sensitive credentials should never be uploaded publicly.

---

# Future Improvements

* Push notifications
* Google Maps integration
* Blood bank module
* Emergency donor alerts
* Dark mode
* Advanced analytics
* Chat system

---

# Author

Daniyal Ahmad

Computer Science Student
Flutter & Firebase Developer

---

# License

This project is for educational and learning purposes.

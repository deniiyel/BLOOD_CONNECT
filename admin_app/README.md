# Blood Donation Admin App

Admin-only Flutter console for managing the blood donation platform.

This project is not the donor or recipient portal. The app only includes:

- Admin authentication and admin setup
- Admin dashboard
- People and donor profile management
- Blood request history management
- Firebase/Firestore integration for platform records

## Project Structure

```text
lib/
  main.dart
  firebase_options.dart
  models/
    models.dart
  providers/
    admin_provider.dart
    auth_provider.dart
  screens/
    admin/
      admin_dashboard.dart
      admin_history_screen.dart
      admin_nav.dart
      admin_people_screen.dart
    auth/
      admin_setup_screen.dart
      auth_wrapper.dart
      forgot_password_screen.dart
      login_screen.dart
  services/
    admin_service.dart
    auth_service.dart
  utils/
    app_theme.dart
    firebase_errors.dart
    helpers.dart
  widgets/
    app_card.dart
    blood_group_badge.dart
```

## Removed From This App

The admin app does not include donor or recipient portal screens such as:

- Donor dashboard/profile UI
- Recipient home/search/request creation UI
- Public registration with donor/recipient role selection
- Shared user request tabs for donor/recipient workflows

The admin console still reads user, donor, and request records because those are the records administrators manage.

## Run

```bash
flutter pub get
flutter run
```

## Firebase

The app expects Firebase Authentication and Cloud Firestore to be configured. Admin accounts are stored in `users/{uid}` with `role: "admin"`.

The setup screen creates only admin accounts and requires the configured admin setup code in `AppConstants.adminSetupCode`.

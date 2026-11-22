# CS310_TermProject

# Pomodoro App

CS310 Mobile Application Development Term Project (Group 26)

## About

Pomodoro App is a study helper built with Flutter. It is based on the Pomodoro technique: study for 25 minutes, take a 5-minute break, and take a longer break after every four sessions. Users can connect each study session to a task and look back at their study history to follow their own progress.

Planned features:

- Pomodoro timer that switches between study time, short breaks and long breaks
- Adjustable session lengths, volume and vibration settings
- Task list where tasks can be linked to study sessions
- Study history with daily and weekly study time
- Notifications when a session or break ends
- User accounts with email and password.

Built with Flutter, Firebase Authentication and Cloud Firestore.

## Group Members

| Name | Student ID |
| --- | --- |
| Ahmet Kağan İlerisoy (Step 1 Coordinator) | 35901 |
| Altay Ünsaldık | 34079 |
| Deniz Temel | 35683 |

## Running the app

**Flutter version:** 3.50.1 (stable channel), Dart 3.14.0. Check yours with `flutter --version`.

### Quick start (no Firebase needed)

```bash
git clone https://github.com/akilerisoy/CS310_TermProject.git
cd CS310_TermProject
flutter pub get
flutter run
```

Without a Firebase configuration the app starts in **demo mode**: log in or sign up with any valid email and password, and every screen works with placeholder tasks and study history. A banner at the top says demo mode is on. Nothing is saved in demo mode.

### With Firebase (real accounts and saved data)

The app follows the Step 2.1 wireframes (`CS310_Group26_Step2.1.pdf`): splash, log in, sign up, reset password, timer (focus / short break / long break), task chooser, tasks, add or edit task, stats and history, settings, and end-of-session notifications.

1. Install Flutter and create a Firebase project with **Authentication (Email/Password)** and **Cloud Firestore** enabled.
2. Connect the app to your project (this overwrites the placeholder `lib/firebase_options.dart`):

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

3. Add these Firestore rules (each user can only read and write their own data):

   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{db}/documents {
       match /users/{uid}/{document=**} {
         allow read, write: if request.auth != null && request.auth.uid == uid;
       }
     }
   }
   ```

4. Run it:

   ```bash
   flutter pub get
   flutter run
   ```

### Data layout (Firestore)

- `users/{uid}`: name, email, `settings` (session lengths, volume, vibration, notifications)
- `users/{uid}/tasks/{id}`: title, notes, done, createdAt
- `users/{uid}/sessions/{id}`: endedAt, seconds, taskId, taskTitle (statistics are calculated from these)

### Notes on behaviour

- The timer stores the moment the current phase ends instead of counting ticks, so it stays correct while the app is in the background or closed. A notification is scheduled for that moment.
- Only finished focus sessions are saved to the history. Skipping a session does not save it.
- The end-of-session sound is generated in code, so there is no audio asset.
- If `lib/firebase_options.dart` still holds the `REPLACE_ME` placeholder values, or Firebase fails to start, the app falls back to demo mode instead of stopping.

### UI resources

- Colors and shared text styles: `lib/theme.dart`. Shared spacing values: `lib/spacing.dart`.
- Custom font: Poppins, bundled in `assets/fonts/` and registered in `pubspec.yaml` (SIL Open Font License, `assets/fonts/OFL.txt`).
- Local image: the app logo `assets/images/logo.png` (`Image.asset`, on the splash and log in screens).
- Network image: the profile picture in Settings > Account is loaded with `Image.network` and falls back to an icon when offline.

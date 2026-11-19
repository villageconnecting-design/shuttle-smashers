# Firebase Setup Guide for Shuttle Smashers

## Your App Details
- **Android Package Name:** `com.shuttlesmashers.app`
- **iOS Bundle ID:** `com.shuttlesmashers.app`

---

## PART 1: Firebase Console Setup (Do This First)

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Create a project"** (or "Add project")
3. Enter project name: `shuttle-smashers`
4. Click **Continue**
5. Google Analytics: Enable it (recommended) or disable
6. If enabled, select or create a Google Analytics account
7. Click **Create Project**
8. Wait for project creation, then click **Continue**

---

### Step 2: Add Android App

1. On Firebase Console dashboard, click **Android icon** (or "+ Add app")
2. Fill in the details:
   - **Android package name:** `com.shuttlesmashers.app`
   - **App nickname:** Shuttle Smashers Android
   - **Debug signing certificate SHA-1:** (See below how to get it)
3. Click **Register app**

#### How to Get SHA-1 Certificate:
Open terminal in your project folder and run:
```bash
cd android
./gradlew signingReport
```
Copy the **SHA1** value from the output (looks like: `XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX`)

4. **Download `google-services.json`**
5. **IMPORTANT:** Place the file at:
   ```
   shuttle_Smashers/android/app/google-services.json
   ```
6. Click **Next** through remaining steps
7. Click **Continue to console**

---

### Step 3: Add iOS App

1. On Firebase Console, click **"+ Add app"** → **iOS icon**
2. Fill in the details:
   - **Apple bundle ID:** `com.shuttlesmashers.app`
   - **App nickname:** Shuttle Smashers iOS
   - **App Store ID:** (Leave empty for now)
3. Click **Register app**
4. **Download `GoogleService-Info.plist`**
5. **IMPORTANT:** Place the file at:
   ```
   shuttle_Smashers/ios/Runner/GoogleService-Info.plist
   ```
   (You need to add it via Xcode - see instructions below)
6. Click **Next** through remaining steps
7. Click **Continue to console**

#### Adding GoogleService-Info.plist to Xcode:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Right-click on `Runner` folder in left sidebar
3. Select **"Add Files to Runner..."**
4. Select `GoogleService-Info.plist`
5. Ensure **"Copy items if needed"** is checked
6. Click **Add**

---

### Step 4: Enable Authentication

1. In Firebase Console, go to **Build** → **Authentication**
2. Click **Get Started**
3. Go to **Sign-in method** tab
4. Enable these providers:

#### Phone Authentication:
1. Click **Phone**
2. Toggle **Enable**
3. Click **Save**

#### Google Sign-In:
1. Click **Google**
2. Toggle **Enable**
3. Enter your **Project support email**
4. Click **Save**

---

### Step 5: Create Firestore Database

1. In Firebase Console, go to **Build** → **Firestore Database**
2. Click **Create database**
3. Choose location: Select nearest to your users (e.g., `asia-south1` for India)
4. Select **Start in test mode** (for development)
5. Click **Create**

#### Set Up Security Rules (After testing):
Go to **Rules** tab and replace with:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Matches - authenticated users can read, participants can write
    match /matches/{matchId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null &&
        (resource.data.createdBy == request.auth.uid ||
         request.auth.uid in resource.data.participants);
    }

    // Tournaments - authenticated users can read, creator can write
    match /tournaments/{tournamentId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null &&
        resource.data.createdBy == request.auth.uid;
    }

    // Players - all authenticated users can read, owners can write
    match /players/{playerId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == playerId;
    }
  }
}
```

---

## PART 2: Files You Need to Add

After completing Firebase Console setup, you need these files:

### File 1: google-services.json
- **Download from:** Firebase Console → Project Settings → Your Android App
- **Place at:** `android/app/google-services.json`

### File 2: GoogleService-Info.plist
- **Download from:** Firebase Console → Project Settings → Your iOS App
- **Place at:** `ios/Runner/GoogleService-Info.plist` (via Xcode)

### File 3: Update firebase_options.dart

Open `lib/firebase_options.dart` and replace the placeholder values:

1. Go to **Firebase Console** → **Project Settings** (gear icon)
2. Scroll to **Your apps** section
3. For **Android**, find these values in `google-services.json`:
   - `apiKey`: Look for `"api_key"` → `"current_key"`
   - `appId`: Look for `"mobilesdk_app_id"`
   - `messagingSenderId`: Look for `"project_number"`
   - `projectId`: Look for `"project_id"`
   - `storageBucket`: Look for `"storage_bucket"`

4. For **iOS**, find these values in `GoogleService-Info.plist`:
   - `apiKey`: Look for `API_KEY`
   - `appId`: Look for `GOOGLE_APP_ID`
   - `messagingSenderId`: Look for `GCM_SENDER_ID`
   - `projectId`: Look for `PROJECT_ID`
   - `storageBucket`: Look for `STORAGE_BUCKET`

### File 4: Update iOS Info.plist (for Google Sign-In)

1. Open `GoogleService-Info.plist`
2. Find the `REVERSED_CLIENT_ID` value
3. Open `ios/Runner/Info.plist`
4. Replace `YOUR_REVERSED_CLIENT_ID` with the actual value

---

## PART 3: Firestore Collections Structure

Your app will use these collections:

```
firestore/
├── users/                    # User profiles
│   └── {userId}/
│       ├── uid: string
│       ├── name: string
│       ├── email: string
│       ├── phone: string
│       ├── avatar: string
│       ├── wins: number
│       ├── losses: number
│       ├── points: number
│       ├── matchesPlayed: number
│       └── createdAt: timestamp
│
├── matches/                  # Match records
│   └── {matchId}/
│       ├── id: string
│       ├── type: string (Singles/Doubles/Mixed)
│       ├── teamA: array<string> (player IDs)
│       ├── teamB: array<string> (player IDs)
│       ├── teamANames: string
│       ├── teamBNames: string
│       ├── scores: array<{teamA: number, teamB: number}>
│       ├── currentSet: number
│       ├── status: string (live/completed)
│       ├── winner: string (teamA/teamB)
│       ├── createdBy: string (userId)
│       ├── createdAt: timestamp
│       └── completedAt: timestamp
│
├── tournaments/              # Tournament data
│   └── {tournamentId}/
│       ├── id: string
│       ├── name: string
│       ├── description: string
│       ├── startDate: timestamp
│       ├── endDate: timestamp
│       ├── prizePool: string
│       ├── status: string (upcoming/live/completed)
│       ├── participants: array<string>
│       ├── bracket: map
│       ├── winner: string
│       ├── createdBy: string
│       └── createdAt: timestamp
│
└── players/                  # Player profiles (public)
    └── {odlayerId}/
        ├── uid: string
        ├── name: string
        ├── avatar: string
        ├── wins: number
        ├── losses: number
        ├── points: number
        └── isGuest: boolean
```

---

## Checklist Before Running

- [ ] Created Firebase project
- [ ] Added Android app with package name `com.shuttlesmashers.app`
- [ ] Downloaded and placed `google-services.json` in `android/app/`
- [ ] Added iOS app with bundle ID `com.shuttlesmashers.app`
- [ ] Downloaded and added `GoogleService-Info.plist` to Xcode project
- [ ] Enabled Phone authentication
- [ ] Enabled Google Sign-In
- [ ] Created Firestore database
- [ ] Run `flutter pub get` to install dependencies

---

## After Setup - Run These Commands

```bash
# Navigate to project
cd "/Users/jeevanreddy/Documents/flutter projectsideas/shuttle_Smashers"

# Get dependencies
flutter pub get

# Run on iOS
flutter run -d ios

# Run on Android
flutter run -d android
```

---

## Troubleshooting

### Android Issues:
- **Gradle sync failed:** Run `cd android && ./gradlew clean`
- **SHA-1 mismatch:** Re-add SHA-1 in Firebase Console

### iOS Issues:
- **GoogleService-Info.plist not found:** Ensure added via Xcode, not just copied
- **Pod install failed:** Run `cd ios && pod install --repo-update`

### Auth Issues:
- **Phone auth not working:** Ensure SHA-1 is added for Android
- **Google Sign-In failed:** Check SHA-1 and OAuth configuration

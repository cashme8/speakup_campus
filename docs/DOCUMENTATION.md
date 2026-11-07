# SpeakUp Campus: Project Documentation

## Contents

1. [Overview](#1-overview)
2. [Users and roles](#2-users-and-roles)
3. [Features](#3-features)
4. [Technology choices](#4-technology-choices)
5. [Architecture](#5-architecture)
6. [Backend](#6-backend)
7. [Setting up the backend from scratch](#7-setting-up-the-backend-from-scratch)
8. [Using the app](#8-using-the-app)
9. [Testing](#9-testing)
10. [Challenges and decisions](#10-challenges-and-decisions)
11. [Limitations and future work](#11-limitations-and-future-work)

---

## 1. Overview

On campus, problems like a leaking tap in the residence, a dead socket in a
classroom or a broken chair in the library are usually reported by word of
mouth or in a WhatsApp group. Reports get lost, the same issue gets reported
many times, and students never find out whether anyone is working on it.

SpeakUp Campus gives this process one place:

- a student reports the problem in under a minute, with a photo if they have
  one;
- other students can see that it has already been reported and press
  **"Me too"** instead of filing a duplicate;
- staff see every report, update its status and leave a note;
- the reporter watches the status change live, from **Submitted** to
  **In Progress** to **Resolved**.

## 2. Users and roles

| Role | Who | Can do |
|---|---|---|
| **Student** | Anyone with an `@alustudent.com` / `@alueducation.com` email | Create reports (optionally anonymous), browse campus reports, "Me too" on other people's reports, withdraw their own report while it is still *Submitted* |
| **Staff** | Accounts promoted by an administrator | Everything a student can see, plus updating the status of any report with a note |

Every account starts as a student. Staff are promoted by changing `role` to
`staff` in the user's Firestore document from the Firebase console. The app
cannot do this, and the security rules block any attempt to do it from a
client (see [6.3](#63-firestore-security-rules)).

## 3. Features

**Authentication**
- Register with name, department, ALU email and password
- Only ALU email domains are accepted, checked in the app *and* in the
  security rules
- Email verification is required: until the link is clicked, the app only
  shows the "Check your inbox" screen
- Resend the verification email, reset a forgotten password, sign out
- The session is restored on app start (splash screen while it loads)

**Reporting**
- Quick-report shortcuts on the home screen for each category
- Form: category, title (5–60 chars), description (15–500 chars), campus
  area, optional room/detail, optional photo from camera or gallery
- Anonymous switch: the name is not stored on the report at all
- Duplicate warning: if reports are already open at the chosen area, the form
  shows them before you submit
- Leaving a half-filled form asks for confirmation first

**Tracking**
- Home: greeting, summary counts, recent reports
- Reports: *My reports* / *Campus* toggle, search (title, location,
  description), filter by status and category
- Detail: photo (tap for full screen), status timeline, activity log with
  staff notes, number of people affected
- Withdraw your own report while it is *Submitted*

**Staff**
- "Update status" button on every report, with an optional note
- Staff see reporter names on non-anonymous reports. Students only see
  "A student"

## 4. Technology choices

| Need | Choice | Why |
|---|---|---|
| UI | Flutter + Material 3 | One codebase for Android and iOS |
| State management | **Provider** (`ChangeNotifier`) | Simple, officially recommended, and enough for two pieces of app-wide state (auth and incidents) |
| Login | **Firebase Authentication** | Email/password with built-in email verification and password reset |
| Database | **Cloud Firestore** | Real-time listeners, so status changes show up instantly without refreshing, plus security rules for role checks |
| Photos | **Supabase Storage** | Free tier with no card needed. Firebase Storage now requires the Blaze plan (see [10](#10-challenges-and-decisions)) |
| Font / images | Plus Jakarta Sans (bundled), local campus photos | Works offline, no runtime font download |

Packages: `firebase_core`, `firebase_auth`, `cloud_firestore`,
`firebase_storage`, `supabase_flutter`, `provider`, `image_picker`, `intl`.

## 5. Architecture

### 5.1 Layers

```
┌──────────────────────────────────────────────────────────┐
│  Screens & widgets      (lib/screens, lib/widgets)       │  read state with
│                                                          │  context.watch / select
├──────────────────────────────────────────────────────────┤
│  Providers              (lib/providers)                  │  business rules,
│  AuthProvider, IncidentProvider                          │  filters, loading/errors
├──────────────────────────────────────────────────────────┤
│  Repository interfaces  (lib/data/repositories.dart)     │  AuthRepository
│                                                          │  IncidentRepository
│                                                          │  PhotoStorage
├──────────────────────────────────────────────────────────┤
│  Implementations        (lib/data/*.dart)                │  Firebase Auth,
│                                                          │  Firestore, Supabase
└──────────────────────────────────────────────────────────┘
```

The rule I followed is that **each layer only talks to the one below it**.
Screens never import Firebase, and providers only know about the abstract
interfaces. This has two benefits:

1. **Testing.** The tests pass in-memory fake repositories, so the whole app
   runs in tests without a network.
2. **Swapping backends.** When Firebase Storage turned out to need a paid
   plan, I wrote `SupabasePhotoStorage` and changed one line in `main.dart`.
   Nothing else in the app changed.

### 5.2 State management with Provider

Both providers are created once at the top of the app in `main.dart`:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
    ChangeNotifierProxyProvider<AuthProvider, IncidentProvider>(
      create: (_) => IncidentProvider(repository: ..., storage: ...),
      update: (_, auth, incidents) => incidents!..bindUser(auth.user),
    ),
  ],
  ...
)
```

**AuthProvider** listens to the auth repository's stream of the current user
and exposes `user`, `initializing`, `loading` and `error`. Its actions
(`login`, `register`, `checkVerified`, `resendVerification`,
`sendPasswordReset`, `logout`) all go through one helper that sets `loading`,
clears old errors and turns exceptions into readable messages.

**IncidentProvider** depends on the signed-in user, which is why it is a
`ChangeNotifierProxyProvider`. Every time the auth state changes, `bindUser`
is called:
- verified user → start listening to the Firestore `incidents` collection;
- signed out / unverified → cancel the listener, clear the list and reset
  filters.

It holds the list of incidents and the current filters, and works out the
views the screens need: `browsable` (my reports or campus), `filtered`
(search + status + category), `recent`, `stats`, and `openAt(location)` for
the duplicate warning. Screens just read these. They don't filter anything
themselves.

**Routing by state.** `AuthGate` in `main.dart` picks the screen from the
auth state, so there is no manual navigation after login or logout:

```
initializing → Splash
no user      → LoginScreen
not verified → VerifyEmailScreen
verified     → MainShell (Home · Reports · Profile)
```

To avoid unnecessary rebuilds, screens use `context.select` when they only
need one value (for example, `MainShell` only rebuilds when `isStaff`
changes).

### 5.3 Folder structure

```
lib/
├── main.dart                 app start, providers, AuthGate
├── firebase_options.dart     generated by flutterfire
├── supabase_config.dart      Supabase URL / key / bucket
├── data/                     repository interfaces + Firebase/Supabase code
├── models/                   AppUser, Incident, StatusEntry
├── providers/                AuthProvider, IncidentProvider
├── screens/                  one file per screen (auth/ for login flow)
├── widgets/                  reusable components (cards, chips, timeline…)
├── theme/app_theme.dart      Material theme
└── utils/                    colours, constants, validators, formatting
```

## 6. Backend

### 6.1 Authentication flow (Firebase Auth)

```
Register ──► create Firebase user ──► save users/{uid} (role: student)
                                   └► send verification email
                │
                ▼
VerifyEmailScreen ── user taps "I've verified, continue"
                │      reload() the user
                │      getIdToken(true)  ← refresh token so rules see email_verified
                ▼
MainShell
```

Two details matter here:

- **Refreshing the token after verification.** Firestore rules and Supabase
  read `email_verified` from the ID token, not from the user object. Clicking
  the link does not change the token the app already has, so after `reload()`
  I force a new token with `getIdToken(true)`. Without this, a just-verified
  user would get "permission denied" until the token expired an hour later.
- **Live profile.** The auth repository combines two streams: the Firebase
  auth state and the user's `users/{uid}` document. So when an admin changes
  someone's role to `staff`, their app switches to the staff view
  immediately.

Firebase error codes (`wrong-password`, `email-already-in-use`,
`too-many-requests`, …) are mapped to plain messages shown in the UI.

### 6.2 Firestore data model

```
users/{uid}
  name         string
  email        string
  department   string
  role         'student' | 'staff'
  createdAt    timestamp

incidents/{incidentId}
  title          string (5–60)
  description    string (15–500)
  category       'facilities' | 'water' | 'electricity' | 'safety' | 'sanitation' | 'furniture'
  location       string   e.g. "Library"
  locationDetail string?  e.g. "2nd floor, near the printers"
  status         'submitted' | 'inProgress' | 'resolved'
  reporterId     uid
  reporterName   string? (null when anonymous)
  isAnonymous    bool
  affectedBy     [uid]    ("Me too")
  imageUrl       string?  public Supabase URL
  imagePath      string?  {uid}/{incidentId}.jpg
  createdAt      server timestamp
  updatedAt      server timestamp
  history        [{status, at, note?, byName?}]
```

**CRUD operations**

| Operation | Who | How |
|---|---|---|
| Create | Student | `IncidentRepository.create`: one `set()` with all fields, status `submitted`, one history entry |
| Read | Any verified user | Real-time `snapshots()` on `incidents`, newest first (limit 300) |
| Update status | Staff | `update()` with `status`, `history: arrayUnion(entry)`, `updatedAt` |
| Update "Me too" | Student | `arrayUnion` / `arrayRemove` of their own uid on `affectedBy` |
| Delete | Reporter | Only while `submitted`. The photo is deleted from storage too |

The history is stored inside the incident as an array, not in a
subcollection. A report only ever has a few entries, and keeping them together
means the detail screen needs one read instead of two.

Timestamps use `FieldValue.serverTimestamp()`, so a wrong phone clock cannot
give a report the wrong date. While a write is still pending, Firestore's
local snapshot has `null` there, and the model treats that as "now" so the new
report shows up instantly.

### 6.3 Firestore security rules

The app hides staff buttons from students, but the UI is not where security
lives. A modified app could send any request, so `firestore.rules` enforces
everything again on the server:

- **Helpers:** `verified()` means signed in, `email_verified == true` and an
  ALU email domain. `isStaff()` reads `users/{uid}.role`.
- **users:** you can only read your own document (staff can read all). On
  create, `role` **must** be `student`, the email must match the token, and
  only known fields are allowed. On update, only `name` and `department` can
  change, never `role` or `email`.
- **incidents create:** every field is validated (lengths, category list,
  status must be `submitted`, `reporterId` must be the caller,
  `reporterName` must be null if anonymous, `affectedBy` empty, exactly one
  history entry, timestamps equal to the server time, photo path must be the
  caller's own folder).
- **incidents update (staff):** only `status`, `history` and `updatedAt` may
  change, and exactly one history entry is added.
- **incidents update (students):** only `affectedBy`, only their own uid
  added or removed, and not on their own report.
- **incidents delete:** only the reporter, only while `submitted`.
- Everything else is denied.

Deploy with:

```bash
firebase deploy --only firestore:rules
```

### 6.4 Photo storage: connecting Supabase to Firebase

Photos are stored in Supabase Storage, but users only ever log in with
Firebase. The two are connected through Supabase's **third-party auth**:
Supabase is told to trust ID tokens issued by my Firebase project.

**How an upload works**

```
1. User picks a photo           image_picker (max 1600px, quality 75)
2. IncidentProvider.submit()    gets a new incident id from Firestore
3. SupabasePhotoStorage         uploads to incident-photos/{uid}/{id}.jpg
   └─ supabase_flutter calls accessToken() → Firebase ID token
      and sends it as "Authorization: Bearer <token>"
4. Supabase                     checks the token signature against Firebase's
                                public keys (project speakup-campus)
5. Storage policy               checks claims in the token (below)
6. App                          saves the incident in Firestore with
                                imageUrl + imagePath
   If step 6 fails, the photo is deleted again so no orphan is left behind.
```

**The connection in code** (`lib/main.dart`):

```dart
await Supabase.initialize(
  url: supabaseUrl,
  publishableKey: supabasePublishableKey,
  accessToken: () async =>
      FirebaseAuth.instance.currentUser?.getIdToken(),
);
```

Because of `accessToken`, Supabase never starts its own session. Whoever is
signed in to Firebase is who Supabase sees.

**Storage policies** (`supabase/storage_policies.sql`). A helper function
checks that the token:

- was issued by **my** Firebase project
  (`iss = https://securetoken.google.com/speakup-campus`);
- has `email_verified = true`;
- has an ALU email.

Then:

- **Insert:** only into the bucket `incident-photos`, only into the folder
  named after your own Firebase uid (`sub` claim), only `.jpg/.jpeg/.png`.
- **Delete:** only files in your own folder (used when withdrawing a report).
- **Read:** the bucket is public, so photos load by URL. This is the same
  model as Firebase Storage download URLs. The URLs are long and only
  appear inside reports, which only verified users can read.

Firebase tokens do not include Supabase's `role` claim, so Supabase runs these
requests as the `anon` role. That is why the policies are written
`to anon, authenticated`. Access is decided by the token claims above, not by
the role, so an anonymous request without a valid Firebase token still fails
every check.

**Keys.** The app only contains the Supabase **publishable** key, which is
public by design (like the Firebase config). The secret/service-role key is
never used in the app.

### 6.5 Error handling

All repositories turn backend errors into an `AppException` with a message a
user can understand ("No internet connection. Your report was not sent.",
"Photo upload was refused…", "That photo is too large"). Providers expose the
message through `error`, and screens show it in a banner or snackbar. Nothing
fails silently.

## 7. Setting up the backend from scratch

You only need this to connect your own Firebase and Supabase projects. The
repository already points to mine.

### 7.1 Firebase

1. Create a project at <https://console.firebase.google.com>.
2. **Authentication → Sign-in method →** enable **Email/Password**.
3. **Firestore Database →** create the database.
4. Install the CLIs and connect the app:
   ```bash
   npm install -g firebase-tools
   firebase login
   dart pub global activate flutterfire_cli
   flutterfire configure        # generates lib/firebase_options.dart
   ```
5. Deploy the rules:
   ```bash
   firebase deploy --only firestore:rules
   ```

### 7.2 Supabase

1. Create a project at <https://supabase.com/dashboard>.
2. **Storage → New bucket:** name `incident-photos`, set it to **Public**
   and (optionally) set a 5 MB size limit.
3. **SQL Editor:** paste and run `supabase/storage_policies.sql`. If your
   Firebase project ID is not `speakup-campus`, change it in the `iss` line
   first.
4. **Authentication → Third-Party Auth → Add provider → Firebase:** enter
   your Firebase **project ID**. Without this step, Supabase rejects Firebase
   tokens and every upload fails.
5. **Project Settings → API Keys:** copy the project URL and the
   **publishable** key into `lib/supabase_config.dart`:
   ```dart
   const supabaseUrl = 'https://<project-ref>.supabase.co';
   const supabasePublishableKey = 'sb_publishable_...';
   ```

### 7.3 Run

```bash
flutter pub get
flutter run
```

### 7.4 Using Firebase Storage instead (Blaze plan)

1. Enable Storage in the Firebase console.
2. `firebase deploy --only storage` (rules are in `storage.rules`).
3. In `main.dart`, pass `FirebasePhotoStorage()` as `photoStorage`.

## 8. Using the app

### Student

1. **Create a student account** → fill in name, department, ALU email,
   password.
2. Open the verification email, tap the link, return to the app and tap
   **I've verified, continue**.
3. On Home, tap a category under *Quick report* or the **+** button.
4. Fill in the form, add a photo if you have one, choose whether to stay
   anonymous, and submit. If the app warns about similar open reports, open
   them and use **Me too** instead.
5. Follow the report under **Reports → My reports**. The status and timeline
   update live.

### Staff

1. Register normally, then an admin sets `role: staff` in Firestore.
2. Open any report and tap **Update status**, pick the new status, add a note
   ("Plumber booked for Thursday") and save.
3. The reporter sees the change immediately.

### Adding photos on the Android emulator

The emulator's gallery starts empty. Drag a `.jpg` from your computer onto the
emulator window (it is saved to *Downloads*), or use **Take a photo**, which
uses the emulator's virtual camera.

## 9. Testing

```bash
flutter analyze   # no issues
flutter test      # 28 tests
```

The tests use fake, in-memory versions of the three repositories
(`test/support/fakes.dart`), so they are fast and don't touch Firebase or
Supabase.

| File | What it covers |
|---|---|
| `auth_provider_test.dart` | login/register errors, ALU domain check, verification state, logout |
| `incident_provider_test.dart` | filters and search, my/campus scope, stats, duplicate detection, privacy labels for anonymous reports, staff-only status updates, photo rollback when saving the report fails |
| `widget_test.dart` | login screen renders, register → verify → home flow, validators |
| `flows_test.dart` | full student flow (submit and see the report), signing out without errors, staff updating a status |

**Manual tests on the emulator**

| Scenario | Expected |
|---|---|
| Register with a Gmail address | Blocked: "Use your ALU email" |
| Log in before verifying | Verify screen only, reports not readable |
| Submit report with photo | Photo appears in Supabase `incident-photos/{uid}/`, report in Firestore with `imageUrl` |
| Student tries to change status (via rules playground) | Permission denied |
| Staff updates status | Reporter's timeline updates live |
| Anonymous report | `reporterName` is `null` in Firestore, other students see "Anonymous student" |
| Withdraw report after staff moved it to In Progress | Option hidden, and the rules reject it |
| Airplane mode, then submit | Clear "No internet connection" message |

## 10. Challenges and decisions

**Firebase Storage needed a paid plan.** New Firebase projects can only use
Cloud Storage on the Blaze plan, and my card was declined when I tried to
upgrade. Instead of dropping photos, I moved them to Supabase Storage and kept
Firebase for everything else. Because storage was already behind the
`PhotoStorage` interface, this meant writing one new class and changing one
line in `main.dart`. The hard part was security: Supabase had to trust my
Firebase logins, which I solved with third-party auth and policies that check
the Firebase token's claims.

**Verified users still got "permission denied".** Right after clicking the
verification link, Firestore rejected requests because the cached ID token
still said `email_verified: false`. Forcing a token refresh after `reload()`
fixed it.

**Crash on sign-out.** Signing out briefly showed a red "Null check operator"
screen. For one frame, screens rebuilt with `user == null` before `AuthGate`
swapped them out. I removed the `user!` assumptions, and those screens now
render nothing for that frame. A widget test covers it so it can't come back.

**Staff role security.** Hiding the staff button is not enough, because anyone
could edit the app. Roles live in Firestore, can only be changed from the
console, and every status update is checked by the rules.

**Privacy for anonymous reports.** At first I only hid the name in the UI.
I changed it so the name is never written to Firestore for anonymous reports,
and the rules reject an anonymous report that includes a name.

## 11. Limitations and future work

- **Push notifications** when a report's status changes (Firebase Cloud
  Messaging needs a Cloud Function, which needs Blaze).
- **Admin panel** to promote staff from the app instead of the console.
- **Photos are public by URL.** Signed, expiring URLs would be stricter.
- **Offline submission** with photo upload retried later.
- **Analytics for staff:** average time to resolve, busiest locations.
- iOS was not tested on a device. It uses the same code and already has the
  camera/photo permission text in `Info.plist`, but it needs
  `flutterfire configure` to be run for the iOS app.

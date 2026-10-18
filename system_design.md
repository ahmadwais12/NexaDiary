# Offline Private Workspace App

## 1. Product Overview

Build a privacy-focused, offline-first personal workspace application.

The application must work without requiring the user to:

* Create an account
* Log in
* Register
* Enter an email address
* Enter a phone number
* Create a password
* Subscribe
* Purchase a plan
* Use cloud storage

The application is completely local-first.

The user can store and manage:

* Notes
* Text
* Documents
* Images
* Videos
* Music
* Audio
* Other files
* Tasks
* Todo lists
* Alarms
* Reminders
* Timetables
* Calendar events
* Folders
* Tags
* Backups

The only monetization method is advertising.

---

# 2. Core Product Philosophy

The application should follow this principle:

> **No account. No subscription. No mandatory cloud. Your data stays on your device.**

The application must remain useful when the device has:

* No Internet
* Airplane mode enabled
* Wi-Fi disabled
* Mobile data disabled
* Poor network connection

Internet is only required for online-dependent features such as advertisements and any future optional online functionality.

---

# 3. Account Policy

## Absolutely no user accounts

Do NOT implement:

* Login
* Sign up
* Registration
* Email authentication
* Phone authentication
* Google login
* Apple login
* Facebook login
* User profiles
* Password accounts
* Subscription accounts

There should be no user account database.

All user data belongs to the local installation.

---

# 4. Monetization Policy

The application is free to use.

There is:

* No subscription
* No premium plan
* No lifetime purchase
* No in-app purchase
* No paid upgrade
* No cloud-storage purchase
* No paid account

## Revenue source

The only revenue source is advertising.

Use Google Mobile Ads / AdMob with App Open Ads.

Google's Flutter Mobile Ads SDK supports App Open Ads, which are intended to monetize app loading and foregrounding.

---

# 5. Advertisement Behavior

Advertising must be completely independent from the user's local data.

## Internet OFF

When the device is offline:

```text
App starts
    ↓
Internet unavailable
    ↓
Do NOT request advertisement
    ↓
Do NOT wait
    ↓
Open application immediately
```

No ad should be displayed.

## Internet ON

When the device has actual Internet access:

```text
App starts
    ↓
Check Internet
    ↓
Internet available
    ↓
Load App Open Ad
    ↓
Ad available?
   / \
 YES  NO
  |    |
  ↓    ↓
Show  Open app
 ad   immediately
  |
  ↓
Open app
```

If the advertisement cannot load, the user must immediately enter the application.

The application must never become unusable because an ad failed.

---

# 6. Internet Detection

Do not assume that Wi-Fi or mobile connectivity means Internet access.

`connectivity_plus` can identify available connection types, but its documentation explicitly states that connectivity does not guarantee actual Internet access.

Use this architecture:

```text
Connectivity Check
       ↓
Network available?
   NO ───────→ Offline mode
   │
  YES
   ↓
Short Internet reachability check
       ↓
Internet actually reachable?
   │
   ├── NO → Offline mode
   │
   └── YES → Online mode
```

The reachability check must:

* Have a short timeout
* Fail quickly
* Never block the app indefinitely
* Handle DNS errors
* Handle connection errors
* Handle timeouts

---

# 7. App Startup Advertisement

The startup process should be:

```text
Application Launch
        ↓
Initialize Flutter
        ↓
Initialize local database
        ↓
Initialize local storage
        ↓
Check Internet
        ↓
Offline?
   ├── YES → Open Home
   │
   └── NO
        ↓
Load App Open Ad
        ↓
Ad ready?
   ├── NO → Open Home
   │
   └── YES
        ↓
Show App Open Ad
        ↓
Open Home
```

The ad must not delay the application unnecessarily.

Google's App Open Ad documentation recommends using a loading screen for cold starts and showing the ad only while the app is still loading.

---

# 8. Advertisement Frequency

Do not display an App Open Ad every time the user briefly switches applications.

Implement a cooldown.

Recommended initial value:

```text
minimum_ad_interval = 20 minutes
```

Example:

```text
User opens app
    ↓
Show ad

User closes app
    ↓
Opens again after 2 minutes
    ↓
No ad

User opens again after 25 minutes
    ↓
Show ad if Internet is available
```

The cooldown should be configurable.

---

# 9. First Launch

Do not make the very first application experience aggressive.

Recommended:

```text
First launch
    ↓
Open application normally
```

After the user has used the application a few times, App Open Ads can begin.

Google's current App Open Ads guidance recommends showing the first ad after users have used the app a few times.

Suggested setting:

```text
minimum_launches_before_ads = 3
```

This is configurable.

---

# 10. No Advertisement in User Content

Never place advertisements:

* Inside notes
* Inside the text editor
* Over text while typing
* Inside the task editor
* Inside the timetable editor
* Inside the Private Vault
* During backup restoration
* During file copying
* During file import
* During file export
* During audio playback
* During video playback
* Inside an alarm screen

Ads should only appear during appropriate application loading/foreground transitions.

---

# 11. App Open Ad Manager

Create a dedicated service:

```text
core/
└── ads/
    ├── app_open_ad_manager.dart
    ├── ad_config.dart
    └── ad_cooldown.dart
```

Responsibilities:

### AppOpenAdManager

* Load ads
* Store loaded ad
* Check whether ad is available
* Check ad expiration
* Show ad
* Dispose ad
* Handle callbacks
* Reload after an ad is shown
* Prevent duplicate ads

Google's documentation recommends a dedicated utility class for loading and showing App Open Ads.

---

# 12. Advertisement State

Maintain:

```text
adLoaded
adShowing
lastAdShownAt
launchCount
isOnline
```

Example:

```text
shouldShowAd():

    if offline:
        return false

    if launchCount < 3:
        return false

    if currentTime - lastAdShownAt < cooldown:
        return false

    if adNotLoaded:
        return false

    return true
```

---

# 13. Ad Failure Behavior

Any of these must result in normal application startup:

* Ad loading failure
* Internet timeout
* DNS failure
* No advertisement available
* Google Mobile Ads SDK error
* Network disconnected
* Ad expired
* Ad failed to display

Never show an error such as:

> "You cannot use the app because an ad could not load."

Instead:

```text
Ad unavailable
    ↓
Continue to application
```

---

# 14. Development Advertisement IDs

During development, use Google's official test ad IDs.

Do not use production ad IDs during development/testing.

Google specifically recommends test ad units during development and warns that using live ads for testing can cause account problems.

Example test App Open IDs:

```text
Android:
ca-app-pub-3940256099942544/9257395921

iOS:
ca-app-pub-3940256099942544/5575463023
```

These are for testing only and must be replaced with production ad unit IDs before release.

---

# 15. Home Dashboard

The home screen should contain:

* Today's date
* Today's tasks
* Upcoming reminders
* Today's timetable
* Recent notes
* Recent files
* Recently played media
* Favorites
* Storage usage
* Quick Add

Example:

```text
TODAY

○ Finish Project       10:00 AM
○ Study Flutter        02:00 PM
○ Gym                  06:00 PM

TIMETABLE

10:00  Project
14:00  Study
18:00  Gym

RECENT

Project Notes
research.pdf
music.mp3
video.mp4
```

---

# 16. Main Navigation

Recommended navigation:

```text
Home
Notes
Tasks
Files
More
```

More:

```text
Calendar
Timetable
Media
Favorites
Private Vault
Backup
Statistics
Settings
```

Quick Add:

```text
+ Note
+ Task
+ Reminder
+ File
+ Image
+ Audio
+ Folder
```

---

# 17. Notes

The note editor should support:

* Plain text
* Rich text
* Headings
* Bold
* Italic
* Underline
* Lists
* Checklists
* Tables
* Links
* Quotes
* Code blocks
* Images
* Audio
* File attachments

Organization:

* Folders
* Subfolders
* Tags
* Favorites
* Pinned notes
* Archive
* Trash
* Recent notes

---

# 18. Files

The app should provide a local file vault.

Supported files:

* PDF
* DOC
* DOCX
* TXT
* ZIP
* Images
* Videos
* Music
* Audio
* Other supported files

Operations:

* Import
* Rename
* Move
* Copy
* Delete
* Favorite
* Tag
* Search
* Share
* Export
* Create folders
* Attach to notes

---

# 19. File Storage Architecture

Do NOT store large videos, music and images directly as SQLite BLOBs.

Use:

```text
SQLite / Drift
    ↓
Metadata

Filesystem
    ↓
Actual files
```

Example:

```text
app_storage/
├── images/
├── videos/
├── audio/
├── music/
├── documents/
└── attachments/
```

Database stores:

```text
file_id
name
path
mime_type
size
hash
folder_id
favorite
created_at
modified_at
```

---

# 20. Images

Features:

* Gallery
* Grid view
* List view
* Albums
* Favorites
* Preview
* Zoom
* Share
* Rename
* Delete
* Tags
* Attach to notes

---

# 21. Video

Internal video player:

* Play
* Pause
* Seek
* Fullscreen
* Playback speed
* Volume
* Continue watching
* Recently watched
* Favorite
* Attach to notes

---

# 22. Music and Audio

Music library:

```text
Recently Played
Favorites
Albums
Artists
Folders
Playlists
```

Features:

* Background playback
* Play/pause
* Next
* Previous
* Seek
* Repeat
* Shuffle
* Queue
* Favorites
* Recently played

Also support:

* Voice recording
* Audio notes

---

# 23. Tasks

Each task contains:

```text
Title
Description
Priority
Due Date
Due Time
Reminder
Repeat Rule
Category
Tags
Attachments
Related Note
Status
Created Date
Completed Date
```

Priority:

```text
Urgent
High
Medium
Low
```

Repeat:

```text
Daily
Weekly
Monthly
Yearly
Weekdays
Weekends
Custom
```

---

# 24. Alarms and Reminders

Support:

* One-time reminders
* Repeating reminders
* Multiple reminders
* Snooze
* Complete
* Skip occurrence
* Notification sound
* Vibration
* Notification actions

Reminder example:

```text
Study Flutter
Today
8:00 PM

Repeat:
Every Monday, Wednesday and Friday
```

---

# 25. Timetable

Support daily and weekly timetables.

Daily:

```text
08:00  Wake up
09:00  Study
11:00  Break
11:30  Project
14:00  Lunch
15:00  Work
18:00  Gym
20:00  Reading
```

Weekly:

```text
        MON      TUE      WED      THU      FRI

08:00   Study    Work     Study    Work     Study
10:00   Math     Project  Math     Project  Math
14:00   Work     Work     Work     Study    Work
18:00   Gym      ---      Gym      ---      Gym
```

Timetable events can connect to:

* Tasks
* Notes
* Reminders
* Files
* Calendar

---

# 26. Calendar

Views:

* Day
* 3-day
* Week
* Month

Calendar events can connect to:

* Tasks
* Notes
* Timetable
* Files
* Reminders

---

# 27. Global Search

Search everything:

```text
Search everything...
```

Search results:

```text
Notes
Documents
Images
Videos
Music
Tasks
Timetable
```

Filters:

```text
Type
Date
Folder
Tag
Favorite
Created
Modified
```

Future feature:

* OCR
* Search text inside images
* Search text inside PDFs

---

# 28. Private Vault

Optional local security feature.

Allow users to protect selected content with:

* PIN
* Password
* Biometrics

Vault can contain:

* Notes
* Images
* Videos
* Audio
* Documents
* Other files

No account is required.

---

# 29. Encryption

Sensitive local data can be encrypted.

Use established cryptographic libraries.

Do not make unsupported security claims such as:

> Military-grade encryption

unless the implementation has been professionally reviewed.

---

# 30. Backup

Because there is no account or cloud requirement, backup is essential.

Provide:

```text
Create Backup
Restore Backup
Export Everything
Import Backup
Automatic Local Backup
```

Example:

```text
backup/
├── database.sqlite
├── notes/
├── files/
├── media/
└── manifest.json
```

The user must always be able to export their data.

---

# 31. No Cloud Requirement

The application does not require:

* Cloud database
* Cloud authentication
* Cloud storage
* Cloud synchronization

Future cloud features may be considered, but they are NOT part of the initial application.

---

# 32. Database

Use Drift with SQLite.

Drift is a reactive, type-safe persistence library built on SQLite and supports transactions, migrations, joins and generated type-safe code.

Use:

```yaml
drift:
drift_flutter:
```

`drift_flutter` provides Flutter-specific database setup and stores the database locally on native platforms.

---

# 33. Database Tables

Initial:

```text
folders
notes
tags
note_tags
files
tasks
task_tags
reminders
timetable_events
calendar_events
playlists
playlist_items
media_history
settings
```

Additional:

```text
vault_items
backup_history
```

Advertisement settings:

```text
ad_settings
```

Possible fields:

```text
launch_count
last_ad_shown_at
ads_enabled
minimum_ad_interval
```

No user/account table should exist.

---

# 34. Recommended Flutter Packages

Core:

```yaml
drift:
drift_flutter:
path:
path_provider:
uuid:
```

Files:

```yaml
file_picker:
open_filex:
mime:
share_plus:
permission_handler:
```

Media:

```yaml
photo_manager:
video_player:
just_audio:
image_picker:
record:
```

Notifications:

```yaml
flutter_local_notifications:
timezone:
```

Network:

```yaml
connectivity_plus:
```

Security:

```yaml
cryptography:
cryptography_flutter:
```

Navigation:

```yaml
go_router:
```

Utilities:

```yaml
intl:
```

Ads:

```yaml
google_mobile_ads:
```

There is intentionally **no**:

```text
firebase_auth
google_sign_in
sign_in_with_apple
supabase_auth
in_app_purchase
subscription SDK
```

because this application does not have user accounts or subscriptions.

---

# 35. Project Structure

```text
lib/
│
├── core/
│   ├── database/
│   ├── storage/
│   ├── security/
│   ├── notifications/
│   ├── network/
│   ├── ads/
│   ├── permissions/
│   └── utilities/
│
├── features/
│   ├── dashboard/
│   ├── notes/
│   ├── files/
│   ├── tasks/
│   ├── reminders/
│   ├── timetable/
│   ├── calendar/
│   ├── media/
│   ├── search/
│   ├── backup/
│   ├── vault/
│   ├── settings/
│   └── statistics/
│
└── main.dart
```

---

# 36. Advertisement Architecture

```text
core/
└── ads/
    ├── app_open_ad_manager.dart
    ├── ad_config.dart
    └── ad_cooldown.dart
```

## AppOpenAdManager

Responsible for:

* Loading
* Showing
* Disposing
* Reloading
* Expiration
* Callbacks
* Preventing duplicate ads

## NetworkService

Responsible for:

* Connectivity check
* Internet reachability
* Timeout handling

## AdCooldown

Responsible for:

* Last ad time
* Minimum interval
* Launch count

---

# 37. Complete Startup Algorithm

```text
START APPLICATION

        ↓

Initialize local database

        ↓

Initialize local filesystem

        ↓

Load local settings

        ↓

Check launch count

        ↓

Check connectivity

        ↓

No network?
   │
   └── YES → Open Home

        ↓ NO

Check actual Internet access

        ↓

No Internet?
   │
   └── YES → Open Home

        ↓ YES

Has minimum launch count been reached?
   │
   └── NO → Open Home

        ↓ YES

Has advertisement cooldown expired?
   │
   └── NO → Open Home

        ↓ YES

Load App Open Ad

        ↓

Ad available?
   │
   ├── NO → Open Home
   │
   └── YES
          ↓
       Show Ad
          ↓
       Open Home
```

---

# 38. Application Resume

When the application returns from background:

```text
App resumed
    ↓
Check whether enough time has passed
    ↓
Check Internet
    ↓
Online?
 ├── NO → Continue
 └── YES
       ↓
    Load/prepare ad
       ↓
    Ad available?
     ├── NO → Continue
     └── YES → Show App Open Ad
```

Do not show an ad on every short resume.

---

# 39. Error Handling

The application must continue working if:

* Internet fails
* Advertisement fails
* Database temporarily fails
* File import fails
* File is unavailable
* Notification permission is denied
* Media cannot be opened
* Network times out
* Ad SDK fails

Always prioritize the user's local data and application access.

---

# 40. Privacy

The application should clearly communicate:

```text
No account required.
Your notes and files are stored locally.
Internet is not required for core functionality.
```

Advertising-related network communication is separate from the local data system.

Do not send the user's notes, files, images, videos or music to an external server merely to run the core application.

---

# 41. First Version / MVP

Do not build every advanced feature immediately.

MVP:

```text
Home
Notes
Folders
Files
Tasks
Reminders
Timetable
Search
Backup
Settings
App Open Ads
```

Then add:

```text
Image Gallery
Video Player
Music Player
Audio Recorder
Private Vault
Encryption
Calendar
Statistics
OCR
Widgets
```

---

# 42. Development Roadmap

## Phase 1 — Foundation

* Flutter project
* Theme
* Navigation
* Local database
* Local filesystem
* Settings

## Phase 2 — Notes

* Create
* Edit
* Delete
* Folders
* Tags
* Search
* Favorites

## Phase 3 — Files

* Import
* File browser
* Attachments
* Images
* Documents

## Phase 4 — Productivity

* Tasks
* Todo
* Reminders
* Notifications
* Timetable
* Calendar

## Phase 5 — Media

* Images
* Video
* Music
* Audio
* Playlists

## Phase 6 — Backup

* Export
* Import
* Restore
* Automatic local backup

## Phase 7 — Security

* App lock
* Private Vault
* Encryption
* Biometrics

## Phase 8 — Advertising

* Google Mobile Ads
* App Open Ads
* Internet detection
* Ad cooldown
* Startup ad flow
* Resume ad flow
* Test advertisements
* Production advertisements

---

# 43. Final Product Rules

These rules must not be broken:

```text
1. NO USER ACCOUNTS

2. NO LOGIN

3. NO REGISTRATION

4. NO SUBSCRIPTIONS

5. NO IN-APP PURCHASES

6. NO REQUIRED CLOUD

7. CORE FEATURES WORK OFFLINE

8. USER DATA IS STORED LOCALLY

9. INTERNET IS ONLY REQUIRED FOR ONLINE FEATURES

10. ADS ARE THE ONLY MONETIZATION METHOD

11. NO ADS WHEN OFFLINE

12. IF INTERNET EXISTS, APP OPEN ADS MAY BE SHOWN

13. IF AN AD FAILS, OPEN THE APP NORMALLY

14. NEVER BLOCK USER DATA BECAUSE OF ADS

15. NEVER PUT ADS INSIDE USER CONTENT

16. ALWAYS PROVIDE LOCAL BACKUP/EXPORT

17. USE TEST ADS DURING DEVELOPMENT

18. KEEP ADVERTISING CODE SEPARATE FROM DATA CODE
```

---

# 44. Product Positioning

The application should be presented as:

> **Your private digital workspace — no account required.**

Core concept:

```text
NO ACCOUNT
     +
OFFLINE FIRST
     +
NOTES
     +
FILES
     +
IMAGES
     +
VIDEOS
     +
MUSIC
     +
TASKS
     +
ALARMS
     +
TIMETABLE
     +
BACKUP
     +
FREE
     +
ADS ONLY WHEN ONLINE
```

The main promise:

> **Your data stays with you, even when the Internet doesn't.**

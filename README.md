<<<<<<< HEAD
# CheemHang

A social hangout coordination app that helps friends organize and manage their get-togethers, with a playful theme centered around the "Cheems" meme character.

## Key Features

- **Google Calendar Integration**: Smart scheduling that checks calendar availability
- **Multiple Personas**: Create different personas mapped to your real identity
- **Intelligent Scheduling**: Only suggest hangout times that work for both parties
- **Real-time Notifications**: Get alerts for hangout requests and updates

## Technical Details

- iOS 17+ app built with SwiftUI
- Firebase backend (Auth, Firestore, Storage)
- Google Sign-In for authentication
- Google Calendar API for availability checking
- MVVM architecture

## Project Structure

```
CheemHang/
├── App/                    (App entry point and configuration)
├── Authentication/         (Auth-related views and logic)
├── Models/                 (Data models and Firebase schemas)
├── Features/
│   ├── Profile/            (User profile views and management)
│   ├── Hangouts/           (Hangout creation and management)
│   ├── Friends/            (Friend list and management)
│   └── Notifications/      (Notification handling)
├── Services/               (Firebase and API services)
├── Utils/                  (Shared utilities and helpers)
└── Resources/              (Assets, fonts, etc.)
```

## Setup Instructions

1. Clone the repository
2. Run the setup script:
   ```bash
   ./setup.sh
   ```
3. Configure Firebase:
   - Add your `GoogleService-Info.plist` file to the project
   - Update the `GIDClientID` in `Info.plist` with your Google Client ID
   - Update the URL scheme in `Info.plist` with your Google Client ID

4. Build and run the project 
=======
# 0230_build
>>>>>>> 34e149abec90233f9a6f363d87f8a1331b600fd6

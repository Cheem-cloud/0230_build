# Unhinged

A daring dating app that embraces authenticity. Unhinged helps users connect with potential matches by showcasing their unfiltered, real personalities.

## Key Features

- **Multiple Personas**: Create different personas for different aspects of your personality
- **Persona Discovery**: Browse potential dates with a Tinder-like interface
- **Intelligent Matching**: Find matches based on compatible interests and availability
- **Calendar Integration**: Check Google Calendar availability and schedule dates
- **Authentic Connections**: Built for people who want genuine relationships

## Technical Details

- iOS 17+ app built with SwiftUI
- Firebase backend (Auth, Firestore, Storage)
- Google Sign-In for authentication
- Google Calendar API for availability checking
- MVVM architecture

## Project Structure

```
Unhinged/
├── App/                    (App entry point and configuration)
├── Authentication/         (Auth-related views and logic)
├── Models/                 (Data models and Firebase schemas)
├── Features/
│   ├── Profile/            (User profile and persona management)
│   ├── Personas/           (Date persona discovery)
│   ├── Hangouts/           (Date creation and management)
├── Services/               (Firebase and API services)
├── Utils/                  (Shared utilities and helpers)
└── Resources/              (Assets, fonts, etc.)
```

## Setup Instructions

### Prerequisites

- Xcode 15.0+
- iOS 17.0+ device or simulator
- Firebase account
- Google Cloud Platform account with Calendar API enabled

### Getting Started

1. Clone the repository

```bash
git clone https://github.com/username/Unhinged.git
cd Unhinged
```

2. Run the setup script:

```bash
chmod +x setup.sh
./setup.sh
```

3. Configure Firebase and Google Sign-In:
   - Follow the detailed instructions in the `GOOGLE_SETUP.md` file
   - This includes creating a Firebase project, enabling Google Sign-In, and setting up Calendar API access

4. Open the Xcode project and run:

```bash
open Unhinged.xcodeproj
```

5. Build and run the app on your device or simulator

## Usage

### First-time Setup

1. Sign in with Google (make sure to grant calendar permissions)
2. Create your personas in the Profile tab
3. Browse potential dates in the Date tab
4. Create hangouts by selecting a persona and available time

### Scheduling a Date

1. Browse potential dates in the Date tab
2. Tap the hangout button on a persona you'd like to meet
3. Select which of your personas will meet with the date's persona
4. Choose a date and time that works based on calendar availability
5. Fill in hangout details and confirm
6. The date will appear in your Hangouts tab and Google Calendar

## License

This project is licensed under the MIT License - see the LICENSE file for details.

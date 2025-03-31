# CheemHang

A social hangout coordination app designed specifically for couples. CheemHang helps partners schedule time together while acknowledging the different "personas" or modes of their relationship.

## Key Features

- **Multiple Personas**: Create different personas for different aspects of your personality
- **Partner Persona Discovery**: Browse your partner's personas with a Tinder-like interface
- **Intelligent Scheduling**: Only suggest hangout times that work for both parties
- **Calendar Integration**: Check Google Calendar availability and add events
- **Private & Secure**: Built for just two users - you and your partner

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
│   ├── Profile/            (User profile and persona management)
│   ├── Personas/           (Partner persona discovery)
│   ├── Hangouts/           (Hangout creation and management)
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
git clone https://github.com/username/CheemHang.git
cd CheemHang
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
open CheemHang.xcodeproj
```

5. Build and run the app on your device or simulator

## Usage

### First-time Setup

1. Sign in with Google (make sure to grant calendar permissions)
2. Create your personas in the Profile tab
3. Have your partner sign in and create their personas
4. Browse your partner's personas in the Partner tab
5. Create hangouts by selecting a persona and available time

### Scheduling a Hangout

1. Browse your partner's personas in the Partner tab
2. Tap the hangout button on a persona you'd like to meet
3. Select which of your personas will meet with your partner's persona
4. Choose a date and time that works based on calendar availability
5. Fill in hangout details and confirm
6. The hangout will appear in both users' Hangouts tab and Google Calendar

## License

This project is licensed under the MIT License - see the LICENSE file for details.

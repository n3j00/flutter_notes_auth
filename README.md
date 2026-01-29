## AUTHOR Nikodem Stach

**Student Project** - mobile application for notes management with strickted design 

## About

This Notes Application is a mobile app built with Flutter, enabling efficient note management.

 The design and functionality of this application were developed in strict accordance with the requirements specified for the course project. All features, UI elements, and architectural decisions were implemented to meet the exact specifications provided by the project assignment.

## Key Features

- **Authentication System** - secure user login and registration
- **Notes Management** - create, edit, and delete notes
- **Priorities** - organize notes by importance levels (High, Medium, Normal, Low)
- **Pin Notes** - access most important notes at the top of the list
- **Search** - quickly find notes by title or content
- **Image Attachments** - add photos to notes
- **User Profile** - personalization with options to change name, password, and profile picture

## Technologies

- **Flutter SDK** - cross-platform mobile app framework
- **Dart** - programming language
- **SQLite** - local database
- **Crypto** - password encryption (SHA-256)

## Getting Started

### Prerequisites

- Flutter SDK (3.10.7 or higher)
- Dart SDK
- Android Studio / Xcode (for mobile development)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd flutter_notes_auth
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run
```

## Project Structure

```
lib/
├── database/          # Database helper and data access layer
├── models/            # Data models (User, Note, NoteImage)
├── screens/           # UI screens
├── services/          # Business logic services
├── theme/             # App theme configuration
├── utils/             # Utility functions and constants
└── widgets/           # Reusable UI components
```

## License

This is a student project created for educational purposes.



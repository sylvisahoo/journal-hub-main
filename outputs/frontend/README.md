# Journal Hub Frontend

Flutter Frontend Client for **Journal Hub** - Personal Journal & Diary Application. Supports iOS, Android, and Web platforms.

## Table of Contents
- [Architecture](#architecture)
- [Folder Structure](#folder-structure)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Dependencies](#dependencies)
- [Running the App](#running-the-app)
- [Running Tests](#running-tests)

---

## Architecture

This project is organized using a clean, feature-layered component architecture:

- **Config Layer (`lib/src/config/`)**: Contains app routing (`router.dart`), visual design tokens, color palette, and light/dark theme schemes (`theme.dart`).
- **Core Layer (`lib/src/core/`)**: Houses platform utils, local caches, and the generic HTTP client (`api_client.dart`) powered by Dio.
- **Features Layer (`lib/src/features/`)**: Contains modular domain logic and presentation widgets (e.g. Auth, Journals, Analytics).

---

## Folder Structure

```text
outputs/frontend/
├── lib/
│   ├── src/
│   │   ├── config/          # Routes, themes, constants
│   │   │   ├── router.dart
│   │   │   └── theme.dart
│   │   ├── core/            # Network clients, models, utilities
│   │   │   └── network/
│   │   │       └── api_client.dart
│   │   ├── features/        # Feature modules
│   │   └── app.dart         # Root Material App Widget
│   └── main.dart            # Application entry point
├── test/
│   └── widget_test.dart     # Smoke and navigation tests
├── pubspec.yaml             # Flutter dependencies list
└── README.md                # Project documentation guide
```

---

## Prerequisites

- **Flutter SDK**: `^3.41.0`
- **Dart SDK**: `^3.11.0`

---

## Getting Started

1. Navigate to the frontend directory:
   ```bash
   cd outputs/frontend
   ```

2. Download package dependencies:
   ```bash
   flutter pub get
   ```

3. Run static analyzer check:
   ```bash
   flutter analyze
   ```

4. Launch the application:
   ```bash
   flutter run
   ```

---

## Dependencies

The following key packages are pre-configured:
- `go_router` - Declarative routing and URL deep-linking support.
- `flutter_riverpod` - Safe, testable state management.
- `dio` - Feature-rich HTTP networking client with custom interceptor logic.
- `shared_preferences` - Secure local cache key-value store.
- `flutter_quill` - Rich-text document formatting and content editing.
- `table_calendar` - Highly customizable calendar widgets.
- `connectivity_plus` - Dynamic internet connectivity detection.
- `pdf` & `printing` - Document generation and print layouts.

---

## Running the App

Run on standard connected device or emulator:
```bash
flutter run
```

To run specifically on Web (Chrome):
```bash
flutter run -d chrome
```

---

## Running Tests

Execute unit and widget tests:
```bash
flutter test
```

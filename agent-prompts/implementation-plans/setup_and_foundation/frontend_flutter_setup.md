# Implementation Plan - Frontend Flutter Setup

Initialize the Flutter frontend development workspace for **Journal Hub** under [outputs/frontend](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend) and set up the foundation of the project.

## User Review Required

> [!NOTE]
> The Flutter application will be initialized directly in [outputs/frontend](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend) (making it the root of the frontend).
> 
> The project will use **Riverpod** for state management and **GoRouter** for routing. **Dio** will be set up as the HTTP client, configured to point to `http://localhost:5001/api/v1` by default (matching the backend port).

---

## Proposed Changes

### [Frontend Setup]

We will initialize the Flutter project and configure the initial source files under [outputs/frontend](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend).

#### [NEW] [outputs/frontend](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend)
Initialize the project structure using:
```bash
flutter create --org com.journalhub --project-name journal_app --platforms=android,ios,web .
```

#### [MODIFY] [pubspec.yaml](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/pubspec.yaml)
Add dependencies required for the project:
- Routing: `go_router`
- State Management: `flutter_riverpod`
- Networking: `dio`
- Storage: `shared_preferences`
- Rich Text Editor: `flutter_quill`
- Calendar: `table_calendar`
- Connectivity: `connectivity_plus`
- Exports: `pdf`, `printing`

#### [NEW] [main.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/main.dart)
Initialize the application entry point. Wraps the root widget in a `ProviderScope` to enable Riverpod state management.

#### [NEW] [app.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/app.dart)
Root Material Application widget. Configures themes and injects the GoRouter instance.

#### [NEW] [router.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/config/router.dart)
Define base application routes using GoRouter:
- `/` (Home/Dashboard Screen placeholder)
- `/login` (Login Screen placeholder)

#### [NEW] [theme.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/config/theme.dart)
Define the UI Design System, color palettes (Harmonious Teal/Indigo accents), typography (using modern style guidelines), and button styles.

#### [NEW] [api_client.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/core/network/api_client.dart)
Configure a generic Dio client:
- Configures default `baseUrl` (read from environment/constants)
- Configures interceptors to add Authorization header dynamically from local storage
- Standardizes network exceptions mapping to application-level failures.

#### [NEW] [widget_test.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/test/widget_test.dart)
Baseline widget tests verifying that the root app widget mounts and navigates to the login screen or homepage correctly.

#### [NEW] [README.md](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/README.md)
Guidelines on how to configure, run, and test the Flutter application on Mobile and Web.

---

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure zero compilation or styling warnings.
- Run `flutter test` to verify the baseline widget tests execute successfully.

### Manual Verification
- Launch the application locally on Chrome/Web (`flutter run -d chrome`) to verify the basic routing, styling, and base UI layout render correctly.

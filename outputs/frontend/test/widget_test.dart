import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:journal_app/src/app.dart';
import 'package:journal_app/src/config/router.dart';
import 'package:journal_app/src/core/models/models.dart';
import 'package:journal_app/src/core/network/api_client.dart';
import 'package:journal_app/src/core/repositories/auth_repository.dart';
import 'package:journal_app/src/core/repositories/mock_repositories.dart';
import 'package:journal_app/src/core/providers/providers.dart';

class TestAuthRepository extends AuthRepository {
  TestAuthRepository() : super(ApiClient());

  @override
  Future<User?> getCurrentUser() async {
    return null;
  }

  @override
  Future<User> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (email == 'verified@example.com' && password == 'Password123!') {
      return User(
        userId: 'user-1',
        fullName: 'Jane Doe',
        email: email,
        accountStatus: 'Verified',
      );
    }
    throw Exception('INVALID_CREDENTIALS');
  }

  @override
  Future<User> register(String fullName, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return User(
      userId: 'user-new-test',
      fullName: fullName,
      email: email,
      accountStatus: 'Pending',
    );
  }

  @override
  Future<void> verifyEmail(String token) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<void> forgotPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (email != 'verified@example.com') {
      throw Exception('INVALID_EMAIL');
    }
  }

  @override
  Future<void> resetPassword(String token, String newPassword) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (token != '123456') {
      throw Exception('INVALID_TOKEN');
    }
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('App login flow and dashboard rendering smoke test', (WidgetTester tester) async {
    // Build our app under ProviderScope and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(TestAuthRepository()),
          journalRepositoryProvider.overrideWithValue(MockJournalRepository()),
          analyticsRepositoryProvider.overrideWithValue(MockAnalyticsRepository()),
        ],
        child: const JournalApp(),
      ),
    );

    // Reset GoRouter location to /login to ensure test isolation
    goRouter.go('/login');
    await tester.pumpAndSettle();

    // Verify that the login screen is rendered
    expect(find.text('Access your private digital journal'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);

    // Find email and password inputs
    final textFields = find.byType(TextField);
    expect(textFields, findsNWidgets(2));

    // Input credentials
    await tester.enterText(textFields.at(0), 'verified@example.com');
    await tester.enterText(textFields.at(1), 'Password123!');
    await tester.pumpAndSettle();

    // Tap the 'Login' button
    await tester.tap(find.text('Login'));
    
    // Settle for the simulated network latency (600ms)
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Verify we navigated to the dashboard and see the welcome message
    expect(find.textContaining('Hello, Jane Doe'), findsOneWidget);
    expect(find.text('Capture your thoughts and track your journey.'), findsOneWidget);
    expect(find.text('Writing Streak'), findsOneWidget);
  });

  testWidgets('App signup flow and verification redirect test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(TestAuthRepository()),
          journalRepositoryProvider.overrideWithValue(MockJournalRepository()),
          analyticsRepositoryProvider.overrideWithValue(MockAnalyticsRepository()),
        ],
        child: const JournalApp(),
      ),
    );
    
    // Reset GoRouter location to /login to ensure test isolation
    goRouter.go('/login');
    await tester.pumpAndSettle();

    // Navigate to registration
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    // Verify Register screen is displayed
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Begin journaling securely today'), findsOneWidget);

    final textFields = find.byType(TextField);
    // Name, Email, Password, Confirm Password -> 4 TextFields
    expect(textFields, findsNWidgets(4));

    await tester.enterText(textFields.at(0), 'Alice Smith');
    await tester.enterText(textFields.at(1), 'alice@example.com');
    await tester.enterText(textFields.at(2), 'Password123!');
    await tester.enterText(textFields.at(3), 'Password123!');
    await tester.pumpAndSettle();

    // Tap 'Sign Up' button
    await tester.tap(find.text('Sign Up'));

    // Settle for register latency (100ms)
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    // Verify the verification dialog is displayed
    expect(find.text('Verify Your Email'), findsOneWidget);
    expect(find.textContaining('We have sent a verification code to alice@example.com.'), findsOneWidget);

    // Find token textfield and enter code
    final dialogTextField = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
    expect(dialogTextField, findsOneWidget);
    await tester.enterText(dialogTextField, 'token123');
    await tester.pumpAndSettle();

    // Tap "Verify"
    await tester.tap(find.text('Verify'));

    // Settle for verify latency (100ms)
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    // Verify we navigated back to Login screen and see the success SnackBar
    expect(find.text('Access your private digital journal'), findsOneWidget);
    expect(find.text('Email verified successfully! You can now log in.'), findsOneWidget);
  });

  testWidgets('Settings screen add category test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(TestAuthRepository()),
          journalRepositoryProvider.overrideWithValue(MockJournalRepository()),
          analyticsRepositoryProvider.overrideWithValue(MockAnalyticsRepository()),
        ],
        child: const JournalApp(),
      ),
    );

    // Reset GoRouter location to /settings
    goRouter.go('/settings');
    await tester.pumpAndSettle();

    // Verify Settings screen is displayed
    expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
    expect(find.text('Manage Categories'), findsOneWidget);

    // Verify initial categories are displayed
    expect(find.text('Personal'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);

    // Tap "Add" category button
    await tester.tap(find.widgetWithText(TextButton, 'Add').first);
    await tester.pumpAndSettle();

    // Enter category name
    await tester.enterText(find.byType(TextField), 'Health & Fitness');
    await tester.pumpAndSettle();

    // Tap "Create"
    await tester.tap(find.text('Create'));
    
    // Settle for the 200ms repo delay
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Verify the new category is displayed
    expect(find.text('Health & Fitness'), findsOneWidget);

    // Test deleting a category
    final workListTile = find.widgetWithText(ListTile, 'Work');
    await tester.ensureVisible(workListTile);
    final deleteCategoryButton = find.descendant(
      of: workListTile,
      matching: find.byType(IconButton),
    );
    await tester.tap(deleteCategoryButton);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Work'), findsNothing);

    // Test adding a tag
    final addTagButton = find.widgetWithText(TextButton, 'Add').last;
    await tester.ensureVisible(addTagButton);
    await tester.tap(addTagButton);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'mindfulness');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('#mindfulness'), findsOneWidget);

    // Test deleting a tag
    final gratefulChip = find.widgetWithText(Chip, '#grateful');
    await tester.ensureVisible(gratefulChip);
    final deleteTagButton = find.descendant(
      of: gratefulChip,
      matching: find.byType(Icon),
    );
    await tester.tap(deleteTagButton);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('#grateful'), findsNothing);
  });

  testWidgets('Journal entries search and filtering test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(TestAuthRepository()),
          journalRepositoryProvider.overrideWithValue(MockJournalRepository()),
          analyticsRepositoryProvider.overrideWithValue(MockAnalyticsRepository()),
        ],
        child: const JournalApp(),
      ),
    );

    // Reset GoRouter location to /journals
    goRouter.go('/journals');
    await tester.pumpAndSettle();

    // Verify initially loaded entries from MockJournalRepository
    expect(find.text('A beautiful weekend getaway'), findsOneWidget);
    expect(find.text('Stitch UI Screens Integration'), findsOneWidget);

    // Search for "weekend" keyword
    await tester.enterText(find.byType(TextField).first, 'weekend');
    await tester.pumpAndSettle();
    
    // Settle for mock delay
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();

    // Verify filtered entries
    expect(find.text('A beautiful weekend getaway'), findsOneWidget);
    expect(find.text('Stitch UI Screens Integration'), findsNothing);

    // Clear Search
    await tester.tap(find.byIcon(Icons.clear_rounded));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();

    // Verify it is restored
    expect(find.text('A beautiful weekend getaway'), findsOneWidget);
    expect(find.text('Stitch UI Screens Integration'), findsOneWidget);
  });

  testWidgets('Calendar screen rendering and highlights test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(TestAuthRepository()),
          journalRepositoryProvider.overrideWithValue(MockJournalRepository()),
          analyticsRepositoryProvider.overrideWithValue(MockAnalyticsRepository()),
        ],
        child: const JournalApp(),
      ),
    );

    // Reset GoRouter location to /calendar
    goRouter.go('/calendar');
    await tester.pumpAndSettle();

    // Verify Calendar screen is displayed
    expect(find.widgetWithText(AppBar, 'Calendar View'), findsOneWidget);
    expect(find.byWidgetPredicate((widget) => widget is TableCalendar), findsOneWidget);
    
    // Settle calendar highlighting and entries fetching
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  });
}

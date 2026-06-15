import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/auth_screens.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/dashboard/presentation/main_shell.dart';
import '../features/journal/presentation/calendar_screen.dart';
import '../features/journal/presentation/editor_screen.dart';
import '../features/journal/presentation/entries_screen.dart';
import '../features/journal/presentation/entry_details_screen.dart';
import '../features/analytics/presentation/analytics_screen.dart';
import '../features/export/presentation/export_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

final goRouter = GoRouter(
  initialLocation: '/login', // Start at login for security/session check flow
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return MainNavigationShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/journals',
          builder: (context, state) => const EntriesScreen(),
        ),
        GoRoute(
          path: '/journals/create',
          builder: (context, state) {
            final prompt = state.uri.queryParameters['prompt'];
            return EditorScreen(initialPrompt: prompt);
          },
        ),
        GoRoute(
          path: '/journals/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return EntryDetailsScreen(entryId: id);
          },
        ),
        GoRoute(
          path: '/journals/:id/edit',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return EditorScreen(entryId: id);
          },
        ),
        GoRoute(
          path: '/calendar',
          builder: (context, state) => const CalendarScreen(),
        ),
        GoRoute(
          path: '/analytics',
          builder: (context, state) => const AnalyticsScreen(),
        ),
        GoRoute(
          path: '/export',
          builder: (context, state) => const ExportScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);

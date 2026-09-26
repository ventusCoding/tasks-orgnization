import 'package:everslot/app/shell_scaffold.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/auth/presentation/sign_in_screen.dart';
import 'package:everslot/features/checklists/presentation/checklist_screen.dart';
import 'package:everslot/features/checklists/presentation/lists_board_screen.dart';
import 'package:everslot/features/checklists/presentation/smart_list_screen.dart';
import 'package:everslot/features/dev/presentation/debug_menu_screen.dart';
import 'package:everslot/features/habits/presentation/habit_detail_screen.dart';
import 'package:everslot/features/habits/presentation/habit_editor_screen.dart';
import 'package:everslot/features/habits/presentation/habits_screen.dart';
import 'package:everslot/features/habits/presentation/quit_dashboard_screen.dart';
import 'package:everslot/features/notifications/presentation/inbox_screen.dart';
import 'package:everslot/features/onboarding/presentation/onboarding_screen.dart';
import 'package:everslot/features/organization/presentation/categories_screen.dart';
import 'package:everslot/features/organization/presentation/tags_screen.dart';
import 'package:everslot/features/planner/presentation/planner_screen.dart';
import 'package:everslot/features/planner/presentation/task_detail_screen.dart';
import 'package:everslot/features/planner/presentation/task_editor_screen.dart';
import 'package:everslot/features/search/presentation/search_screen.dart';
import 'package:everslot/features/settings/presentation/settings_page_screen.dart';
import 'package:everslot/features/settings/presentation/settings_screen.dart';
import 'package:everslot/features/settings/presentation/trash_screen.dart';
import 'package:everslot/features/stats/presentation/insights_screen.dart';
import 'package:everslot/features/stats/presentation/scope_stats_screen.dart';
import 'package:everslot/features/today/presentation/today_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Routes (arch §6.4, T1.3.06). Tabs keep their own stacks; editors/details open above the shell.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(sessionProvider, (_, _) => refresh.value++)
    ..onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppLinks.today(),
    refreshListenable: refresh,
    redirect: (context, state) {
      final env = ref.read(envProvider);
      final session = ref.read(sessionProvider);
      final atAuth = state.matchedLocation.startsWith('/auth');
      if (env.isSupabaseConfigured && session == null) {
        return atAuth ? null : AppLinks.signIn();
      }
      if (session != null && atAuth) return AppLinks.today();
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(),
      body: EmptyState(icon: Icons.link_off, title: context.l10n.notFoundTitle),
    ),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ShellScaffold(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/today', builder: (_, _) => const TodayScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/plan',
                builder: (_, s) => PlannerScreen(date: s.uri.queryParameters['date']),
                routes: [
                  GoRoute(
                    path: 'week',
                    builder: (_, s) => PlannerScreen(date: s.uri.queryParameters['date']),
                  ),
                  GoRoute(
                    path: 'day',
                    builder: (_, s) =>
                        PlannerScreen(view: 'day_list', date: s.uri.queryParameters['date']),
                  ),
                  GoRoute(
                    path: 'view/:type',
                    builder: (_, s) => PlannerScreen(
                      view: s.pathParameters['type']!,
                      date: s.uri.queryParameters['date'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/lists', builder: (_, _) => const ListsBoardScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/habits', builder: (_, _) => const HabitsScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/insights', builder: (_, _) => const InsightsScreen())],
          ),
        ],
      ),
      // ---- Planner
      GoRoute(
        path: '/task-new',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, s) => MaterialPage(
          fullscreenDialog: true,
          child: TaskEditorScreen(
            initialStart: s.uri.queryParameters['start'],
            initialDurationMinutes: int.tryParse(s.uri.queryParameters['duration'] ?? ''),
            allDay: s.uri.queryParameters['allDay'] == '1',
          ),
        ),
      ),
      GoRoute(
        path: '/task/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, s) => TaskDetailScreen(
          taskId: s.pathParameters['id']!,
          occurrenceKey: s.uri.queryParameters['occ'],
        ),
        routes: [
          GoRoute(
            path: 'edit',
            parentNavigatorKey: rootNavigatorKey,
            pageBuilder: (_, s) => MaterialPage(
              fullscreenDialog: true,
              child: TaskEditorScreen(taskId: s.pathParameters['id']),
            ),
          ),
        ],
      ),
      // ---- Checklists
      GoRoute(
        path: '/lists/smart/:kind',
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, s) => SmartListScreen(kind: s.pathParameters['kind']!),
      ),
      GoRoute(
        path: '/lists/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, s) => ChecklistScreen(
          checklistId: s.pathParameters['id']!,
          focusItemId: s.uri.queryParameters['item'],
          preview: s.uri.queryParameters['mode'] == 'preview',
        ),
      ),
      // ---- Habits
      GoRoute(
        path: '/habit-new',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, s) => MaterialPage(
          fullscreenDialog: true,
          child: HabitEditorScreen(kind: s.uri.queryParameters['kind'] ?? 'build'),
        ),
      ),
      GoRoute(
        path: '/habits/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, s) => HabitDetailScreen(habitId: s.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'edit',
            parentNavigatorKey: rootNavigatorKey,
            pageBuilder: (_, s) => MaterialPage(
              fullscreenDialog: true,
              child: HabitEditorScreen(habitId: s.pathParameters['id']),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/quit/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, s) => QuitDashboardScreen(habitId: s.pathParameters['id']!),
      ),
      // ---- Insights
      GoRoute(
        path: '/insights/:scope',
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, s) => ScopeStatsScreen(scope: s.pathParameters['scope']!),
        routes: [
          GoRoute(
            path: ':id',
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, s) =>
                ScopeStatsScreen(scope: s.pathParameters['scope']!, scopeId: s.pathParameters['id']),
          ),
        ],
      ),
      // ---- Cross-cutting
      GoRoute(
        path: '/inbox',
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, _) => const InboxScreen(),
      ),
      GoRoute(
        path: '/search',
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, s) => SearchScreen(initialQuery: s.uri.queryParameters['q']),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, _) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'trash',
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, _) => const TrashScreen(),
          ),
          GoRoute(
            path: 'categories',
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, _) => const CategoriesScreen(),
          ),
          GoRoute(
            path: 'tags',
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, _) => const TagsScreen(),
          ),
          GoRoute(
            path: ':page',
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, s) => SettingsPageScreen(page: s.pathParameters['page']!),
          ),
        ],
      ),
      GoRoute(path: '/auth/sign-in', builder: (_, _) => const SignInScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(
        path: '/dev',
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, _) => const DebugMenuScreen(),
      ),
    ],
  );
});

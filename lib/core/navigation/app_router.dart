import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:forma/core/navigation/bottom_nav_bar.dart';
import 'package:forma/features/authentication/screens/splash_screen.dart';
import 'package:forma/features/authentication/screens/welcome_screen.dart';
import 'package:forma/features/authentication/screens/login_screen.dart';
import 'package:forma/features/authentication/screens/onboarding_flow_screen.dart';
import 'package:forma/features/profile/screens/developer_setup_diagnostics_screen.dart';
import 'package:forma/features/home/screens/home_screen.dart';
import 'package:forma/features/workout/screens/workout_screen.dart';
import 'package:forma/features/workout/screens/workout_execution_screen.dart';
import 'package:forma/features/workout/screens/manual_workout_log_screen.dart';
import 'package:forma/features/workout/screens/exercise_detail_screen.dart';
import 'package:forma/data/models/exercise_model.dart';
import 'package:forma/features/nutrition/screens/nutrition_screen.dart';
import 'package:forma/features/habits/screens/habits_screen.dart';
import 'package:forma/features/profile/screens/profile_screen.dart';
import 'package:forma/features/trainer/screens/personal_trainer_screen.dart';
import 'package:forma/features/profile/screens/notification_settings_screen.dart';
import 'package:forma/features/profile/screens/user_api_key_settings_screen.dart';
import 'package:forma/features/friends/screens/friends_screen.dart';
import 'package:forma/data/models/workout_model.dart';
import 'package:forma/features/profile/screens/thanks_credits_screen.dart';
import 'package:forma/features/profile/screens/health_connect_settings_screen.dart';
import 'package:forma/features/profile/screens/account_connections_screen.dart';
import 'package:forma/features/profile/screens/security_settings_screen.dart';
import 'package:forma/features/authentication/screens/email_action_handler_screen.dart';
import 'package:forma/features/profile/screens/avatar_picker_screen.dart';
import 'package:forma/data/models/expense_model.dart';
import 'package:forma/features/expenses/screens/personal_expenses_screen.dart';
import 'package:forma/features/expenses/screens/add_personal_expense_screen.dart';
import 'package:forma/features/expenses/screens/expense_history_screen.dart';
import 'package:forma/features/expenses/screens/expense_detail_screen.dart';
import 'package:forma/features/expenses/screens/shared_expenses_screen.dart';
import 'package:forma/features/expenses/screens/add_shared_expense_screen.dart';
import 'package:forma/features/expenses/screens/shared_expense_detail_screen.dart';
import 'package:forma/features/expenses/screens/settlement_details_screen.dart';
import 'package:forma/features/expenses/screens/settle_up_screen.dart';
import 'package:forma/core/legal/terms_and_conditions_screen.dart';
import 'package:forma/features/body/screens/body_activity_screen.dart';
import 'package:forma/features/body/screens/body_settings_screen.dart';
import 'package:forma/features/workout/screens/weekly_muscle_overview_screen.dart';
import 'package:forma/features/workout/screens/log_muscle_groups_screen.dart';
import 'package:forma/features/workout/screens/weekly_muscle_plan_screen.dart';
import 'package:forma/features/calendar/screens/activity_calendar_screen.dart';
import 'package:forma/features/home/screens/customize_home_screen.dart';
import 'package:forma/features/search/screens/global_search_screen.dart';
import 'package:forma/features/expenses/screens/spending_insights_screen.dart';
import 'package:forma/features/reports/screens/weekly_report_screen.dart';

// ─── Route path constants ───────────────────────────────────────
class AppRoutes {
  const AppRoutes._();

  // Splash / Onboarding
  static const String splash = '/splash';
  static const String welcome = '/welcome';

  // Main shell tabs
  static const String home = '/home';
  static const String workout = '/workout';
  static const String nutrition = '/nutrition';
  static const String habits = '/habits';
  static const String expenses = '/expenses';
  static const String profile = '/profile';
  static const String trainer = '/trainer';
  static const String friends = '/friends';
  static const String notificationSettings = '/notification-settings';
  static const String userApiKeySettings = '/user-api-key-settings';
  static const String securitySettings = '/profile/security-settings';
  static const String authAction = '/auth/action';
  static const String activityCalendar = '/activity-calendar';
  static const String customizeHome = '/customize-home';
  static const String search = '/search';
  static const String spendingInsights = '/expenses/insights';
  static const String weeklyReport = '/weekly-report';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _workoutNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'workout');
final _nutritionNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'nutrition');
final _habitsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'habits');
final _expensesNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'expenses');

Page<dynamic> _buildPageWithTransition({
  LocalKey? key,
  required Widget child,
}) {
  return CustomTransitionPage<dynamic>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      final secondaryCurved = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      // Incoming screen slides in smoothly from right to left
      final slideIn = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(curved);

      // Outgoing screen moves back slightly with a 20% parallax shift
      final slideOut = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.20, 0.0),
      ).animate(secondaryCurved);

      return SlideTransition(
        position: slideOut,
        child: SlideTransition(
          position: slideIn,
          child: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 20,
                  offset: const Offset(-4, 0),
                ),
              ],
            ),
            child: child,
          ),
        ),
      );
    },
  );
}

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.welcome,
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const WelcomeScreen(),
      ),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const LoginScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding-flow',
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const OnboardingFlowScreen(),
      ),
    ),
    GoRoute(
      path: '/developer-diagnostics',
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const DeveloperSetupDiagnosticsScreen(),
      ),
    ),
    GoRoute(
      path: '/profile/diagnostics',
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const DeveloperSetupDiagnosticsScreen(),
      ),
    ),
    GoRoute(
      path: '/profile/api-key',
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const UserApiKeySettingsScreen(),
      ),
    ),
    // In-App Email Action Handler (verifyEmail, resetPassword, recoverEmail)
    GoRoute(
      path: AppRoutes.authAction,
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: EmailActionHandlerScreen(
          mode: state.uri.queryParameters['mode'],
          oobCode: state.uri.queryParameters['oobCode'],
          continueUrl: state.uri.queryParameters['continueUrl'],
        ),
      ),
    ),
    GoRoute(
      path: '/auth',
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: EmailActionHandlerScreen(
          mode: state.uri.queryParameters['mode'],
          oobCode: state.uri.queryParameters['oobCode'],
          continueUrl: state.uri.queryParameters['continueUrl'],
        ),
      ),
    ),
    // Account Security & Biometrics Screen
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.securitySettings,
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const SecuritySettingsScreen(),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/security-settings',
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const SecuritySettingsScreen(),
      ),
    ),
    // Modal Execution Screen
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/workout/execution',
      pageBuilder: (context, state) {
        final workout = state.extra as WorkoutModel;
        return _buildPageWithTransition(
          key: state.pageKey,
          child: WorkoutExecutionScreen(workout: workout),
        );
      },
    ),
    // Manual Workout Logging Screen (Post-Gym Entry)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/workout/manual-log',
      pageBuilder: (context, state) {
        final workout =
            state.extra is WorkoutModel ? state.extra as WorkoutModel : null;
        final exercise =
            state.extra is ExerciseModel ? state.extra as ExerciseModel : null;
        return _buildPageWithTransition(
          key: state.pageKey,
          child: ManualWorkoutLogScreen(
              initialWorkout: workout, initialExercise: exercise),
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/workout/builder',
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const ManualWorkoutLogScreen(),
      ),
    ),
    // Connected Shared-Element Exercise Detail Screen
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/workout/exercise/:id',
      pageBuilder: (context, state) {
        final exercise = state.extra as ExerciseModel;
        return _buildPageWithTransition(
          key: state.pageKey,
          child: ExerciseDetailScreen(exercise: exercise),
        );
      },
    ),
    // Dedicated Personal Trainer Screen with Smooth Shared Page Transition
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.trainer,
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const PersonalTrainerScreen(),
      ),
    ),
    // Android Notification Settings Screen
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.notificationSettings,
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const NotificationSettingsScreen(),
      ),
    ),
    // Friends & Private Group Management Screen
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.friends,
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const FriendsScreen(),
      ),
    ),
    // User's Personal Gemini API Key Settings Screen
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.userApiKeySettings,
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const UserApiKeySettingsScreen(),
      ),
    ),
    // Thanks & Developer Credits Screen
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/thanks-credits',
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const ThanksCreditsScreen(),
      ),
    ),
    // Google Health Connect Settings Screen
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/health-connect-settings',
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const HealthConnectSettingsScreen(),
      ),
    ),
    // Account Connections & Firebase Linking Screen
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/account-connections',
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const AccountConnectionsScreen(),
      ),
    ),
    // Activity Calendar Screen
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.activityCalendar,
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const ActivityCalendarScreen(),
      ),
    ),
    // Customize Home Screen
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.customizeHome,
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const CustomizeHomeScreen(),
      ),
    ),
    // Global Search Screen
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.search,
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const GlobalSearchScreen(),
      ),
    ),
    // Smart Spending Insights Screen
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.spendingInsights,
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const SpendingInsightsScreen(),
      ),
    ),
    // Weekly Intelligence Report Screen
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.weeklyReport,
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const WeeklyReportScreen(),
      ),
    ),

    // ── Personal Expense Tracker Routes ──
    // Dedicated Full-Page Profile Screen (Accessible via 1-tap from Expenses header & Home)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.profile,
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const ProfileScreen(),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/profile/avatar',
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const AvatarPickerScreen(),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/expenses/add',
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: AddPersonalExpenseScreen(
          existingExpense: state.extra as PersonalExpense?,
        ),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/expenses/history',
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const ExpenseHistoryScreen(),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/expenses/detail',
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: ExpenseDetailScreen(
          expense: state.extra as PersonalExpense,
        ),
      ),
    ),

    // ── Shared Expenses & Settlements Routes ──
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/shared-expenses',
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const SharedExpensesScreen(),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/shared-expenses/add',
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const AddSharedExpenseScreen(),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/shared-expenses/detail',
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: SharedExpenseDetailScreen(
          expense: state.extra as SharedExpense,
        ),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/shared-expenses/settlements',
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: SettlementDetailsScreen(
          balance: state.extra as ParticipantBalance,
        ),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/shared-expenses/settle-up',
      pageBuilder: (context, state) {
        return _buildPageWithTransition(
          key: state.pageKey,
          child: SettleUpScreen(
            targetBalance: state.extra as ParticipantBalance?,
          ),
        );
      },
    ),

    // ── Body & Muscle Tracker Routes ──
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/workout/body-visualization',
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const BodyActivityScreen(),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/profile/body-settings',
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const BodySettingsScreen(),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/workout/muscle-overview',
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const WeeklyMuscleOverviewScreen(),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/workout/muscle-log',
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: LogMuscleGroupsScreen(
          initialDate: state.extra as DateTime?,
        ),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/workout/muscle-plan',
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const WeeklyMusclePlanScreen(),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/terms-and-conditions',
      pageBuilder: (context, state) => _buildPageWithTransition(
        child: const TermsAndConditionsScreen(),
      ),
    ),

    // ────────── Main App Shell ──────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return FormaShellScaffold(navigationShell: navigationShell);
      },
      branches: [
        // Home
        StatefulShellBranch(
          navigatorKey: _homeNavigatorKey,
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        // Workout
        StatefulShellBranch(
          navigatorKey: _workoutNavigatorKey,
          routes: [
            GoRoute(
              path: AppRoutes.workout,
              builder: (context, state) => const WorkoutScreen(),
            ),
          ],
        ),
        // Nutrition
        StatefulShellBranch(
          navigatorKey: _nutritionNavigatorKey,
          routes: [
            GoRoute(
              path: AppRoutes.nutrition,
              builder: (context, state) => const NutritionScreen(),
            ),
          ],
        ),
        // Habits
        StatefulShellBranch(
          navigatorKey: _habitsNavigatorKey,
          routes: [
            GoRoute(
              path: AppRoutes.habits,
              builder: (context, state) => const HabitsScreen(),
            ),
          ],
        ),
        // Expenses (Tab 5)
        StatefulShellBranch(
          navigatorKey: _expensesNavigatorKey,
          routes: [
            GoRoute(
              path: AppRoutes.expenses,
              builder: (context, state) => const PersonalExpensesScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

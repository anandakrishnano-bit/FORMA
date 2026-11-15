import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:forma/core/components/asymmetric_feature_hero.dart';
import 'package:forma/core/components/calendar_widget.dart';
import 'package:forma/core/components/horizontal_card_carousel.dart';
import 'package:forma/core/components/habit_card.dart';
import 'package:forma/core/components/section_header.dart';
import 'package:forma/core/components/forma_bounceable.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/core/services/local_workout_recovery_service.dart';
import 'package:forma/core/services/home_widget_service.dart';
import 'package:forma/core/services/app_icon_service.dart';
import 'package:forma/data/repositories/friends_group_repository.dart';
import 'package:forma/data/repositories/habit_repository.dart';
import 'package:forma/data/repositories/workout_repository.dart';
import 'package:forma/data/repositories/nutrition_repository.dart';
import 'package:forma/core/components/hydration_log_modal.dart';
import 'package:forma/data/repositories/daily_summary_repository.dart';
import 'package:forma/data/repositories/hydration_repository.dart';
import 'package:forma/data/repositories/expense_repository.dart';
import 'package:forma/data/models/expense_model.dart';
import 'package:forma/features/home/widgets/daily_summary_card.dart';
import 'package:forma/core/components/forma_logo.dart';
import 'package:forma/core/components/forma_avatar.dart';
import 'package:forma/features/authentication/providers/auth_providers.dart';
import 'package:forma/core/services/daily_summary_service.dart';
import 'package:forma/features/home/widgets/daily_energy_rings_widget.dart';
import 'package:forma/features/home/widgets/compact_weekly_muscle_widget.dart';
import 'package:forma/features/home/repositories/home_customization_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:forma/core/legal/terms_data.dart';
import 'package:forma/core/updates/models/update_check_result.dart';
import 'package:forma/core/updates/services/app_update_manager.dart';
import 'package:forma/core/updates/widgets/forma_update_screen.dart';

/// Inspiring Home Screen (Reference Image 2 Fidelity)
///
/// Composition:
/// 1. Editorial Header: Warm, uncluttered greeting with profile circular node.
/// 2. Quick Access Toolbar: Global Search, Activity Calendar, Weekly Report, Customize Layout.
/// 3. Signature Date Selector: Horizontal Mon-Sun weekly strip with active gold badge.
/// 4. Customizable Modular Cards: Reorderable and toggleable via HomeCustomizationNotifier.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _unfinishedWorkout;

  @override
  void initState() {
    super.initState();
    _checkRecovery();
    _checkForUpdates();
    _checkTermsAcceptance();
  }

  Future<void> _checkTermsAcceptance() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (!doc.exists || !mounted) return;
        final acceptedVersion = doc.data()?['termsAcceptedVersion'] as String?;
        if (FormaTermsData.isAcceptanceRequired(acceptedVersion)) {
          if (mounted) {
            _showTermsUpdateSheet(context, user.uid);
          }
        }
      } catch (_) {
        // Offline or rules latency - never block the user from using the app!
      }
    });
  }

  void _showTermsUpdateSheet(BuildContext context, String uid) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? FormaColors.charcoal : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: FormaColors.primaryAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.gavel_rounded,
                        color: FormaColors.primaryAccent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Updated Terms & Conditions',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : FormaColors.charcoal,
                          ),
                        ),
                        Text(
                          'Version ${FormaTermsData.currentVersion}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? FormaColors.darkSecondaryText
                                : FormaColors.lightSecondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'We have updated the FORMA Terms and Conditions. Please review the updated terms to stay informed about your rights, privacy, and responsibilities.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark
                      ? FormaColors.darkSecondaryText
                      : FormaColors.lightSecondaryText,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        context.push('/terms-and-conditions');
                      },
                      child: Text(
                        'Review Terms',
                        style: TextStyle(
                          color: isDark ? Colors.white : FormaColors.charcoal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: FormaColors.primaryAccent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        try {
                          await ref
                              .read(authRepositoryProvider)
                              .acceptTerms(
                                uid: uid,
                                version: FormaTermsData.currentVersion,
                              );
                        } catch (_) {}
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                        }
                      },
                      child: const Text(
                        'Agree & Continue',
                        style: TextStyle(
                          color: FormaColors.charcoal,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _checkForUpdates() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        final updateNotifier = ref.read(updateCheckStateProvider.notifier);
        final result = await updateNotifier.checkForUpdates(force: false);
        if (!mounted) return;
        if (result.status == UpdateStatus.updateAvailable &&
            result.latestRelease != null) {
          final isDismissed = await updateNotifier
              .isVersionDismissed(result.latestRelease!.tagName);
          if (!isDismissed || result.isCritical) {
            if (mounted) {
              FormaUpdateScreen.show(context, result.latestRelease!);
            }
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _checkRecovery() async {
    final recovered =
        await LocalWorkoutRecoveryService().checkUnfinishedWorkout();
    if (mounted && recovered != null) {
      setState(() => _unfinishedWorkout = recovered);
    }
  }

  void _syncWidgets({
    required dynamic summary,
    required dynamic topWorkout,
    required BudgetPlannerSummary budgetSummary,
  }) {
    final now = DateTime.now();
    HomeWidgetService()
        .updateDailyActivityWidget(
          date: DateFormat('EEEE, d MMM').format(now),
          steps: summary?.steps ?? 0,
          energyScore: (summary != null && summary.hasSufficientData)
              ? '${summary.energyScore}'
              : '--',
          workoutStatus:
              topWorkout != null ? topWorkout.name : 'No workout completed',
        )
        .ignore();

    HomeWidgetService()
        .updateWorkoutWidget(
          workoutName: topWorkout?.name ?? 'Rest & Recovery',
          workoutSub: topWorkout != null
              ? '${topWorkout.estimatedDurationMinutes}m • ${topWorkout.splitType}'
              : 'No session scheduled',
          isActive: _unfinishedWorkout != null,
        )
        .ignore();

    HomeWidgetService()
        .updateBudgetWidget(
          allowance:
              '₹${budgetSummary.suggestedDailyAllowance.toStringAsFixed(0)}/day',
          details:
              '${budgetSummary.daysRemaining} days remaining • ₹${budgetSummary.remainingSpendableBudget.toStringAsFixed(0)} balance',
          isRedacted: false,
        )
        .ignore();

    if (topWorkout != null &&
        topWorkout.targetMuscleGroups != null &&
        (topWorkout.targetMuscleGroups as List).isNotEmpty) {
      AppIconService()
          .applyAutoWorkoutAppIcon(
              (topWorkout.targetMuscleGroups as List).join(', '))
          .ignore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    final userProfileAsync = ref.watch(currentUserProfileStreamProvider);
    final userProfile = userProfileAsync.valueOrNull;

    final rawName = userProfile?.displayName ?? user?.displayName ?? 'Athlete';
    final cleaned = rawName
        .replaceAll(
          RegExp(
            r'[\u{10000}-\u{10FFFF}]|[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]',
            unicode: true,
          ),
          '',
        )
        .trim();
    final userName = cleaned.isNotEmpty ? cleaned : 'Athlete';
    final photoUrl = userProfile?.photoUrl ??
        userProfile?.photoURL ??
        userProfile?.avatarUrl ??
        user?.photoURL;

    final habitsAsync = ref.watch(habitsListProvider);
    final habitStatus = ref.watch(habitStatusProvider);
    final workoutsAsync = ref.watch(workoutTemplatesProvider);
    final mealsAsync = ref.watch(todayMealsProvider);
    final friendsActivityAsync = ref.watch(friendsActivityFeedProvider);
    final budgetSummary = ref.watch(budgetPlannerSummaryProvider);
    final summaryAsync = ref.watch(todaySummaryProvider);

    final totalCals = mealsAsync.valueOrNull
            ?.fold<double>(0, (s, m) => s + m.totalCalories)
            .toInt() ??
        0;
    final totalProtein = mealsAsync.valueOrNull
            ?.fold<double>(0, (s, m) => s + m.totalProtein)
            .toInt() ??
        0;
    final todayWaterMl = ref.watch(dailyHydrationProvider);
    const targetWaterMl = HydrationRepository.dailyTargetMl;

    final homeConfigs = ref.watch(homeCardConfigsProvider);
    final visibleCards = homeConfigs.where((c) => c.isVisible).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    // Background widget sync
    final topWorkout = workoutsAsync.valueOrNull?.firstOrNull;
    final summary = summaryAsync.valueOrNull;
    _syncWidgets(
        summary: summary, topWorkout: topWorkout, budgetSummary: budgetSummary);

    return Scaffold(
      backgroundColor:
          isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: FormaColors.primaryAccent,
          onRefresh: () async {
            ref.invalidate(habitsListProvider);
            ref.invalidate(habitStatusProvider);
            ref.invalidate(workoutTemplatesProvider);
            ref.invalidate(todayMealsProvider);
            ref.invalidate(friendsActivityFeedProvider);
            ref.invalidate(todaySummaryProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.only(bottom: 180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // 1. EDITORIAL HEADER & PROFILE NODE
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const FormaLogo.compact(size: 30),
                              const SizedBox(width: 8),
                              Text(
                                'Hi, $userName',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                  color: isDark
                                      ? FormaColors.darkPrimaryText
                                      : FormaColors.lightPrimaryText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Track your progress and daily consistency.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? FormaColors.darkSecondaryText
                                  : FormaColors.lightSecondaryText,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Trainer shortcut node
                          GestureDetector(
                            onTap: () => context.push('/trainer'),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: FormaColors.goldenYellow,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: isDark ? 0.3 : 0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 20,
                                  color: FormaColors.charcoal,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // User profile circular avatar
                          GestureDetector(
                            onTap: () => context.push('/profile'),
                            child: FormaAvatar(
                              photoUrl: photoUrl,
                              name: userName,
                              size: 44,
                              borderWidth: 2,
                              borderColor: FormaColors.goldenYellow,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 1.5 QUICK ACCESS ACTION BAR (Search, Calendar, Weekly Report, Customize)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.push('/search'),
                          child: Container(
                            height: 42,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color:
                                  isDark ? FormaColors.charcoal : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white10
                                    : FormaColors.divider
                                        .withValues(alpha: 0.6),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: isDark ? 0.2 : 0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search_rounded,
                                    size: 18, color: FormaColors.concreteGrey),
                                const SizedBox(width: 8),
                                Text(
                                  'Search FORMA...',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? FormaColors.darkSecondaryText
                                        : FormaColors.lightSecondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildHeaderCircleButton(
                        icon: Icons.calendar_month_rounded,
                        tooltip: 'Calendar',
                        isDark: isDark,
                        onTap: () => context.push('/activity-calendar'),
                      ),
                      const SizedBox(width: 6),
                      _buildHeaderCircleButton(
                        icon: Icons.auto_awesome_rounded,
                        tooltip: 'Weekly Report',
                        isDark: isDark,
                        onTap: () => context.push('/weekly-report'),
                      ),
                      const SizedBox(width: 6),
                      _buildHeaderCircleButton(
                        icon: Icons.tune_rounded,
                        tooltip: 'Customize Home',
                        isDark: isDark,
                        onTap: () => context.push('/customize-home'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2. SIGNATURE DATE SELECTOR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FormaCalendar(
                    selectedDate: _selectedDate,
                    onDateSelected: (date) {
                      setState(() => _selectedDate = date);
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // 2.5 UNFINISHED WORKOUT RECOVERY BANNER (Conditional)
                if (_unfinishedWorkout != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: FormaColors.coralPink.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: FormaColors.coralPink.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: FormaColors.coralPink,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.fitness_center_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Unfinished Workout',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                              Text(
                                '${(_unfinishedWorkout!['workout'] as dynamic).title} • ${(_unfinishedWorkout!['elapsedSeconds'] as int) ~/ 60}m logged',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: FormaColors.concreteGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.push(
                              '/workout/execution',
                              extra: _unfinishedWorkout!['workout'],
                            );
                          },
                          child: const Text(
                            'Resume',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: FormaColors.coralPink,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16),
                          onPressed: () async {
                            await LocalWorkoutRecoveryService()
                                .clearActiveWorkoutSnapshot();
                            setState(() => _unfinishedWorkout = null);
                          },
                        ),
                      ],
                    ),
                  ),

                // 3. DYNAMIC CUSTOMIZABLE HOME CARDS
                ...visibleCards.map((config) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: _buildHomeCard(
                      cardId: config.id,
                      context: context,
                      ref: ref,
                      isDark: isDark,
                      workoutsAsync: workoutsAsync,
                      habitsAsync: habitsAsync,
                      habitStatus: habitStatus,
                      friendsActivityAsync: friendsActivityAsync,
                      todayWaterMl: todayWaterMl,
                      targetWaterMl: targetWaterMl,
                      totalCals: totalCals,
                      totalProtein: totalProtein,
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCircleButton({
    required IconData icon,
    required String tooltip,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: FormaBounceable(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isDark ? FormaColors.charcoal : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark
                  ? Colors.white10
                  : FormaColors.divider.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: isDark
                  ? FormaColors.darkPrimaryText
                  : FormaColors.lightPrimaryText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeCard({
    required String cardId,
    required BuildContext context,
    required WidgetRef ref,
    required bool isDark,
    required AsyncValue<List<dynamic>> workoutsAsync,
    required AsyncValue<List<dynamic>> habitsAsync,
    required Map<String, bool> habitStatus,
    required AsyncValue<List<dynamic>> friendsActivityAsync,
    required int todayWaterMl,
    required int targetWaterMl,
    required int totalCals,
    required int totalProtein,
  }) {
    switch (cardId) {
      case 'energy_score':
        return ref.watch(todaySummaryProvider).when(
              data: (summary) => DailyEnergyRingsWidget(summary: summary),
              loading: () => DailyEnergyRingsWidget(
                summary: DailySummaryService().generateSummary(
                  completedWorkouts: [],
                  loggedMeals: [],
                  habits: [],
                  habitCompletion: {},
                  userName: 'Athlete',
                ),
              ),
              error: (_, __) => DailyEnergyRingsWidget(
                summary: DailySummaryService().generateSummary(
                  completedWorkouts: [],
                  loggedMeals: [],
                  habits: [],
                  habitCompletion: {},
                  userName: 'Athlete',
                ),
              ),
            );

      case 'today_focus':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Focus",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: isDark
                          ? FormaColors.darkPrimaryText
                          : FormaColors.lightPrimaryText,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/workout'),
                    child: const Text(
                      'See all',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: FormaColors.secondaryAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: workoutsAsync.when(
                data: (workouts) {
                  final topWorkout =
                      workouts.isNotEmpty ? workouts.first : null;
                  return AsymmetricFeatureHero(
                    workout: topWorkout,
                    waterMl: todayWaterMl,
                    targetWaterMl: targetWaterMl,
                    onSecondaryTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useRootNavigator: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => const HydrationLogModal(),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ],
        );

      case 'muscle_split':
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: CompactWeeklyMuscleWidget(),
        );

      case 'quick_tools':
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => context.go('/expenses'),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? FormaColors.charcoal : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : FormaColors.concreteGrey.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                FormaColors.goldenYellow.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 18,
                            color: FormaColors.goldenYellow,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Expenses',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white
                                      : FormaColors.charcoal,
                                ),
                              ),
                              Text(
                                'Personal & Shared',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark
                                      ? FormaColors.darkSecondaryText
                                      : FormaColors.lightSecondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/workout/body-visualization'),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? FormaColors.charcoal : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : FormaColors.concreteGrey.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: FormaColors.coralPink.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.accessibility_new_rounded,
                            size: 18,
                            color: FormaColors.coralPink,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Body Anatomy',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white
                                      : FormaColors.charcoal,
                                ),
                              ),
                              Text(
                                'Muscles & Vitals',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark
                                      ? FormaColors.darkSecondaryText
                                      : FormaColors.lightSecondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      case 'daily_pillars':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily Pillars',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: isDark
                          ? FormaColors.darkPrimaryText
                          : FormaColors.lightPrimaryText,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/nutrition'),
                    child: const Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: FormaColors.secondaryAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            HorizontalCardCarousel(
              items: [
                CarouselPillarItem(
                  title: 'Push Power',
                  subtitle: 'Hypertrophy & chest strength focus',
                  tags: const ['Chest', '55 min'],
                  backgroundColor: isDark
                      ? const Color(0xFF2E1C22)
                      : const Color(0xFFFFEAEA),
                  textColor: isDark
                      ? const Color(0xFFFFB4C0)
                      : const Color(0xFFB52B44),
                  icon: Icons.fitness_center_rounded,
                  onTap: () => context.go('/workout'),
                ),
                CarouselPillarItem(
                  title: 'Hydration',
                  subtitle: todayWaterMl >= targetWaterMl
                      ? 'Target complete (${(todayWaterMl / 1000).toStringAsFixed(1)}L)'
                      : '${(todayWaterMl / 1000).toStringAsFixed(1)}L of ${(targetWaterMl / 1000).toStringAsFixed(1)}L target',
                  tags: [
                    '${((todayWaterMl / targetWaterMl).clamp(0.0, 1.0) * 100).toInt()}%',
                    todayWaterMl >= targetWaterMl ? 'Complete' : 'Tracked',
                  ],
                  backgroundColor: isDark
                      ? const Color(0xFF1B2633)
                      : const Color(0xFFEEF5FF),
                  textColor: isDark
                      ? const Color(0xFF90C2FF)
                      : const Color(0xFF1D5CA6),
                  icon: Icons.water_drop_rounded,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useRootNavigator: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => const HydrationLogModal(),
                    );
                  },
                ),
                CarouselPillarItem(
                  title: 'Daily Fuel',
                  subtitle: '$totalCals kcal • ${totalProtein}g protein',
                  tags: const ['Target 2.5k', 'Clean'],
                  backgroundColor: isDark
                      ? const Color(0xFF2C2518)
                      : const Color(0xFFFFF6E5),
                  textColor: isDark
                      ? const Color(0xFFFFD47E)
                      : const Color(0xFF8B5D00),
                  icon: Icons.restaurant_rounded,
                  onTap: () => context.go('/nutrition'),
                ),
              ],
            ),
          ],
        );

      case 'daily_recap':
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ref.watch(todaySummaryProvider).when(
                data: (s) => DailySummaryCard(summary: s),
                loading: () => DailySummaryCard(
                  summary: DailySummaryService().generateSummary(
                    completedWorkouts: [],
                    loggedMeals: [],
                    habits: [],
                    habitCompletion: {},
                    userName: 'Athlete',
                  ),
                ),
                error: (_, __) => DailySummaryCard(
                  summary: DailySummaryService().generateSummary(
                    completedWorkouts: [],
                    loggedMeals: [],
                    habits: [],
                    habitCompletion: {},
                    userName: 'Athlete',
                  ),
                ),
              ),
        );

      case 'daily_habits':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FormaSectionHeader(
                title: 'Daily Habits',
                actionLabel: 'View all →',
                onAction: () => context.go('/habits'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 130,
              child: habitsAsync.when(
                data: (habits) {
                  if (habits.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GestureDetector(
                        onTap: () => context.go('/habits'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: isDark ? FormaColors.charcoal : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  isDark ? Colors.white10 : FormaColors.divider,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: FormaColors.primaryAccent
                                      .withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: FormaColors.primaryAccent,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Set Up Your First Daily Habit',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? FormaColors.darkPrimaryText
                                            : FormaColors.lightPrimaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Track water, workouts, sleep, and routines daily.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? FormaColors.darkSecondaryText
                                            : FormaColors.lightSecondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: isDark
                                    ? Colors.white54
                                    : FormaColors.concreteGrey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: habits.length,
                    itemBuilder: (context, index) {
                      final habit = habits[index];
                      final isCompleted = habitStatus[habit.id] ?? false;

                      return HabitCard(
                        habit: habit,
                        isCompleted: isCompleted,
                        isCompact: true,
                        onToggle: () {
                          ref
                              .read(habitRecordsProvider.notifier)
                              .toggleHabit(habit.id, DateTime.now());
                        },
                        onTap: () => context.go('/habits'),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ],
        );

      case 'friends_activity':
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? FormaColors.darkCardBackground
                  : FormaColors.charcoal,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Friends Activity',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Activity',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: FormaColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                friendsActivityAsync.when(
                  data: (activities) {
                    if (activities.isEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Connect with friends using your friend code to share daily consistency.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white24),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () => context.push('/friends'),
                              child: const Text('View Friends & Groups'),
                            ),
                          ),
                        ],
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activities.take(3).length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: Colors.white12, height: 16),
                      itemBuilder: (context, i) {
                        final act = activities[i];
                        final name = (act['name'] as String?) ?? 'Friend';
                        final action =
                            (act['action'] as String?) ?? 'Completed workout';
                        final time = (act['time'] as String?) ?? '';

                        return Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: FormaColors.primaryAccent
                                    .withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    color: FormaColors.primaryAccent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '$action • $time',
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.white60),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

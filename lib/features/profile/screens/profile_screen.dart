import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forma/core/components/forma_button.dart';
import 'package:forma/core/components/forma_avatar.dart';
import 'package:forma/core/services/android_integration_service.dart';
import 'package:forma/core/services/app_icon_service.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/core/theme/theme_provider.dart';
import 'package:forma/features/authentication/providers/auth_providers.dart';
import 'package:forma/data/repositories/friends_group_repository.dart';
import 'package:forma/data/repositories/habit_repository.dart';
import 'package:forma/data/repositories/nutrition_repository.dart';
import 'package:forma/data/repositories/workout_repository.dart';
import 'package:forma/core/updates/models/update_check_result.dart';
import 'package:forma/core/updates/services/app_update_manager.dart';
import 'package:forma/core/updates/widgets/forma_update_screen.dart';
import 'package:forma/core/legal/terms_data.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentThemeMode = ref.watch(themeModeProvider);
    final updateState = ref.watch(updateCheckStateProvider);
    final user = FirebaseAuth.instance.currentUser;
    final userProfileAsync = ref.watch(currentUserProfileStreamProvider);
    final userProfile = userProfileAsync.valueOrNull;

    final userName = userProfile?.displayName ??
        (user?.displayName?.isNotEmpty == true
            ? user!.displayName!
            : 'Athlete');
    final photoUrl = userProfile?.photoUrl ??
        userProfile?.photoURL ??
        userProfile?.avatarUrl ??
        user?.photoURL;
    final userEmail = user?.email ?? 'No email connected';

    final workoutsCount = ref.watch(workoutHistoryProvider).when(
          data: (h) => '${h.length}',
          loading: () => '...',
          error: (_, __) => '0',
        );

    final habitsCount = ref.watch(habitsListProvider).when(
          data: (h) => '${h.length}',
          loading: () => '...',
          error: (_, __) => '0',
        );

    final todayCalories = ref.watch(todayMealsProvider).when(
          data: (meals) =>
              '${meals.fold<double>(0, (s, m) => s + m.calories).toInt()}',
          loading: () => '0',
          error: (_, __) => '0',
        );

    final friendCodeAsync = ref.watch(myFriendCodeProvider);

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
        backgroundColor:
            isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to Home',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text(
          'Profile & Settings',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. User Header
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => context.push('/profile/avatar'),
                      child: Stack(
                        children: [
                          FormaAvatar(
                            photoUrl: photoUrl,
                            name: userName,
                            size: 92,
                            borderWidth: 3,
                            borderColor: FormaColors.goldenYellow,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: FormaColors.primaryAccent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                size: 14,
                                color: FormaColors.charcoal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? FormaColors.darkPrimaryText
                            : FormaColors.lightPrimaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail,
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

              const SizedBox(height: 24),

              // 2. Personal Stats Overview
              Row(
                children: [
                  _buildProfileStat(context, workoutsCount, 'Workouts'),
                  const SizedBox(width: 12),
                  _buildProfileStat(context, habitsCount, 'Habits'),
                  const SizedBox(width: 12),
                  _buildProfileStat(context, todayCalories, 'Calories Today'),
                ],
              ),

              const SizedBox(height: 28),

              // ── CATEGORY 1: Account & Community ──
              _buildSettingsGroup(
                context: context,
                title: 'Account & Community',
                icon: Icons.person_rounded,
                isDark: isDark,
                children: [
                  ListTile(
                    leading: const Icon(Icons.face_rounded,
                        color: FormaColors.primaryAccent),
                    title: const Text('Profile Avatar & Photo',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('FORMA presets or upload custom photo',
                        style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/profile/avatar'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.security_rounded,
                        color: FormaColors.primaryAccent),
                    title: const Text('Account Security & Biometrics',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text(
                        'Email verification, biometrics & app lock',
                        style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/profile/security-settings'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.link_rounded,
                        color: FormaColors.primaryAccent),
                    title: const Text('Account Connections',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Google, Email & Phone linking',
                        style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/account-connections'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.people_alt_rounded,
                        color: FormaColors.coralPink),
                    title: const Text('Friends & Invite Code',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      friendCodeAsync.when(
                        data: (c) => 'Code: $c',
                        loading: () => 'Loading...',
                        error: (_, __) => 'Tap to view',
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/friends'),
                  ),
                ],
              ),

              // ── CATEGORY 2: Body & Training ──
              _buildSettingsGroup(
                context: context,
                title: 'Body & Training',
                icon: Icons.fitness_center_rounded,
                isDark: isDark,
                children: [
                  ListTile(
                    leading: const Icon(Icons.accessibility_new_rounded,
                        color: FormaColors.coralPink),
                    title: const Text('Body & Activity Visualization',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text(
                        'Anatomical muscle map & genuine metrics',
                        style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/workout/body-visualization'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.tune_rounded,
                        color: FormaColors.primaryAccent),
                    title: const Text('Body & Activity Settings',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Units, experience & priority muscles',
                        style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/profile/body-settings'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.view_week_rounded,
                        color: FormaColors.goldenYellow),
                    title: const Text('Weekly Muscle Split',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text(
                        'PPL / Upper-Lower / Custom split tracker',
                        style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/workout/muscle-overview'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.app_shortcut_rounded,
                        color: FormaColors.secondaryAccent),
                    title: const Text('Workout App Icon',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text(
                        'Dynamic launcher badge matching training split',
                        style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showAppIconPicker(context),
                  ),
                ],
              ),

              // ── CATEGORY 3: Finances & Records ──
              _buildSettingsGroup(
                context: context,
                title: 'Finances & Records',
                icon: Icons.account_balance_wallet_rounded,
                isDark: isDark,
                children: [
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet_rounded,
                        color: FormaColors.goldenYellow),
                    title: const Text('Personal Expenses',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Completely private spending tracker',
                        style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.go('/expenses'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.group_rounded,
                        color: FormaColors.secondaryAccent),
                    title: const Text('Shared Expenses & Settlements',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Group split ledger & who-owes-whom',
                        style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/shared-expenses'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.calendar_month_rounded,
                        color: FormaColors.goldenYellow),
                    title: const Text('Activity Calendar',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text(
                        'Historical workout, meal & expense logs',
                        style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/activity-calendar'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.file_download_outlined,
                        color: FormaColors.primaryAccent),
                    title: const Text('Export My Data',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Download CSV workout records via SAF',
                        style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      final history = await ref
                          .read(workoutRepositoryProvider)
                          .getHistory();
                      final rows = history
                          .map((s) => {
                                'date': (s.endTime ?? s.startTime)
                                    .toIso8601String()
                                    .substring(0, 10),
                                'name': s.workoutName,
                                'exercises': s.exercises.length,
                                'volume': s.totalVolume,
                                'duration': s.duration.inMinutes,
                              })
                          .toList();
                      final file = await AndroidIntegrationService()
                          .exportWorkoutHistoryToCsv(rows);
                      await AndroidIntegrationService().shareFile(file,
                          text: 'My FORMA Workout History Export');
                    },
                  ),
                ],
              ),

              // ── CATEGORY 4: Intelligence & Guidance ──
              _buildSettingsGroup(
                context: context,
                title: 'Intelligence & Guidance',
                icon: Icons.auto_awesome_rounded,
                isDark: isDark,
                children: [
                  ListTile(
                    leading: const Icon(Icons.psychology_rounded,
                        color: FormaColors.goldenYellow),
                    title: const Text('Personal AI Assistant',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Manage your coaching preferences',
                        style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/user-api-key-settings'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.auto_awesome_rounded,
                        color: FormaColors.coralPink),
                    title: const Text('Weekly Intelligence Report',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Your Week in FORMA & coach synthesis',
                        style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/weekly-report'),
                  ),
                ],
              ),

              // ── CATEGORY 5: App Preferences & System ──
              _buildSettingsGroup(
                context: context,
                title: 'App Preferences & System',
                icon: Icons.settings_rounded,
                isDark: isDark,
                children: [
                  ListTile(
                    leading: const Icon(Icons.dark_mode_rounded,
                        color: FormaColors.primaryAccent),
                    title: const Text('Theme Mode',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      currentThemeMode == ThemeMode.system
                          ? 'System'
                          : currentThemeMode == ThemeMode.dark
                              ? 'Dark Mode'
                              : 'Light Mode',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: DropdownButton<ThemeMode>(
                      value: currentThemeMode,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(
                            value: ThemeMode.system, child: Text('System')),
                        DropdownMenuItem(
                            value: ThemeMode.light, child: Text('Light')),
                        DropdownMenuItem(
                            value: ThemeMode.dark, child: Text('Dark')),
                      ],
                      onChanged: (mode) {
                        if (mode != null) {
                          ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(mode);
                        }
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.health_and_safety_rounded,
                        color: FormaColors.sage),
                    title: const Text('Google Health Connect',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Steps, calories & vitals integration',
                        style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/health-connect-settings'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined,
                        color: FormaColors.primaryAccent),
                    title: const Text('Notifications',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Reminders, recaps & quiet hours',
                        style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/notification-settings'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      updateState.status == UpdateStatus.updateAvailable
                          ? Icons.system_update_rounded
                          : Icons.cloud_download_outlined,
                      color: updateState.status == UpdateStatus.updateAvailable
                          ? FormaColors.coralPink
                          : FormaColors.primaryAccent,
                    ),
                    title: Row(
                      children: [
                        const Text('Software Updates',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        if (updateState.status == UpdateStatus.updateAvailable) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: FormaColors.coralPink,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'UPDATE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      updateState.status == UpdateStatus.checking
                          ? 'Checking for updates...'
                          : updateState.status == UpdateStatus.updateAvailable
                              ? 'New update available (${updateState.latestRelease?.tagName ?? ""})'
                              : 'v${updateState.currentVersion} • Up to date',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: updateState.status == UpdateStatus.checking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      if (updateState.status == UpdateStatus.updateAvailable &&
                          updateState.latestRelease != null) {
                        FormaUpdateScreen.show(
                            context, updateState.latestRelease!);
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Checking GitHub for updates...'),
                            ],
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );

                      final result = await ref
                          .read(updateCheckStateProvider.notifier)
                          .checkForUpdates(force: true);

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();

                      if (result.status == UpdateStatus.updateAvailable &&
                          result.latestRelease != null) {
                        FormaUpdateScreen.show(context, result.latestRelease!);
                      } else if (result.status == UpdateStatus.upToDate) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'FORMA is up to date (v${result.currentVersion})',
                            ),
                            backgroundColor: FormaColors.sage,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else if (result.status == UpdateStatus.error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Update check failed: ${result.error}'),
                            backgroundColor: FormaColors.coralPink,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.favorite_rounded,
                        color: FormaColors.coralPink),
                    title: const Text('Thanks & Credits',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Developer info & credits',
                        style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/thanks-credits'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _buildSettingsGroup(
                context: context,
                title: 'Legal & Compliance',
                icon: Icons.gavel_rounded,
                isDark: isDark,
                children: [
                  ListTile(
                    leading: const Icon(Icons.description_outlined,
                        color: FormaColors.primaryAccent),
                    title: const Text('Terms and Conditions',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Rules, liability & service terms',
                        style: TextStyle(fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'v${FormaTermsData.currentVersion}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                    onTap: () => context.push('/terms-and-conditions'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              FormaButton(
                label: 'Sign Out',
                variant: FormaButtonVariant.secondary,
                onPressed: () => _confirmSignOut(context),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => _confirmDeleteAccount(context),
                  child: const Text(
                    'Delete Account',
                    style: TextStyle(
                      color: FormaColors.coralPink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 110),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildSettingsGroup({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(icon, size: 15, color: FormaColors.primaryAccent),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: isDark
                      ? FormaColors.darkSecondaryText
                      : FormaColors.lightSecondaryText,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? FormaColors.darkCardBackground
                : FormaColors.lightCardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white10
                  : FormaColors.divider.withValues(alpha: 0.5),
            ),
          ),
          child: Column(children: children),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
            'Are you sure you want to sign out of your FORMA account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: FormaColors.charcoal),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await GoogleSignIn().signOut();
              } catch (_) {}
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                context.go('/welcome');
              }
            },
            child:
                const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This will permanently delete your account and remove all personal workout and nutrition history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: FormaColors.coralPink),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                try {
                  await GoogleSignIn().signOut();
                } catch (_) {}
                final user = FirebaseAuth.instance.currentUser;
                await user?.delete();
                if (context.mounted) {
                  context.go('/welcome');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Failed to delete account: $e. Please re-authenticate first.'),
                      backgroundColor: FormaColors.coralPink,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete Permanently',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAppIconPicker(BuildContext context) async {
    final currentIcon = await AppIconService().getCurrentAppIcon();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final icons = [
      (name: 'Default', label: 'Official FORMA', icon: Icons.stars_rounded),
      (
        name: 'Chest',
        label: 'Push & Chest Day',
        icon: Icons.fitness_center_rounded
      ),
      (
        name: 'Back',
        label: 'Pull & Back Day',
        icon: Icons.fitness_center_rounded
      ),
      (
        name: 'Legs',
        label: 'Leg & Lower Body Day',
        icon: Icons.accessibility_new_rounded
      ),
      (
        name: 'Arms',
        label: 'Arm & Shoulder Day',
        icon: Icons.fitness_center_rounded
      ),
      (name: 'Rest', label: 'Rest & Recovery Day', icon: Icons.spa_rounded),
    ];

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: isDark ? FormaColors.charcoal : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Choose Launcher App Icon',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Select your favorite icon badge or let FORMA automatically match today’s scheduled workout.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? FormaColors.darkSecondaryText
                      : FormaColors.lightSecondaryText,
                ),
              ),
              const SizedBox(height: 16),
              ...icons.map((item) {
                final isSelected = currentIcon == item.name;
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? FormaColors.goldenYellow.withValues(alpha: 0.2)
                          : (isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.05)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.icon,
                      color: isSelected
                          ? FormaColors.goldenYellow
                          : FormaColors.concreteGrey,
                    ),
                  ),
                  title: Text(item.label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded,
                          color: FormaColors.goldenYellow)
                      : null,
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    Navigator.of(ctx).pop();
                    final ok = await AppIconService().setAppIcon(item.name);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok
                              ? 'App icon updated to ${item.label}!'
                              : 'Icon update scheduled.'),
                          backgroundColor: FormaColors.charcoal,
                        ),
                      );
                    }
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStat(BuildContext context, String value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark
              ? FormaColors.darkCardBackground
              : FormaColors.lightCardBackground,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isDark
                    ? FormaColors.darkPrimaryText
                    : FormaColors.lightPrimaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? FormaColors.darkSecondaryText
                    : FormaColors.lightSecondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

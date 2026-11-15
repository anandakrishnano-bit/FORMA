import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forma/core/theme/app_colors.dart';

final notificationSettingsProvider = StateNotifierProvider<
    NotificationSettingsNotifier, NotificationSettingsState>((ref) {
  return NotificationSettingsNotifier();
});

class NotificationSettingsState {
  final bool workoutReminders;
  final bool habitReminders;
  final bool nutritionReminders;
  final bool dailySummaryAlerts;
  final bool groupActivityAlerts;
  final bool restTimerVibration;

  const NotificationSettingsState({
    this.workoutReminders = true,
    this.habitReminders = true,
    this.nutritionReminders = false,
    this.dailySummaryAlerts = true,
    this.groupActivityAlerts = true,
    this.restTimerVibration = true,
  });

  NotificationSettingsState copyWith({
    bool? workoutReminders,
    bool? habitReminders,
    bool? nutritionReminders,
    bool? dailySummaryAlerts,
    bool? groupActivityAlerts,
    bool? restTimerVibration,
  }) {
    return NotificationSettingsState(
      workoutReminders: workoutReminders ?? this.workoutReminders,
      habitReminders: habitReminders ?? this.habitReminders,
      nutritionReminders: nutritionReminders ?? this.nutritionReminders,
      dailySummaryAlerts: dailySummaryAlerts ?? this.dailySummaryAlerts,
      groupActivityAlerts: groupActivityAlerts ?? this.groupActivityAlerts,
      restTimerVibration: restTimerVibration ?? this.restTimerVibration,
    );
  }
}

class NotificationSettingsNotifier
    extends StateNotifier<NotificationSettingsState> {
  NotificationSettingsNotifier() : super(const NotificationSettingsState());

  void toggleWorkoutReminders(bool val) =>
      state = state.copyWith(workoutReminders: val);
  void toggleHabitReminders(bool val) =>
      state = state.copyWith(habitReminders: val);
  void toggleNutritionReminders(bool val) =>
      state = state.copyWith(nutritionReminders: val);
  void toggleDailySummaryAlerts(bool val) =>
      state = state.copyWith(dailySummaryAlerts: val);
  void toggleGroupActivityAlerts(bool val) =>
      state = state.copyWith(groupActivityAlerts: val);
  void toggleRestTimerVibration(bool val) =>
      state = state.copyWith(restTimerVibration: val);
}

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);

    return Scaffold(
      backgroundColor:
          isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
      appBar: AppBar(
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          physics: const BouncingScrollPhysics(),
          children: [
            Text(
              'Manage your reminders and alerts. FORMA respects your quiet hours and only sends relevant notifications.',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? FormaColors.darkSecondaryText
                    : FormaColors.lightSecondaryText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionHeader(context, 'TRAINING & HABITS', isDark),
            _buildSwitchTile(
              title: 'Workout Reminders',
              subtitle: 'Upcoming routines and rest interval alerts',
              value: settings.workoutReminders,
              onChanged: notifier.toggleWorkoutReminders,
              isDark: isDark,
            ),
            _buildSwitchTile(
              title: 'Habit Reminders',
              subtitle: 'Daily check-in reminders for incomplete habits',
              value: settings.habitReminders,
              onChanged: notifier.toggleHabitReminders,
              isDark: isDark,
            ),
            _buildSwitchTile(
              title: 'Rest Timer Alert',
              subtitle: 'Vibrate and notify when rest period finishes',
              value: settings.restTimerVibration,
              onChanged: notifier.toggleRestTimerVibration,
              isDark: isDark,
            ),

            const SizedBox(height: 24),

            _buildSectionHeader(context, 'DAILY RECAPS & FRIENDS', isDark),
            _buildSwitchTile(
              title: 'Your Day in Review',
              subtitle: 'Evening notification when your daily summary is ready',
              value: settings.dailySummaryAlerts,
              onChanged: notifier.toggleDailySummaryAlerts,
              isDark: isDark,
            ),
            _buildSwitchTile(
              title: 'Group Challenges & Friends',
              subtitle: 'Updates on shared challenges and milestones',
              value: settings.groupActivityAlerts,
              onChanged: notifier.toggleGroupActivityAlerts,
              isDark: isDark,
            ),
            _buildSwitchTile(
              title: 'Nutrition Reminders',
              subtitle: 'Gentle reminders for meal logging',
              value: settings.nutritionReminders,
              onChanged: notifier.toggleNutritionReminders,
              isDark: isDark,
            ),

            const SizedBox(height: 28),

            // Android System Settings Navigation Link
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? FormaColors.darkCardBackground
                    : FormaColors.lightCardBackground,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded,
                      color: FormaColors.primaryAccent),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Android Notification Channels',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? FormaColors.darkPrimaryText
                                : FormaColors.lightPrimaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'You can also customize sounds and lock screen visibility in system settings.',
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: isDark
              ? FormaColors.darkSecondaryText
              : FormaColors.lightSecondaryText,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark
            ? FormaColors.darkCardBackground
            : FormaColors.lightCardBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark
                ? FormaColors.darkPrimaryText
                : FormaColors.lightPrimaryText,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? FormaColors.darkSecondaryText
                : FormaColors.lightSecondaryText,
          ),
        ),
        value: value,
        activeThumbColor: FormaColors.primaryAccent,
        onChanged: onChanged,
      ),
    );
  }
}

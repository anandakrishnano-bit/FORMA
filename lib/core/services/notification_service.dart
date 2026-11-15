import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;

/// Android-First Notification Channels and Service for FORMA.
///
/// CHANNELS:
/// 1. forma_workouts: Reminders, milestones, active live session updates.
/// 2. forma_habits: Scheduled daily habits and reminders.
/// 3. forma_nutrition: Meal diary reminders.
/// 4. forma_daily_summary: Evening "Your day in review" ready alert.
/// 5. forma_groups: Challenge updates and friend activity milestones.
/// 6. forma_app_updates: Security, sync, and account notifications.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String channelWorkouts = 'forma_workouts';
  static const String channelHabits = 'forma_habits';
  static const String channelNutrition = 'forma_nutrition';
  static const String channelDailySummary = 'forma_daily_summary';
  static const String channelGroups = 'forma_groups';
  static const String channelApp = 'forma_app_updates';

  Future<void> initialize(
      {Function(String? payload)? onNotificationTapped}) async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (onNotificationTapped != null) {
          onNotificationTapped(response.payload);
        }
      },
    );

    await _createNotificationChannels();
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
    }
  }

  Future<void> _createNotificationChannels() async {
    final androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          channelWorkouts,
          'Workouts',
          description:
              'Workout reminders, rest timer alerts, and live sessions',
          importance: Importance.high,
          enableVibration: true,
        ),
      );

      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          channelHabits,
          'Habits',
          description: 'Daily habit reminders and streak celebrations',
          importance: Importance.defaultImportance,
          enableVibration: true,
        ),
      );

      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          channelNutrition,
          'Nutrition',
          description: 'Meal tracking reminders and nutrition targets',
          importance: Importance.low,
        ),
      );

      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          channelDailySummary,
          'Daily Summaries',
          description: 'Evening notifications for "Your day in review"',
          importance: Importance.defaultImportance,
        ),
      );

      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          channelGroups,
          'Friends and Groups',
          description:
              'Group challenges, friend milestones, and activity updates',
          importance: Importance.defaultImportance,
        ),
      );

      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          channelApp,
          'App & Security',
          description: 'Data sync status, security alerts, and exports',
          importance: Importance.high,
        ),
      );
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // LIVE WORKOUT ONGOING NOTIFICATION (Foreground Service Behavior)
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> showLiveWorkoutNotification({
    required String workoutName,
    required String currentExercise,
    required int setNumber,
    required int totalSets,
    int? restSecondsRemaining,
  }) async {
    final subText = restSecondsRemaining != null && restSecondsRemaining > 0
        ? 'Rest: ${restSecondsRemaining}s'
        : 'Set $setNumber of $totalSets';

    final androidDetails = AndroidNotificationDetails(
      channelWorkouts,
      'Workouts',
      channelDescription: 'Ongoing active workout session',
      icon: '@mipmap/ic_launcher',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true, // Non-dismissible while active
      autoCancel: false,
      showWhen: true,
      subText: subText,
      showProgress: totalSets > 0,
      maxProgress: totalSets,
      progress: setNumber,
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction('skip_rest', 'Skip Rest'),
        AndroidNotificationAction('pause_workout', 'Pause'),
      ],
    );

    try {
      await _localNotifications.show(
        1001, // Dedicated active workout ID
        workoutName,
        '$currentExercise • $subText',
        NotificationDetails(android: androidDetails),
        payload: '/workout/execution',
      );
    } catch (_) {}
  }

  Future<void> cancelLiveWorkoutNotification() async {
    await _localNotifications.cancel(1001);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // REST TIMER COMPLETION ALERT
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> showRestTimerCompleted() async {
    const androidDetails = AndroidNotificationDetails(
      channelWorkouts,
      'Workouts',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
    );

    await _localNotifications.show(
      1002,
      'Your rest period is over',
      'Time to crush your next set!',
      const NotificationDetails(android: androidDetails),
      payload: '/workout/execution',
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // EVENING RECAP ("Your day in review is ready")
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> showDailySummaryReady() async {
    const androidDetails = AndroidNotificationDetails(
      channelDailySummary,
      'Daily Summaries',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    await _localNotifications.show(
      2001,
      'Your day in review is ready',
      'See what you achieved today and a gentle thought for tomorrow.',
      const NotificationDetails(android: androidDetails),
      payload: '/home',
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // HABIT REMINDER (Scheduled or Instant)
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> showHabitReminder(String habitTitle) async {
    const androidDetails = AndroidNotificationDetails(
      channelHabits,
      'Habits',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'You have a habit to check off',
      habitTitle,
      const NotificationDetails(android: androidDetails),
      payload: '/habits',
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // SOCIAL & FRIEND NOTIFICATIONS (Android-First Heads-Up)
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> showFriendRequestNotification({
    required String senderName,
    required String requestId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      channelGroups,
      'Friends and Groups',
      channelDescription:
          'Group challenges, friend milestones, and activity updates',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _localNotifications.show(
      requestId.hashCode,
      'New Friend Request',
      '$senderName sent you a friend request on FORMA.',
      const NotificationDetails(android: androidDetails),
      payload: '/friends',
    );
  }

  Future<void> showFriendAcceptedNotification({
    required String friendName,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      channelGroups,
      'Friends and Groups',
      channelDescription:
          'Group challenges, friend milestones, and activity updates',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _localNotifications.show(
      friendName.hashCode,
      'Friend Request Accepted',
      '$friendName is now your training partner on FORMA!',
      const NotificationDetails(android: androidDetails),
      payload: '/friends',
    );
  }
}

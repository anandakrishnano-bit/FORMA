import 'package:flutter/material.dart';

/// Configuration for a reorderable, toggleable card on FORMA's Home Screen.
class HomeCardConfig {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool isVisible;
  final int order;

  const HomeCardConfig({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.isVisible = true,
    required this.order,
  });

  HomeCardConfig copyWith({
    String? title,
    String? description,
    IconData? icon,
    bool? isVisible,
    int? order,
  }) {
    return HomeCardConfig(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      isVisible: isVisible ?? this.isVisible,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isVisible': isVisible,
      'order': order,
    };
  }

  factory HomeCardConfig.fromMap(
      Map<String, dynamic> map, HomeCardConfig fallback) {
    return HomeCardConfig(
      id: map['id'] as String? ?? fallback.id,
      title: map['title'] as String? ?? fallback.title,
      description: fallback.description,
      icon: fallback.icon,
      isVisible: map['isVisible'] as bool? ?? fallback.isVisible,
      order: map['order'] as int? ?? fallback.order,
    );
  }

  /// Default layout configuration
  static List<HomeCardConfig> get defaults => const [
        HomeCardConfig(
          id: 'energy_score',
          title: 'Daily Energy & Vitals',
          description: 'Calculated score from genuine activity and sleep',
          icon: Icons.bolt_rounded,
          isVisible: true,
          order: 0,
        ),
        HomeCardConfig(
          id: 'today_focus',
          title: "Today's Focus & Hydration",
          description: 'Planned workout hero and live water intake',
          icon: Icons.fitness_center_rounded,
          isVisible: true,
          order: 1,
        ),
        HomeCardConfig(
          id: 'muscle_split',
          title: 'Weekly Muscle Split',
          description: 'Muscle group training volume and recovery status',
          icon: Icons.view_week_rounded,
          isVisible: true,
          order: 2,
        ),
        HomeCardConfig(
          id: 'quick_tools',
          title: 'Expenses & Anatomy Tools',
          description: 'Quick access tiles for finances and 3D body map',
          icon: Icons.grid_view_rounded,
          isVisible: true,
          order: 3,
        ),
        HomeCardConfig(
          id: 'daily_pillars',
          title: 'Daily Pillars Carousel',
          description: 'Push power, hydration balance, and macro fuel',
          icon: Icons.view_carousel_rounded,
          isVisible: true,
          order: 4,
        ),
        HomeCardConfig(
          id: 'daily_recap',
          title: 'Evening Day in Review',
          description: 'Summary card with tomorrow’s recommendations',
          icon: Icons.nightlight_round,
          isVisible: true,
          order: 5,
        ),
        HomeCardConfig(
          id: 'daily_habits',
          title: 'Daily Habit Streaks',
          description: 'Interactive horizontal habit completion strip',
          icon: Icons.check_circle_outline_rounded,
          isVisible: true,
          order: 6,
        ),
        HomeCardConfig(
          id: 'friends_activity',
          title: 'Friends & Training Partners',
          description: 'Live consistency feed from verified friends',
          icon: Icons.people_outline_rounded,
          isVisible: true,
          order: 7,
        ),
      ];
}

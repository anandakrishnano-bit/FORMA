import 'package:flutter/material.dart';
import 'package:forma/core/theme/app_colors.dart';

/// Representation of an original FORMA-themed preset avatar
class FormaPresetAvatar {
  final String id;
  final String name;
  final String archetype;
  final Color primaryColor;
  final Color backgroundColor;
  final IconData icon;
  final String badgeText;

  const FormaPresetAvatar({
    required this.id,
    required this.name,
    required this.archetype,
    required this.primaryColor,
    required this.backgroundColor,
    required this.icon,
    required this.badgeText,
  });

  String get storageKey => 'preset:$id';

  static const List<FormaPresetAvatar> collection = [
    FormaPresetAvatar(
      id: 'forma_zen',
      name: 'Zen Athlete',
      archetype: 'Mindfulness & Mobility',
      primaryColor: FormaColors.lavender,
      backgroundColor: Color(0xFF23213A),
      icon: Icons.self_improvement_rounded,
      badgeText: 'MOBILITY',
    ),
    FormaPresetAvatar(
      id: 'forma_lifter',
      name: 'Power Lifter',
      archetype: 'Heavy Strength & Power',
      primaryColor: FormaColors.coralPink,
      backgroundColor: Color(0xFF2E1C22),
      icon: Icons.fitness_center_rounded,
      badgeText: 'STRENGTH',
    ),
    FormaPresetAvatar(
      id: 'forma_sprinter',
      name: 'Sprinter',
      archetype: 'Speed & Acceleration',
      primaryColor: FormaColors.goldenYellow,
      backgroundColor: Color(0xFF2C2518),
      icon: Icons.directions_run_rounded,
      badgeText: 'SPEED',
    ),
    FormaPresetAvatar(
      id: 'forma_runner',
      name: 'Distance Pacer',
      archetype: 'Endurance & Stamina',
      primaryColor: FormaColors.sage,
      backgroundColor: Color(0xFF1E2B1B),
      icon: Icons.timer_rounded,
      badgeText: 'ENDURANCE',
    ),
    FormaPresetAvatar(
      id: 'forma_minimalist',
      name: 'Minimal Crest',
      archetype: 'Editorial Clean',
      primaryColor: FormaColors.warmCream,
      backgroundColor: FormaColors.charcoal,
      icon: Icons.crop_square_rounded,
      badgeText: 'ORIGINAL',
    ),
    FormaPresetAvatar(
      id: 'forma_climber',
      name: 'Apex Climber',
      archetype: 'Grip & Calisthenics',
      primaryColor: FormaColors.terracotta,
      backgroundColor: Color(0xFF2E1E1A),
      icon: Icons.terrain_rounded,
      badgeText: 'CLIMB',
    ),
    FormaPresetAvatar(
      id: 'forma_cyclist',
      name: 'Velodrome Pacer',
      archetype: 'Aerobic & Cadence',
      primaryColor: FormaColors.azure,
      backgroundColor: Color(0xFF172332),
      icon: Icons.pedal_bike_rounded,
      badgeText: 'CADENCE',
    ),
    FormaPresetAvatar(
      id: 'forma_crest',
      name: 'FORMA Monogram',
      archetype: 'Brand Signature',
      primaryColor: FormaColors.goldenYellow,
      backgroundColor: FormaColors.charcoal,
      icon: Icons.shield_rounded,
      badgeText: 'FORMA',
    ),
    FormaPresetAvatar(
      id: 'forma_pulse',
      name: 'Kinetic Pulse',
      archetype: 'Cardio & Heart Drive',
      primaryColor: FormaColors.coralPink,
      backgroundColor: Color(0xFF2E1C22),
      icon: Icons.monitor_heart_rounded,
      badgeText: 'CARDIO',
    ),
    FormaPresetAvatar(
      id: 'forma_aurora',
      name: 'Dawn Athlete',
      archetype: 'Morning Consistency',
      primaryColor: FormaColors.icyBlue,
      backgroundColor: Color(0xFF1B2633),
      icon: Icons.wb_twilight_rounded,
      badgeText: 'RITUAL',
    ),
    FormaPresetAvatar(
      id: 'forma_champion',
      name: 'Strength Shield',
      archetype: 'Resilience & Grit',
      primaryColor: FormaColors.goldenYellow,
      backgroundColor: Color(0xFF2A2318),
      icon: Icons.military_tech_rounded,
      badgeText: 'RESOLVE',
    ),
    FormaPresetAvatar(
      id: 'forma_core',
      name: 'Isometric Core',
      archetype: 'Stability & Balance',
      primaryColor: FormaColors.amber,
      backgroundColor: Color(0xFF2E2417),
      icon: Icons.adjust_rounded,
      badgeText: 'BALANCE',
    ),
  ];

  static FormaPresetAvatar? fromKey(String? key) {
    if (key == null || !key.startsWith('preset:')) return null;
    final id = key.replaceFirst('preset:', '');
    try {
      return collection.firstWhere((a) => a.id == id);
    } catch (_) {
      return collection.first;
    }
  }
}

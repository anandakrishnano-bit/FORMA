import 'package:flutter/material.dart';

/// Categories for user-reported problems in FORMA.
/// Designed with non-technical, human-friendly labels.
enum BugReportCategory {
  crash('crash', 'App crash', 'The app unexpectedly closed or froze',
      Icons.dangerous_rounded),
  display('display', 'Display or layout issue',
      'Elements overlapping, distorted or clipped', Icons.aspect_ratio_rounded),
  auth('auth', 'Login or account issue',
      'Sign-in, verification or account access', Icons.lock_person_rounded),
  incorrectInfo('incorrect_info', 'Incorrect information',
      'Calculations, metrics or sync discrepancies', Icons.rule_rounded),
  feature('feature', 'Feature not working',
      'A button, tracker or tool did not respond', Icons.build_circle_rounded),
  performance('performance', 'Performance issue',
      'Sluggishness, stuttering or slow loading', Icons.speed_rounded),
  other('other', 'Other', 'Any other issue not covered above',
      Icons.help_outline_rounded);

  final String id;
  final String label;
  final String description;
  final IconData icon;

  const BugReportCategory(this.id, this.label, this.description, this.icon);

  static BugReportCategory fromId(String? id) {
    return BugReportCategory.values.firstWhere(
      (c) => c.id == id,
      orElse: () => BugReportCategory.other,
    );
  }
}

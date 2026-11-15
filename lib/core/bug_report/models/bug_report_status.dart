import 'package:flutter/material.dart';
import 'package:forma/core/theme/app_colors.dart';

/// Investigation & resolution lifecycle states for a bug report.
enum BugReportStatus {
  newReport('new', 'New', FormaColors.coralPink, Icons.fiber_new_rounded),
  investigating('investigating', 'Investigating', FormaColors.goldenYellow,
      Icons.troubleshoot_rounded),
  fixed('fixed', 'Fixed', FormaColors.sage, Icons.check_circle_rounded),
  cannotReproduce('cannot_reproduce', 'Cannot Reproduce', Colors.grey,
      Icons.help_center_rounded),
  closed(
      'closed', 'Closed', FormaColors.darkSecondaryText, Icons.archive_rounded);

  final String id;
  final String label;
  final Color badgeColor;
  final IconData icon;

  const BugReportStatus(this.id, this.label, this.badgeColor, this.icon);

  static BugReportStatus fromId(String? id) {
    return BugReportStatus.values.firstWhere(
      (s) => s.id == id,
      orElse: () => BugReportStatus.newReport,
    );
  }
}

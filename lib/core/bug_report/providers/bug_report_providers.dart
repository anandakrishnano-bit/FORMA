import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/bug_report_category.dart';
import '../models/bug_report_model.dart';
import '../models/bug_report_status.dart';
import '../services/bug_report_repository.dart';

final bugReportRepositoryProvider = Provider<BugReportRepository>((ref) {
  return BugReportRepository();
});

/// Stream of reports submitted by the logged in user.
final myBugReportsProvider =
    StreamProvider.autoDispose<List<BugReportModel>>((ref) {
  final repo = ref.watch(bugReportRepositoryProvider);
  return repo.watchMyReports();
});

/// Parameters for querying maintainer reports.
class MaintainerReportsFilter {
  final BugReportStatus? status;
  final BugReportCategory? category;

  const MaintainerReportsFilter({this.status, this.category});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaintainerReportsFilter &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          category == other.category;

  @override
  int get hashCode => status.hashCode ^ category.hashCode;
}

/// Stream of all reports for authorized maintainers.
final allBugReportsProvider = StreamProvider.autoDispose
    .family<List<BugReportModel>, MaintainerReportsFilter>((ref, filter) {
  final repo = ref.watch(bugReportRepositoryProvider);
  return repo.watchAllReports(
    statusFilter: filter.status,
    categoryFilter: filter.category,
  );
});

/// Evaluates whether the currently signed-in user has maintainer / developer privileges.
final isMaintainerProvider = Provider.autoDispose<bool>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  // Known developer/maintainer domains and emails
  final email = user.email?.toLowerCase() ?? '';
  if (email.endsWith('@forma.app') ||
      email.contains('anandakrishnano-bit') ||
      email.contains('stark') ||
      email.contains('admin')) {
    return true;
  }

  return false;
});

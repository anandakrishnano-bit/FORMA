import 'package:cloud_firestore/cloud_firestore.dart';
import 'bug_report_category.dart';
import 'bug_report_status.dart';

/// Immutable model representing a complete user bug report and diagnostic package.
class BugReportModel {
  final String id;
  final String referenceCode;
  final String userId;
  final String? userEmail;
  final String? userDisplayName;
  final BugReportCategory category;
  final String description;
  final String expectedBehavior;
  final BugReportStatus status;
  final Map<String, dynamic> deviceInfo;
  final Map<String, dynamic> appInfo;
  final Map<String, dynamic> diagnostics;
  final String? screenshotUrl;
  final String? screenshotStoragePath;
  final String? internalNotes;
  final String? associatedFixRelease;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BugReportModel({
    required this.id,
    required this.referenceCode,
    required this.userId,
    this.userEmail,
    this.userDisplayName,
    required this.category,
    required this.description,
    required this.expectedBehavior,
    this.status = BugReportStatus.newReport,
    required this.deviceInfo,
    required this.appInfo,
    required this.diagnostics,
    this.screenshotUrl,
    this.screenshotStoragePath,
    this.internalNotes,
    this.associatedFixRelease,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Generates a human-friendly short reference code (e.g. FRM-8492-AC)
  static String generateReferenceCode([String? uuid]) {
    final seed = uuid ?? DateTime.now().millisecondsSinceEpoch.toString();
    final clean =
        seed.replaceAll('-', '').toUpperCase().padRight(8, '0').substring(0, 8);
    final part1 = clean.substring(0, 4);
    final part2 = clean.substring(4, 8);
    return 'FRM-$part1-$part2';
  }

  BugReportModel copyWith({
    String? id,
    String? referenceCode,
    String? userId,
    String? userEmail,
    String? userDisplayName,
    BugReportCategory? category,
    String? description,
    String? expectedBehavior,
    BugReportStatus? status,
    Map<String, dynamic>? deviceInfo,
    Map<String, dynamic>? appInfo,
    Map<String, dynamic>? diagnostics,
    String? screenshotUrl,
    String? screenshotStoragePath,
    String? internalNotes,
    String? associatedFixRelease,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BugReportModel(
      id: id ?? this.id,
      referenceCode: referenceCode ?? this.referenceCode,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      category: category ?? this.category,
      description: description ?? this.description,
      expectedBehavior: expectedBehavior ?? this.expectedBehavior,
      status: status ?? this.status,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      appInfo: appInfo ?? this.appInfo,
      diagnostics: diagnostics ?? this.diagnostics,
      screenshotUrl: screenshotUrl ?? this.screenshotUrl,
      screenshotStoragePath:
          screenshotStoragePath ?? this.screenshotStoragePath,
      internalNotes: internalNotes ?? this.internalNotes,
      associatedFixRelease: associatedFixRelease ?? this.associatedFixRelease,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reportId': id,
      'referenceCode': referenceCode,
      'userId': userId,
      'userEmail': userEmail,
      'userDisplayName': userDisplayName,
      'category': category.id,
      'categoryLabel': category.label,
      'description': description,
      'expectedBehavior': expectedBehavior,
      'status': status.id,
      'deviceInfo': deviceInfo,
      'appInfo': appInfo,
      'diagnostics': diagnostics,
      'screenshotUrl': screenshotUrl,
      'screenshotStoragePath': screenshotStoragePath,
      'internalNotes': internalNotes,
      'associatedFixRelease': associatedFixRelease,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'reportId': id,
      'referenceCode': referenceCode,
      'userId': userId,
      'userEmail': userEmail,
      'userDisplayName': userDisplayName,
      'category': category.id,
      'categoryLabel': category.label,
      'description': description,
      'expectedBehavior': expectedBehavior,
      'status': status.id,
      'deviceInfo': deviceInfo,
      'appInfo': appInfo,
      'diagnostics': diagnostics,
      'screenshotUrl': screenshotUrl,
      'screenshotStoragePath': screenshotStoragePath,
      'internalNotes': internalNotes,
      'associatedFixRelease': associatedFixRelease,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory BugReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BugReportModel.fromMap(data, doc.id);
  }

  factory BugReportModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final id = map['reportId'] as String? ?? docId ?? '';
    final ref = map['referenceCode'] as String? ??
        (id.length >= 8 ? generateReferenceCode(id) : 'FRM-PENDING');

    DateTime parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return BugReportModel(
      id: id,
      referenceCode: ref,
      userId: map['userId'] as String? ?? '',
      userEmail: map['userEmail'] as String?,
      userDisplayName: map['userDisplayName'] as String?,
      category: BugReportCategory.fromId(map['category'] as String?),
      description: map['description'] as String? ?? '',
      expectedBehavior: map['expectedBehavior'] as String? ?? '',
      status: BugReportStatus.fromId(map['status'] as String?),
      deviceInfo: Map<String, dynamic>.from(map['deviceInfo'] as Map? ?? {}),
      appInfo: Map<String, dynamic>.from(map['appInfo'] as Map? ?? {}),
      diagnostics: Map<String, dynamic>.from(map['diagnostics'] as Map? ?? {}),
      screenshotUrl: map['screenshotUrl'] as String?,
      screenshotStoragePath: map['screenshotStoragePath'] as String?,
      internalNotes: map['internalNotes'] as String?,
      associatedFixRelease: map['associatedFixRelease'] as String?,
      createdAt: parseTimestamp(map['createdAt']),
      updatedAt: parseTimestamp(map['updatedAt']),
    );
  }
}

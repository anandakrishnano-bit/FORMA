import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/bug_report_category.dart';
import '../models/bug_report_model.dart';
import '../models/bug_report_status.dart';
import 'device_diagnostic_service.dart';

/// Repository that handles Firestore persistence, Firebase Storage asset uploads,
/// offline draft caching, and maintainer investigation workflows.
class BugReportRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;
  final DeviceDiagnosticService _diagnosticService;

  static const String _draftPrefsKey = 'forma_bug_report_draft_v1';
  static const String collectionName = 'bugReports';

  BugReportRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
    DeviceDiagnosticService? diagnosticService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _diagnosticService = diagnosticService ?? DeviceDiagnosticService();

  /// Submits a complete bug report to Firestore and uploads its screenshot to Storage.
  Future<BugReportModel> submitReport({
    required BugReportCategory category,
    required String description,
    required String expectedBehavior,
    Uint8List? screenshotBytes,
    String? existingReportId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('You must be signed in to submit a bug report.');
    }

    // Reuse existing ID on retry to guarantee idempotent submission and prevent duplicates
    final reportId = existingReportId ?? const Uuid().v4();
    final refCode = BugReportModel.generateReferenceCode(reportId);

    String? screenshotUrl;
    String? screenshotStoragePath;

    if (screenshotBytes != null && screenshotBytes.isNotEmpty) {
      screenshotStoragePath =
          'bug-reports/${user.uid}/$reportId/screenshot.jpg';
      try {
        final ref = _storage.ref(screenshotStoragePath);
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'reportId': reportId,
            'userId': user.uid,
            'submittedAt': DateTime.now().toIso8601String(),
          },
        );

        final uploadTask = await ref.putData(screenshotBytes, metadata);
        screenshotUrl = await uploadTask.ref.getDownloadURL();
      } catch (storageError) {
        debugPrint(
            '[BugReportRepository] Cloud Storage upload failed: $storageError. Using Base64 fallback.');
        // Fallback: If Storage write is blocked or offline, save compressed Base64 inline
        // to guarantee screenshot is never lost
        final b64 = base64Encode(screenshotBytes);
        screenshotUrl = 'data:image/jpeg;base64,$b64';
      }
    }

    final deviceInfo = await _diagnosticService.collectDeviceInfo();
    final appInfo = _diagnosticService.collectAppInfo();
    final diagnostics = _diagnosticService.collectDiagnostics();

    final now = DateTime.now();
    final report = BugReportModel(
      id: reportId,
      referenceCode: refCode,
      userId: user.uid,
      userEmail: user.email,
      userDisplayName: user.displayName,
      category: category,
      description: description.trim(),
      expectedBehavior: expectedBehavior.trim(),
      status: BugReportStatus.newReport,
      deviceInfo: deviceInfo,
      appInfo: appInfo,
      diagnostics: diagnostics,
      screenshotUrl: screenshotUrl,
      screenshotStoragePath: screenshotStoragePath,
      createdAt: now,
      updatedAt: now,
    );

    // Save report document into Firestore
    await _firestore
        .collection(collectionName)
        .doc(reportId)
        .set(report.toFirestore());

    // Clear local draft after verified submission
    await clearDraft();

    return report;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // LOCAL DRAFT MANAGEMENT (PREVENTS ACCIDENTAL DATA LOSS)
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> saveDraft({
    required BugReportCategory category,
    required String description,
    required String expectedBehavior,
    Uint8List? screenshotBytes,
    String? draftId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftData = {
        'draftId': draftId ?? const Uuid().v4(),
        'category': category.id,
        'description': description,
        'expectedBehavior': expectedBehavior,
        'savedAt': DateTime.now().toIso8601String(),
        if (screenshotBytes != null)
          'screenshotBase64': base64Encode(screenshotBytes),
      };
      await prefs.setString(_draftPrefsKey, jsonEncode(draftData));
    } catch (e) {
      debugPrint('[BugReportRepository] Failed to save draft: $e');
    }
  }

  Future<Map<String, dynamic>?> loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_draftPrefsKey);
      if (raw == null || raw.isEmpty) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[BugReportRepository] Failed to load draft: $e');
      return null;
    }
  }

  Future<void> clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftPrefsKey);
    } catch (e) {
      debugPrint('[BugReportRepository] Failed to clear draft: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // USER REPORT TRACKING & MAINTAINER QUERIES
  // ═══════════════════════════════════════════════════════════════════════

  /// Stream of reports submitted by the current authenticated user.
  Stream<List<BugReportModel>> watchMyReports() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(collectionName)
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BugReportModel.fromFirestore(doc))
            .toList());
  }

  /// Stream of all reports for maintainers / developer dashboard.
  Stream<List<BugReportModel>> watchAllReports({
    BugReportStatus? statusFilter,
    BugReportCategory? categoryFilter,
  }) {
    Query query = _firestore
        .collection(collectionName)
        .orderBy('createdAt', descending: true);

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter.id);
    }

    if (categoryFilter != null) {
      query = query.where('category', isEqualTo: categoryFilter.id);
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => BugReportModel.fromFirestore(doc)).toList());
  }

  /// Updates the status of a report (maintainer only).
  Future<void> updateReportStatus(
      String reportId, BugReportStatus status) async {
    await _firestore.collection(collectionName).doc(reportId).update({
      'status': status.id,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Updates internal maintainer notes and associated fix release (maintainer only).
  Future<void> updateMaintainerNotes(
    String reportId, {
    required String notes,
    String? fixRelease,
  }) async {
    await _firestore.collection(collectionName).doc(reportId).update({
      'internalNotes': notes.trim(),
      if (fixRelease != null) 'associatedFixRelease': fixRelease.trim(),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Compliance & Privacy: Deletes all reports associated with a user UID upon account deletion.
  Future<void> deleteReportsForUser(String userId) async {
    final snapshot = await _firestore
        .collection(collectionName)
        .where('userId', isEqualTo: userId)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

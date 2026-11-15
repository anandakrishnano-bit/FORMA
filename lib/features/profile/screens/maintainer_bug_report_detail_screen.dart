import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/core/bug_report/models/bug_report_model.dart';
import 'package:forma/core/bug_report/models/bug_report_status.dart';
import 'package:forma/core/bug_report/providers/bug_report_providers.dart';

/// Detailed maintainer investigation view for a single bug report.
/// Includes interactive screenshot inspection, copyable stack traces,
/// status transitions, and private maintainer notes.
class MaintainerBugReportDetailScreen extends ConsumerStatefulWidget {
  final BugReportModel report;

  const MaintainerBugReportDetailScreen({super.key, required this.report});

  @override
  ConsumerState<MaintainerBugReportDetailScreen> createState() =>
      _MaintainerBugReportDetailScreenState();
}

class _MaintainerBugReportDetailScreenState
    extends ConsumerState<MaintainerBugReportDetailScreen> {
  late BugReportStatus _currentStatus;
  late TextEditingController _notesController;
  late TextEditingController _fixReleaseController;
  bool _isSavingNotes = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.report.status;
    _notesController =
        TextEditingController(text: widget.report.internalNotes ?? '');
    _fixReleaseController =
        TextEditingController(text: widget.report.associatedFixRelease ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    _fixReleaseController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(BugReportStatus newStatus) async {
    setState(() => _currentStatus = newStatus);
    try {
      final repo = ref.read(bugReportRepositoryProvider);
      await repo.updateReportStatus(widget.report.id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${newStatus.label}'),
            backgroundColor: FormaColors.sage,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: FormaColors.coralPink,
          ),
        );
      }
    }
  }

  Future<void> _saveNotes() async {
    setState(() => _isSavingNotes = true);
    try {
      final repo = ref.read(bugReportRepositoryProvider);
      await repo.updateMaintainerNotes(
        widget.report.id,
        notes: _notesController.text,
        fixRelease: _fixReleaseController.text.trim().isNotEmpty
            ? _fixReleaseController.text.trim()
            : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Investigation notes saved!'),
            backgroundColor: FormaColors.sage,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save notes: $e'),
            backgroundColor: FormaColors.coralPink,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingNotes = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final report = widget.report;

    return Scaffold(
      backgroundColor:
          isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
      appBar: AppBar(
        title: Text(
          report.referenceCode,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 20),
            tooltip: 'Copy reference number',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: report.referenceCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reference number copied!')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // 1. Status & Lifecycle Selector Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? FormaColors.darkCardBackground
                    : FormaColors.lightCardBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'REPORT STATUS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<BugReportStatus>(
                    initialValue: _currentStatus,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: BugReportStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Row(
                          children: [
                            Icon(status.icon,
                                size: 16, color: status.badgeColor),
                            const SizedBox(width: 8),
                            Text(
                              status.label,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: status.badgeColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (newStatus) {
                      if (newStatus != null) _updateStatus(newStatus);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Category: ${report.category.label}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? FormaColors.darkSecondaryText
                              : FormaColors.lightSecondaryText,
                        ),
                      ),
                      Text(
                        'Reported: ${_formatDate(report.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? FormaColors.darkSecondaryText
                              : FormaColors.lightSecondaryText,
                        ),
                      ),
                    ],
                  ),
                  if (report.userEmail != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Reporter: ${report.userEmail}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? FormaColors.darkSecondaryText
                            : FormaColors.lightSecondaryText,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 2. User Explanation & Expected Behavior
            _buildSectionCard(
              title: 'USER EXPLANATION',
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What went wrong:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: FormaColors.primaryAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(report.description,
                      style: const TextStyle(fontSize: 13, height: 1.4)),
                  const SizedBox(height: 12),
                  const Text(
                    'Expected behavior:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: FormaColors.sage,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(report.expectedBehavior,
                      style: const TextStyle(fontSize: 13, height: 1.4)),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 3. Screenshot Viewer
            if (report.screenshotUrl != null) ...[
              _buildSectionCard(
                title: 'SCREENSHOT ATTACHMENT',
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tap image to open full-screen pinch-to-zoom inspection.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () =>
                          _openFullScreenImage(context, report.screenshotUrl!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 280),
                          width: double.infinity,
                          color: Colors.black12,
                          child: _renderScreenshot(report.screenshotUrl!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // 4. Device & Environment Breakdown
            _buildSectionCard(
              title: 'DEVICE & ENVIRONMENT',
              isDark: isDark,
              child: Column(
                children: [
                  _buildSpecRow(
                      'Device Model',
                      '${report.deviceInfo['manufacturer'] ?? ""} ${report.deviceInfo['model'] ?? "Unknown"}',
                      isDark),
                  _buildSpecRow(
                      'Android Version',
                      'Android ${report.deviceInfo['androidRelease'] ?? ""} (API ${report.deviceInfo['sdkInt'] ?? "-"})',
                      isDark),
                  _buildSpecRow(
                      'Physical Device',
                      '${report.deviceInfo['isPhysicalDevice'] ?? true}',
                      isDark),
                  _buildSpecRow(
                      'App Version',
                      'v${report.appInfo['version'] ?? "1.0.1"} (Build ${report.appInfo['buildNumber'] ?? "2"})',
                      isDark),
                  _buildSpecRow('Reported Route',
                      '${report.appInfo['currentRoute'] ?? "/home"}', isDark),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 5. Technical Errors & Stack Trace
            _buildSectionCard(
              title: 'TECHNICAL ERRORS & LOGS',
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Last Captured Error',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.copy_rounded, size: 14),
                        label: const Text('Copy Stack',
                            style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          final err = report.diagnostics['lastError'] ??
                              'No error recorded';
                          Clipboard.setData(ClipboardData(text: err));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Error copied to clipboard')),
                          );
                        },
                      ),
                    ],
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black38
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      report.diagnostics['lastError'] ??
                          'No error recorded in buffer',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent System Logs',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.copy_rounded, size: 14),
                        label: const Text('Copy Logs',
                            style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          final logs =
                              (report.diagnostics['recentLogs'] as List?)
                                      ?.join('\n') ??
                                  'No logs';
                          Clipboard.setData(ClipboardData(text: logs));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Logs copied to clipboard')),
                          );
                        },
                      ),
                    ],
                  ),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black38
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        (report.diagnostics['recentLogs'] as List?)
                                ?.join('\n') ??
                            'No logs available',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 6. Private Maintainer Investigation Notes
            _buildSectionCard(
              title: 'PRIVATE INVESTIGATION NOTES (MAINTAINER ONLY)',
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notes and root-cause analysis entered here are completely private and never visible to ordinary users.',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey, height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          'Enter internal debugging notes, findings or PR links...',
                      hintStyle: const TextStyle(fontSize: 12),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.black.withValues(alpha: 0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _fixReleaseController,
                    decoration: InputDecoration(
                      labelText: 'Associated Fix Release (e.g. v1.0.2)',
                      isDense: true,
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.black.withValues(alpha: 0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isSavingNotes ? null : _saveNotes,
                    icon: _isSavingNotes
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded, size: 16),
                    label: const Text('Save Investigation Notes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FormaColors.primaryAccent,
                      foregroundColor: FormaColors.charcoal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? FormaColors.darkCardBackground
            : FormaColors.lightCardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? FormaColors.darkSecondaryText
                  : FormaColors.lightSecondaryText,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _renderScreenshot(String url) {
    if (url.startsWith('data:image')) {
      final base64String = url.split(',').last;
      return Image.memory(base64Decode(base64String), fit: BoxFit.contain);
    }
    return Image.network(url, fit: BoxFit.contain);
  }

  void _openFullScreenImage(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text('Screenshot Inspection',
                style: TextStyle(color: Colors.white, fontSize: 14)),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: _renderScreenshot(url),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

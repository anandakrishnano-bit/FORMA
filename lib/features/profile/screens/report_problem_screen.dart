import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:forma/core/components/forma_button.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/core/bug_report/models/bug_report_category.dart';
import 'package:forma/core/bug_report/models/bug_report_model.dart';
import 'package:forma/core/bug_report/providers/bug_report_providers.dart';
import 'package:forma/core/bug_report/services/device_diagnostic_service.dart';
import 'package:forma/core/bug_report/services/screen_capture_service.dart';

/// User-facing screen to report a problem with automatic diagnostics,
/// optional screenshot capture, draft persistence, and sensitive data redaction.
class ReportProblemScreen extends ConsumerStatefulWidget {
  const ReportProblemScreen({super.key});

  @override
  ConsumerState<ReportProblemScreen> createState() =>
      _ReportProblemScreenState();
}

class _ReportProblemScreenState extends ConsumerState<ReportProblemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _expectedController = TextEditingController();

  BugReportCategory _selectedCategory = BugReportCategory.feature;
  Uint8List? _screenshotBytes;
  bool _isAutoCaptured = false;
  bool _isSensitiveScreenBlocked = false;

  bool _isSubmitting = false;
  String? _submissionError;
  String? _draftId;

  bool _showDiagnosticsReview = false;
  Map<String, dynamic>? _previewDeviceInfo;
  Map<String, dynamic>? _previewAppInfo;

  @override
  void initState() {
    super.initState();
    _initializeFlow();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _expectedController.dispose();
    super.dispose();
  }

  Future<void> _initializeFlow() async {
    // 1. Check for sensitive screen blocking
    final captureService = ScreenCaptureService.instance;
    final isSensitive = captureService.isRouteSensitive();
    if (isSensitive) {
      setState(() => _isSensitiveScreenBlocked = true);
    } else {
      // 2. Offer automatic capture of relevant screen
      final bytes =
          await captureService.captureScreen(enforceSensitiveCheck: true);
      if (bytes != null && mounted) {
        setState(() {
          _screenshotBytes = bytes;
          _isAutoCaptured = true;
        });
      }
    }

    // 3. Check for existing saved draft
    final repo = ref.read(bugReportRepositoryProvider);
    final draft = await repo.loadDraft();
    if (draft != null && mounted) {
      setState(() {
        _draftId = draft['draftId'] as String?;
        if (draft['category'] != null) {
          _selectedCategory =
              BugReportCategory.fromId(draft['category'] as String);
        }
        _descriptionController.text = draft['description'] as String? ?? '';
        _expectedController.text = draft['expectedBehavior'] as String? ?? '';
        if (_screenshotBytes == null && draft['screenshotBase64'] != null) {
          _screenshotBytes = base64Decode(draft['screenshotBase64'] as String);
          _isAutoCaptured = false;
        }
      });
    }

    // 4. Preload diagnostic preview for transparency
    final diag = DeviceDiagnosticService();
    final devInfo = await diag.collectDeviceInfo();
    final appInfo = diag.collectAppInfo();
    if (mounted) {
      setState(() {
        _previewDeviceInfo = devInfo;
        _previewAppInfo = appInfo;
      });
    }
  }

  Future<void> _saveDraftSilently() async {
    if (_descriptionController.text.isEmpty &&
        _expectedController.text.isEmpty) {
      return;
    }
    final repo = ref.read(bugReportRepositoryProvider);
    await repo.saveDraft(
      category: _selectedCategory,
      description: _descriptionController.text,
      expectedBehavior: _expectedController.text,
      screenshotBytes: _screenshotBytes,
      draftId: _draftId,
    );
  }

  Future<void> _pickFromGallery() async {
    final bytes = await ScreenCaptureService.instance.pickFromGallery();
    if (bytes != null && mounted) {
      setState(() {
        _screenshotBytes = bytes;
        _isAutoCaptured = false;
      });
      _saveDraftSilently();
    }
  }

  Future<void> _captureWithCamera() async {
    final bytes = await ScreenCaptureService.instance.captureWithCamera();
    if (bytes != null && mounted) {
      setState(() {
        _screenshotBytes = bytes;
        _isAutoCaptured = false;
      });
      _saveDraftSilently();
    }
  }

  void _removeScreenshot() {
    setState(() {
      _screenshotBytes = null;
      _isAutoCaptured = false;
    });
    _saveDraftSilently();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });

    try {
      final repo = ref.read(bugReportRepositoryProvider);
      final report = await repo.submitReport(
        category: _selectedCategory,
        description: _descriptionController.text,
        expectedBehavior: _expectedController.text,
        screenshotBytes: _screenshotBytes,
        existingReportId: _draftId,
      );

      if (!mounted) return;
      _showSuccessDialog(report);
    } catch (e) {
      if (!mounted) return;
      // Preserve draft on failure
      await _saveDraftSilently();
      setState(() {
        _isSubmitting = false;
        _submissionError =
            'Unable to send report: $e\nYour draft has been preserved.';
      });
    }
  }

  void _showSuccessDialog(BugReportModel report) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark
            ? FormaColors.darkCardBackground
            : FormaColors.lightCardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: FormaColors.sage.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: FormaColors.sage, size: 26),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Report Submitted',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thank you for helping us improve FORMA. Your problem report and technical diagnostics have been securely received.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black26
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: FormaColors.primaryAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'REFERENCE NUMBER',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: FormaColors.primaryAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        report.referenceCode,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        tooltip: 'Copy reference number',
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: report.referenceCode));
                          ScaffoldMessenger.of(dialogCtx).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Reference number copied to clipboard!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.pop();
            },
            child: const Text('Done',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      onPopInvokedWithResult: (_, __) => _saveDraftSilently(),
      child: Scaffold(
        backgroundColor:
            isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
        appBar: AppBar(
          title: const Text(
            'Report a Problem',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Clear draft',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Clear Draft?'),
                    content: const Text(
                        'This will discard your current report draft.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('Clear',
                            style: TextStyle(color: FormaColors.coralPink)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  _descriptionController.clear();
                  _expectedController.clear();
                  _removeScreenshot();
                  await ref.read(bugReportRepositoryProvider).clearDraft();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Draft cleared')),
                    );
                  }
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // Error Alert if submission failed
                if (_submissionError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: FormaColors.coralPink.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: FormaColors.coralPink.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: FormaColors.coralPink, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _submissionError!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? FormaColors.darkPrimaryText
                                  : FormaColors.lightPrimaryText,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 1. Problem Category Selector
                _buildFieldLabel(
                    'WHAT TYPE OF ISSUE ARE YOU EXPERIENCING?', isDark),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: BugReportCategory.values.map((category) {
                    final isSelected = category == _selectedCategory;
                    return ChoiceChip(
                      selected: isSelected,
                      showCheckmark: false,
                      avatar: Icon(
                        category.icon,
                        size: 16,
                        color: isSelected
                            ? (isDark ? FormaColors.charcoal : Colors.white)
                            : (isDark
                                ? FormaColors.darkSecondaryText
                                : FormaColors.lightSecondaryText),
                      ),
                      label: Text(
                        category.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? (isDark ? FormaColors.charcoal : Colors.white)
                              : (isDark
                                  ? FormaColors.darkPrimaryText
                                  : FormaColors.lightPrimaryText),
                        ),
                      ),
                      selectedColor: isDark
                          ? FormaColors.primaryAccent
                          : FormaColors.charcoal,
                      backgroundColor: isDark
                          ? FormaColors.darkCardBackground
                          : FormaColors.lightCardBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? Colors.transparent
                              : (isDark ? Colors.white10 : Colors.black12),
                        ),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = category);
                          _saveDraftSilently();
                        }
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // 2. What went wrong?
                _buildFieldLabel('WHAT WENT WRONG?', isDark),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  onChanged: (_) => _saveDraftSilently(),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please describe what happened';
                    }
                    if (val.trim().length < 8) {
                      return 'Please provide a little more detail (at least 8 characters)';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText:
                        'e.g. When tapping on "Add Expense", the page froze and returned back to the Home screen.',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? FormaColors.darkSecondaryText.withValues(alpha: 0.6)
                          : FormaColors.lightSecondaryText
                              .withValues(alpha: 0.6),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? FormaColors.darkCardBackground
                        : FormaColors.lightCardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: FormaColors.primaryAccent,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 3. What did you expect to happen?
                _buildFieldLabel('WHAT DID YOU EXPECT TO HAPPEN?', isDark),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _expectedController,
                  maxLines: 2,
                  onChanged: (_) => _saveDraftSilently(),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please tell us what should have happened';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText:
                        'e.g. The split expense creation screen should have opened so I could add participants.',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? FormaColors.darkSecondaryText.withValues(alpha: 0.6)
                          : FormaColors.lightSecondaryText
                              .withValues(alpha: 0.6),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? FormaColors.darkCardBackground
                        : FormaColors.lightCardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: FormaColors.primaryAccent,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 4. Screenshot Attachment Section
                _buildFieldLabel('SCREENSHOT (OPTIONAL)', isDark),
                const SizedBox(height: 8),

                if (_isSensitiveScreenBlocked && _screenshotBytes == null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: FormaColors.goldenYellow.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: FormaColors.goldenYellow.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.shield_rounded,
                            color: FormaColors.goldenYellow, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Automatic screenshot disabled: Sensitive authentication or security screen detected.',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                if (_screenshotBytes != null) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? FormaColors.darkCardBackground
                          : FormaColors.lightCardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _isAutoCaptured
                                    ? FormaColors.sage.withValues(alpha: 0.2)
                                    : FormaColors.primaryAccent
                                        .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _isAutoCaptured
                                    ? 'AUTO-CAPTURED'
                                    : 'ATTACHED IMAGE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: _isAutoCaptured
                                      ? FormaColors.sage
                                      : FormaColors.primaryAccent,
                                ),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              tooltip: 'Remove screenshot',
                              onPressed: _removeScreenshot,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 220),
                            width: double.infinity,
                            color: Colors.black12,
                            child: Image.memory(
                              _screenshotBytes!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: _pickFromGallery,
                              icon: const Icon(Icons.photo_library_outlined,
                                  size: 15),
                              label: const Text('Replace',
                                  style: TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: _removeScreenshot,
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 15, color: FormaColors.coralPink),
                              label: const Text('Remove',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: FormaColors.coralPink)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickFromGallery,
                          icon:
                              const Icon(Icons.photo_library_rounded, size: 18),
                          label: const Text('Add Screenshot',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.outlined(
                        onPressed: _captureWithCamera,
                        icon: const Icon(Icons.camera_alt_rounded),
                        tooltip: 'Take photo with camera',
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),

                // 5. Expandable Transparency Card: Included Diagnostics
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? FormaColors.darkCardBackground
                        : FormaColors.lightCardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black12,
                    ),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info_outline_rounded,
                            color: FormaColors.primaryAccent),
                        title: const Text(
                          'Included Diagnostic Data',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        subtitle: const Text(
                          'Tap to review device specs & sanitized logs',
                          style: TextStyle(fontSize: 11),
                        ),
                        trailing: Icon(
                          _showDiagnosticsReview
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                        ),
                        onTap: () {
                          setState(() {
                            _showDiagnosticsReview = !_showDiagnosticsReview;
                          });
                        },
                      ),
                      if (_showDiagnosticsReview) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDiagRow(
                                  'App Version',
                                  '${_previewAppInfo?['version'] ?? "1.0.1"} (Build ${_previewAppInfo?['buildNumber'] ?? "2"})',
                                  isDark),
                              _buildDiagRow(
                                  'Device',
                                  '${_previewDeviceInfo?['manufacturer'] ?? ""} ${_previewDeviceInfo?['model'] ?? "Android"}',
                                  isDark),
                              _buildDiagRow(
                                  'Android OS',
                                  'Android ${_previewDeviceInfo?['androidRelease'] ?? "Unknown"} (API ${_previewDeviceInfo?['sdkInt'] ?? "-"})',
                                  isDark),
                              _buildDiagRow(
                                  'Active Screen',
                                  '${_previewAppInfo?['currentRoute'] ?? "/home"}',
                                  isDark),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : Colors.black.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.lock_outline_rounded,
                                        size: 14,
                                        color: FormaColors.primaryAccent),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'All sensitive tokens, passwords, OTPs, and personal records are automatically scrubbed.',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 6. Submit Button
                FormaButton(
                  label: _isSubmitting ? 'Sending Report...' : 'Submit Report',
                  variant: FormaButtonVariant.primary,
                  onPressed: _isSubmitting ? null : _submitReport,
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: isDark
            ? FormaColors.darkSecondaryText
            : FormaColors.lightSecondaryText,
      ),
    );
  }

  Widget _buildDiagRow(String title, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
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
}

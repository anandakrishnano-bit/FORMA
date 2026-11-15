import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/core/theme/app_spacing.dart';
import 'package:forma/core/components/forma_button.dart';
import 'package:forma/core/components/forma_text_field.dart';
import 'package:forma/data/models/muscle_tracker_model.dart';
import 'package:forma/data/repositories/muscle_tracker_repository.dart';
import 'package:forma/features/authentication/providers/auth_providers.dart';

class LogMuscleGroupsScreen extends ConsumerStatefulWidget {
  final DateTime? initialDate;

  const LogMuscleGroupsScreen({super.key, this.initialDate});

  @override
  ConsumerState<LogMuscleGroupsScreen> createState() =>
      _LogMuscleGroupsScreenState();
}

class _LogMuscleGroupsScreenState extends ConsumerState<LogMuscleGroupsScreen> {
  final _titleController = TextEditingController(text: 'Gym Workout');
  final _exercisesController = TextEditingController();
  final _noteController = TextEditingController();

  late DateTime _selectedDate;
  final Set<String> _selectedMuscles = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _exercisesController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: FormaColors.primaryAccent,
                    onPrimary: FormaColors.charcoal,
                    surface: FormaColors.charcoal,
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: FormaColors.primaryAccent,
                    onPrimary: FormaColors.charcoal,
                    surface: Colors.white,
                  ),
                ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  void _toggleMuscle(String muscleName) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedMuscles.contains(muscleName)) {
        _selectedMuscles.remove(muscleName);
      } else {
        _selectedMuscles.add(muscleName);
      }
    });
  }

  Future<void> _handleSave() async {
    final user = ref.read(currentFirebaseUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to log muscle groups.')),
      );
      return;
    }

    if (_selectedMuscles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one trained muscle group.'),
          backgroundColor: FormaColors.coralPink,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final exercises = _exercisesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final log = MuscleTrainingLog(
        id: '',
        userId: user.uid,
        workoutDate: _selectedDate,
        muscleGroups: _selectedMuscles.toList(),
        workoutTitle: _titleController.text.trim().isEmpty
            ? 'Muscle Training Session'
            : _titleController.text.trim(),
        contributingExercises: exercises,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        source: 'manual_log',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(muscleTrackerRepositoryProvider).logMuscleTraining(log);

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Logged ${_selectedMuscles.length} muscle groups successfully!',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: FormaColors.charcoal,
              ),
            ),
            backgroundColor: FormaColors.primaryAccent,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save log: $e'),
            backgroundColor: FormaColors.coralPink,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? FormaColors.darkPrimaryText : FormaColors.charcoal,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Log Muscle Groups',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: isDark ? FormaColors.darkPrimaryText : FormaColors.charcoal,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: FormaSpacing.lg,
          vertical: 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Selector Bar
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? FormaColors.charcoal : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : FormaColors.concreteGrey.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: FormaColors.primaryAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Session Date',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? FormaColors.darkSecondaryText
                                  : FormaColors.lightSecondaryText,
                            ),
                          ),
                          Text(
                            DateFormat('EEEE, MMM d, yyyy')
                                .format(_selectedDate),
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color:
                                  isDark ? Colors.white : FormaColors.charcoal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.edit_calendar_rounded,
                      size: 18,
                      color: FormaColors.concreteGrey,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Session Title
            FormaTextField(
              hint: 'Workout Title (e.g. Push Hypertrophy, Legs)',
              controller: _titleController,
              prefixIcon: Icons.fitness_center_rounded,
            ),
            const SizedBox(height: 24),

            // Muscle Multi-Selector Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Trained Muscles',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: isDark ? Colors.white : FormaColors.charcoal,
                  ),
                ),
                Text(
                  '${_selectedMuscles.length} selected',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: FormaColors.primaryAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Muscle Groups Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.2,
              ),
              itemCount: MajorMuscleGroup.all.length,
              itemBuilder: (context, index) {
                final group = MajorMuscleGroup.all[index];
                final isSelected = _selectedMuscles.contains(group.name);

                return GestureDetector(
                  onTap: () => _toggleMuscle(group.name),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? group.color.withValues(alpha: 0.18)
                          : (isDark
                              ? FormaColors.charcoal.withValues(alpha: 0.6)
                              : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? group.color
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : FormaColors.concreteGrey
                                    .withValues(alpha: 0.2)),
                        width: isSelected ? 1.8 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: group.color.withValues(alpha: 0.2),
                          ),
                          child: Icon(
                            group.icon,
                            size: 16,
                            color: group.color,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            group.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: isSelected
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                              fontSize: 13,
                              color:
                                  isDark ? Colors.white : FormaColors.charcoal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: group.color,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Exercises (Optional)
            FormaTextField(
              hint: 'Contributing exercises (comma-separated, optional)',
              controller: _exercisesController,
              prefixIcon: Icons.list_alt_rounded,
            ),
            const SizedBox(height: 14),

            // Note (Optional)
            FormaTextField(
              hint: 'Session note (intensity, sets, pumps...)',
              controller: _noteController,
              prefixIcon: Icons.notes_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Save Button
            FormaButton(
              label: 'Save Muscle Training Session',
              onPressed: _isSaving ? null : _handleSave,
              isLoading: _isSaving,
              icon: Icons.check_rounded,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

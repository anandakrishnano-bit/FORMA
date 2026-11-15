import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/core/theme/app_spacing.dart';
import 'package:forma/core/components/forma_button.dart';
import 'package:forma/data/models/muscle_tracker_model.dart';
import 'package:forma/data/repositories/muscle_tracker_repository.dart';
import 'package:forma/features/authentication/providers/auth_providers.dart';

class BodySettingsScreen extends ConsumerStatefulWidget {
  const BodySettingsScreen({super.key});

  @override
  ConsumerState<BodySettingsScreen> createState() => _BodySettingsScreenState();
}

class _BodySettingsScreenState extends ConsumerState<BodySettingsScreen> {
  String _units = 'metric';
  String _experienceLevel = 'Intermediate';
  final Set<String> _trainingInterests = {'Hypertrophy', 'Strength'};
  final Set<String> _priorityMuscles = {'Chest', 'Back', 'Quadriceps'};
  bool _enableHealthConnect = false;
  bool _isSaving = false;
  bool _loaded = false;

  final List<String> _availableInterests = [
    'Hypertrophy',
    'Strength',
    'Endurance',
    'Powerlifting',
    'Mobility & Flexibility',
    'Functional Fitness',
    'Calisthenics',
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final user = ref.read(currentFirebaseUserProvider);
    if (user == null) return;

    final prefs = await ref
        .read(muscleTrackerRepositoryProvider)
        .getBodyPreferences(user.uid);
    if (mounted) {
      setState(() {
        _units = prefs.units;
        _experienceLevel = prefs.experienceLevel;
        _trainingInterests.clear();
        _trainingInterests.addAll(prefs.trainingInterests);
        _priorityMuscles.clear();
        _priorityMuscles.addAll(prefs.priorityMuscles);
        _enableHealthConnect = prefs.enableHealthConnect;
        _loaded = true;
      });
    }
  }

  Future<void> _savePreferences() async {
    final user = ref.read(currentFirebaseUserProvider);
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final prefs = BodyPreferences(
        units: _units,
        experienceLevel: _experienceLevel,
        trainingInterests: _trainingInterests.toList(),
        priorityMuscles: _priorityMuscles.toList(),
        enableHealthConnect: _enableHealthConnect,
      );

      await ref
          .read(muscleTrackerRepositoryProvider)
          .saveBodyPreferences(prefs);

      // Invalidate provider so listeners refresh
      ref.invalidate(bodyPreferencesProvider);

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Body & Activity settings saved successfully!',
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
            content: Text('Failed to save settings: $e'),
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
          'Body & Activity Settings',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: isDark ? FormaColors.darkPrimaryText : FormaColors.charcoal,
          ),
        ),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: FormaSpacing.lg,
                vertical: 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Unit Selection
                  Text(
                    'Measurement Units',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isDark ? Colors.white : FormaColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildUnitOption(
                          label: 'Metric',
                          sub: 'kg, cm, ml',
                          value: 'metric',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildUnitOption(
                          label: 'Imperial',
                          sub: 'lbs, inches, fl oz',
                          value: 'imperial',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Experience Level
                  Text(
                    'Experience Level',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isDark ? Colors.white : FormaColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: ['Beginner', 'Intermediate', 'Advanced']
                        .map(
                          (level) => Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: ChoiceChip(
                                label: Center(
                                  child: Text(
                                    level,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: _experienceLevel == level
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      fontSize: 12,
                                      color: _experienceLevel == level
                                          ? FormaColors.charcoal
                                          : (isDark
                                              ? Colors.white70
                                              : FormaColors.charcoal),
                                    ),
                                  ),
                                ),
                                selected: _experienceLevel == level,
                                selectedColor: FormaColors.primaryAccent,
                                backgroundColor: isDark
                                    ? FormaColors.charcoal
                                    : Colors.white,
                                onSelected: (sel) {
                                  if (sel) {
                                    HapticFeedback.selectionClick();
                                    setState(() => _experienceLevel = level);
                                  }
                                },
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),

                  // Training Interests
                  Text(
                    'Training Interests',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isDark ? Colors.white : FormaColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableInterests.map((interest) {
                      final isSelected = _trainingInterests.contains(interest);
                      return FilterChip(
                        label: Text(interest),
                        selected: isSelected,
                        selectedColor: FormaColors.primaryAccent,
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 12,
                          color: isSelected
                              ? FormaColors.charcoal
                              : (isDark
                                  ? Colors.white70
                                  : FormaColors.charcoal),
                        ),
                        backgroundColor:
                            isDark ? FormaColors.charcoal : Colors.white,
                        onSelected: (val) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (val) {
                              _trainingInterests.add(interest);
                            } else {
                              _trainingInterests.remove(interest);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Priority Muscle Groups
                  Text(
                    'Priority Muscle Focus',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isDark ? Colors.white : FormaColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select muscles you are prioritizing in your current mesocycle.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? FormaColors.darkSecondaryText
                          : FormaColors.lightSecondaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: MajorMuscleGroup.all.map((group) {
                      final isSelected = _priorityMuscles.contains(group.name);
                      return FilterChip(
                        avatar: Icon(
                          group.icon,
                          size: 14,
                          color:
                              isSelected ? FormaColors.charcoal : group.color,
                        ),
                        label: Text(group.name),
                        selected: isSelected,
                        selectedColor: FormaColors.primaryAccent,
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 12,
                          color: isSelected
                              ? FormaColors.charcoal
                              : (isDark ? Colors.white : FormaColors.charcoal),
                        ),
                        backgroundColor:
                            isDark ? FormaColors.charcoal : Colors.white,
                        onSelected: (val) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (val) {
                              _priorityMuscles.add(group.name);
                            } else {
                              _priorityMuscles.remove(group.name);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),

                  // Health Connect Sync Toggle
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? FormaColors.charcoal : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : FormaColors.concreteGrey.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: FormaColors.primaryAccent
                                    .withValues(alpha: 0.15),
                              ),
                              child: const Icon(
                                Icons.sync_rounded,
                                color: FormaColors.primaryAccent,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Google Health Connect Sync',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.white
                                        : FormaColors.charcoal,
                                  ),
                                ),
                                Text(
                                  'Sync active calories and water logs',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? FormaColors.darkSecondaryText
                                        : FormaColors.lightSecondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Switch(
                          value: _enableHealthConnect,
                          activeThumbColor: FormaColors.primaryAccent,
                          onChanged: (val) {
                            HapticFeedback.selectionClick();
                            setState(() => _enableHealthConnect = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  FormaButton(
                    label: 'Save Body & Activity Settings',
                    onPressed: _isSaving ? null : _savePreferences,
                    isLoading: _isSaving,
                    icon: Icons.check_rounded,
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
    );
  }

  Widget _buildUnitOption({
    required String label,
    required String sub,
    required String value,
    required bool isDark,
  }) {
    final isSelected = _units == value;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _units = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? FormaColors.primaryAccent.withValues(alpha: 0.15)
              : (isDark ? FormaColors.charcoal : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? FormaColors.primaryAccent
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : FormaColors.concreteGrey.withValues(alpha: 0.2)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: isSelected
                    ? FormaColors.primaryAccent
                    : (isDark ? Colors.white : FormaColors.charcoal),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? FormaColors.darkSecondaryText
                    : FormaColors.lightSecondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

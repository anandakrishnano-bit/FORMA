import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forma/core/theme/app_colors.dart';

/// Polished Workout Completion Dialog
///
/// Clean, celebratory milestone dialog providing genuine feedback
/// on workout duration, exercises completed, and volume lifted.
class WorkoutCompletionDialog extends StatelessWidget {
  final String workoutName;
  final Duration duration;
  final int exercisesCompleted;
  final double totalVolumeKg;
  final VoidCallback onDismiss;

  const WorkoutCompletionDialog({
    super.key,
    required this.workoutName,
    required this.duration,
    required this.exercisesCompleted,
    required this.totalVolumeKg,
    required this.onDismiss,
  });

  static Future<void> show({
    required BuildContext context,
    required String workoutName,
    required Duration duration,
    required int exercisesCompleted,
    required double totalVolumeKg,
    required VoidCallback onDismiss,
  }) {
    HapticFeedback.heavyImpact();
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 340),
      pageBuilder: (context, anim, secAnim) {
        return WorkoutCompletionDialog(
          workoutName: workoutName,
          duration: duration,
          exercisesCompleted: exercisesCompleted,
          totalVolumeKg: totalVolumeKg,
          onDismiss: onDismiss,
        );
      },
      transitionBuilder: (context, anim, secAnim, child) {
        final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curve,
          child: FadeTransition(
            opacity: anim,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final minutes = duration.inMinutes;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.88,
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? FormaColors.darkCardBackground : Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Checkmark pill node
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: FormaColors.goldenYellow,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_rounded,
                    size: 36,
                    color: FormaColors.charcoal,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Workout Complete',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark
                      ? FormaColors.darkPrimaryText
                      : FormaColors.lightPrimaryText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                workoutName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? FormaColors.darkSecondaryText
                      : FormaColors.lightSecondaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Genuine summary metrics
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : const Color(0xFFF7F4EC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetric('$minutes', 'MINUTES', isDark),
                    Container(
                        height: 32,
                        width: 1,
                        color: isDark ? Colors.white12 : Colors.black12),
                    _buildMetric('$exercisesCompleted', 'EXERCISES', isDark),
                    Container(
                        height: 32,
                        width: 1,
                        color: isDark ? Colors.white12 : Colors.black12),
                    _buildMetric(
                        '${totalVolumeKg.toInt()} kg', 'VOLUME', isDark),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onDismiss();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FormaColors.charcoal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save & Done',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String value, String label, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark
                ? FormaColors.darkPrimaryText
                : FormaColors.lightPrimaryText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: isDark
                ? FormaColors.darkSecondaryText
                : FormaColors.lightSecondaryText,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forma/core/theme/app_colors.dart';

/// Inspiring Weekly Date Selector (Reference Image 2 Fidelity)
///
/// Features:
/// - Editorial typography: Weekday abbreviation above date number.
/// - Minimalist aesthetic: Uncluttered warm surface without repetitive boxed cards.
/// - Active day highlighted by a circular warm-gold (#FFC443) badge.
/// - Tactile haptic feedback on selection.
class FormaCalendar extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const FormaCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Generate 7 days for the week containing selectedDate (Mon-Sun)
    final firstDayOfWeek =
        selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    final days =
        List.generate(7, (index) => firstDayOfWeek.add(Duration(days: index)));
    const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: days.map((date) {
          final isSelected = date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;
          final dayName = weekDays[date.weekday - 1];
          final isToday = date.year == DateTime.now().year &&
              date.month == DateTime.now().month &&
              date.day == DateTime.now().day;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onDateSelected(date);
            },
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 44,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? (isDark
                              ? FormaColors.darkPrimaryText
                              : FormaColors.lightPrimaryText)
                          : (isDark
                              ? FormaColors.darkSecondaryText
                              : FormaColors.lightSecondaryText),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? FormaColors.goldenYellow
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: FormaColors.goldenYellow
                                    .withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? FormaColors.charcoal
                              : (isDark
                                  ? FormaColors.darkPrimaryText
                                  : FormaColors.lightPrimaryText),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Subtle indicator dot for today if not actively selected
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isToday && !isSelected
                          ? FormaColors.goldenYellow
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

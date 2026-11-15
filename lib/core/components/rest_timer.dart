import 'dart:async';
import 'package:flutter/material.dart';
import 'package:forma/core/theme/app_colors.dart';

class RestTimerModal extends StatefulWidget {
  final int initialSeconds;
  final VoidCallback? onComplete;

  const RestTimerModal({
    super.key,
    this.initialSeconds = 60,
    this.onComplete,
  });

  @override
  State<RestTimerModal> createState() => _RestTimerModalState();
}

class _RestTimerModalState extends State<RestTimerModal> {
  late int _remaining;
  late int _total;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.initialSeconds;
    _total = widget.initialSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining > 0) {
        setState(() {
          _remaining--;
        });
      } else {
        _timer?.cancel();
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = _total > 0 ? _remaining / _total : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color:
            isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: FormaColors.concreteGrey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'REST TIME',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: isDark
                  ? FormaColors.darkSecondaryText
                  : FormaColors.lightSecondaryText,
            ),
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: progress, end: progress),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return CircularProgressIndicator(
                      value: value,
                      strokeWidth: 8,
                      backgroundColor: isDark
                          ? FormaColors.charcoal
                          : FormaColors.lightSecondaryBackground,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          FormaColors.primaryAccent),
                    );
                  },
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_remaining',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: isDark
                          ? FormaColors.darkPrimaryText
                          : FormaColors.lightPrimaryText,
                    ),
                  ),
                  Text(
                    'SEC',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? FormaColors.darkSecondaryText
                          : FormaColors.lightSecondaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _remaining += 30;
                    _total += 30;
                  });
                },
                child: const Text('+30s',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: FormaColors.primaryAccent,
                  foregroundColor: FormaColors.charcoal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Skip Rest',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

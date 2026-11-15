import 'package:flutter/material.dart';
import 'package:forma/core/theme/app_colors.dart';

enum SyncStatus { synced, syncing, error }

class SyncIndicator extends StatelessWidget {
  final SyncStatus status;
  final VoidCallback? onRetry;

  const SyncIndicator({
    super.key,
    this.status = SyncStatus.synced,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case SyncStatus.synced:
        return Tooltip(
          message: 'All changes synced',
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: FormaColors.success,
              shape: BoxShape.circle,
            ),
          ),
        );
      case SyncStatus.syncing:
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor:
                AlwaysStoppedAnimation<Color>(FormaColors.primaryAccent),
          ),
        );
      case SyncStatus.error:
        return GestureDetector(
          onTap: onRetry,
          child: Tooltip(
            message: 'Sync error. Tap to retry.',
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: FormaColors.coralPink,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
    }
  }
}

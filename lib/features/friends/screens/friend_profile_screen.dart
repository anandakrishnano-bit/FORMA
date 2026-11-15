import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forma/core/components/forma_avatar.dart';
import 'package:forma/core/components/forma_bounceable.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/models/friends_model.dart';
import 'package:forma/data/repositories/friends_social_repository.dart';

/// Detailed Friend Profile Screen with Card-to-Detail Hero morph.
///
/// STRICT PRIVACY ENFORCEMENT:
/// - Never exposes email addresses, phone numbers, personal budgets/expenses, or food logs.
/// - Only shows verified public training stats if [friend.shareWorkouts] is true.
class FriendProfileScreen extends ConsumerStatefulWidget {
  final FriendUser friend;

  const FriendProfileScreen({
    super.key,
    required this.friend,
  });

  @override
  ConsumerState<FriendProfileScreen> createState() =>
      _FriendProfileScreenState();
}

class _FriendProfileScreenState extends ConsumerState<FriendProfileScreen> {
  bool _isLoading = false;

  Future<void> _handleRemoveFriend() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text(
          'Are you sure you want to remove ${widget.friend.displayName} from your friends?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: FormaColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      final success = await ref
          .read(friendsSocialRepositoryProvider)
          .removeFriend(widget.friend.uid);

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Removed ${widget.friend.displayName} from friends.'),
              backgroundColor: FormaColors.charcoal,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleBlockUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block User'),
        content: Text(
          'Are you sure you want to block ${widget.friend.displayName}? They will not be able to find you or send requests.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: FormaColors.error),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      final success = await ref
          .read(friendsSocialRepositoryProvider)
          .blockUser(widget.friend.uid);

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Blocked ${widget.friend.displayName}.'),
              backgroundColor: FormaColors.charcoal,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleReportUser() async {
    final reasonController = TextEditingController();
    String selectedReason = 'Inappropriate content';

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Report User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select a reason:'),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: selectedReason,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                      value: 'Inappropriate content',
                      child: Text('Inappropriate content')),
                  DropdownMenuItem(
                      value: 'Spam or harassment',
                      child: Text('Spam or harassment')),
                  DropdownMenuItem(
                      value: 'Impersonation', child: Text('Impersonation')),
                  DropdownMenuItem(
                      value: 'Other violation', child: Text('Other violation')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedReason = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  hintText: 'Additional details (optional)...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: FormaColors.error),
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );

    if (submitted == true && mounted) {
      final success =
          await ref.read(friendsSocialRepositoryProvider).reportUser(
                targetUid: widget.friend.uid,
                reason: selectedReason,
                details: reasonController.text.trim(),
              );
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Report submitted. Thank you for keeping FORMA safe.'),
            backgroundColor: FormaColors.charcoal,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final friend = widget.friend;

    return Scaffold(
      backgroundColor:
          isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
      appBar: AppBar(
        title: const Text('Friend Profile',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'report') _handleReportUser();
              if (value == 'block') _handleBlockUser();
              if (value == 'remove') _handleRemoveFriend();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined,
                        size: 18, color: FormaColors.concreteGrey),
                    SizedBox(width: 10),
                    Text('Report User'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block_rounded,
                        size: 18, color: FormaColors.error),
                    SizedBox(width: 10),
                    Text('Block User',
                        style: TextStyle(color: FormaColors.error)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.person_remove_rounded,
                        size: 18, color: FormaColors.error),
                    SizedBox(width: 10),
                    Text('Remove Friend',
                        style: TextStyle(color: FormaColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Hero Avatar
              Center(
                child: Hero(
                  tag: 'friend_avatar_${friend.uid}',
                  child: FormaAvatar(
                    photoUrl: friend.avatarUrl ?? friend.photoUrl,
                    name: friend.displayName,
                    size: 96,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Display Name
              Text(
                friend.displayName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? FormaColors.darkPrimaryText
                      : FormaColors.lightPrimaryText,
                ),
              ),
              if (friend.username.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '@${friend.username}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? FormaColors.darkSecondaryText
                        : FormaColors.lightSecondaryText,
                  ),
                ),
              ],
              const SizedBox(height: 10),

              // Friend Code Badge
              if (friend.friendCode.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: FormaColors.goldenYellow.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.qr_code_rounded,
                          size: 16, color: FormaColors.goldenYellow),
                      const SizedBox(width: 6),
                      Text(
                        friend.friendCode,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: isDark
                              ? FormaColors.goldenYellow
                              : const Color(0xFF7A5400),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Bio / Statement Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? FormaColors.charcoal : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : FormaColors.divider.withValues(alpha: 0.6),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.fitness_center_rounded,
                            size: 18, color: FormaColors.primaryAccent),
                        const SizedBox(width: 8),
                        Text(
                          'ATHLETE PROFILE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: FormaColors.primaryAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      friend.bio != null && friend.bio!.isNotEmpty
                          ? friend.bio!
                          : 'Training with FORMA to achieve strength, endurance, and consistency.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: isDark
                            ? FormaColors.darkPrimaryText
                            : FormaColors.lightPrimaryText,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Privacy-Compliant Activity Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? FormaColors.charcoal : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : FormaColors.divider.withValues(alpha: 0.6),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shield_outlined,
                            size: 18, color: FormaColors.secondaryAccent),
                        const SizedBox(width: 8),
                        Text(
                          'PRIVACY & VERIFIED STATS',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: FormaColors.secondaryAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (friend.shareWorkouts)
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 16, color: FormaColors.success),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Verified workouts and milestones shared with mutual friends.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? FormaColors.darkSecondaryText
                                    : FormaColors.lightSecondaryText,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          const Icon(Icons.lock_rounded,
                              size: 16, color: FormaColors.concreteGrey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This athlete keeps their training sessions private.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? FormaColors.darkSecondaryText
                                    : FormaColors.lightSecondaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.verified_user_rounded,
                            size: 16, color: FormaColors.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Personal expenses, nutrition diary, and health vitals are private to each user account.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? FormaColors.darkSecondaryText
                                  : FormaColors.lightSecondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Remove Friend Button
              FormaBounceable(
                onTap: _isLoading ? null : _handleRemoveFriend,
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: FormaColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: FormaColors.error),
                          )
                        : const Text(
                            'Remove Friend',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: FormaColors.error,
                            ),
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
}

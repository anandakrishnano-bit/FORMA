import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:forma/core/components/forma_avatar.dart';
import 'package:forma/core/components/forma_bounceable.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/models/friends_model.dart';
import 'package:forma/data/repositories/friends_social_repository.dart';

class GroupDetailsScreen extends ConsumerStatefulWidget {
  final SocialGroup group;

  const GroupDetailsScreen({super.key, required this.group});

  @override
  ConsumerState<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends ConsumerState<GroupDetailsScreen> {
  bool _isLoading = false;

  void _copyGroupCode() {
    Clipboard.setData(ClipboardData(text: widget.group.joinCode));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Group invite code ${widget.group.joinCode} copied!'),
        backgroundColor: FormaColors.charcoal,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareGroupCode() {
    SharePlus.instance.share(
      ShareParams(
        text:
            'Join my private training group "${widget.group.name}" on FORMA! Use join code: ${widget.group.joinCode}',
      ),
    );
  }

  Future<void> _handleLeaveGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Group'),
        content: Text('Are you sure you want to leave "${widget.group.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: FormaColors.error),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      final ok = await ref
          .read(friendsSocialRepositoryProvider)
          .leaveGroup(widget.group.id);
      if (mounted) {
        setState(() => _isLoading = false);
        if (ok) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Left "${widget.group.name}".')),
          );
        }
      }
    }
  }

  Future<void> _handleDeleteGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text(
          'Are you sure you want to delete "${widget.group.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: FormaColors.error),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      final ok = await ref
          .read(friendsSocialRepositoryProvider)
          .deleteGroup(widget.group.id);
      if (mounted) {
        setState(() => _isLoading = false);
        if (ok) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted "${widget.group.name}".')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final group = widget.group;
    final currentUserId =
        ref.read(friendsSocialRepositoryProvider).currentUserId;
    final isOwner = group.ownerId == currentUserId;

    return Scaffold(
      backgroundColor:
          isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
      appBar: AppBar(
        title: Text(group.name,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 20),
            onPressed: _shareGroupCode,
            tooltip: 'Share invite code',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: isDark ? FormaColors.charcoal : Colors.white,
                  borderRadius: BorderRadius.circular(24),
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
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: FormaColors.goldenYellow
                                .withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.groups_rounded,
                              color: FormaColors.goldenYellow, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? FormaColors.darkPrimaryText
                                      : FormaColors.lightPrimaryText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${group.memberIds.length} members • ${group.isPrivate ? "Private Group" : "Public Group"}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? FormaColors.darkSecondaryText
                                      : FormaColors.lightSecondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (group.description.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        group.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? FormaColors.darkSecondaryText
                              : FormaColors.lightSecondaryText,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),

                    // Join Code Banner
                    GestureDetector(
                      onTap: _copyGroupCode,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color:
                              isDark ? Colors.black26 : const Color(0xFFF7F5F0),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: FormaColors.goldenYellow
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.vpn_key_rounded,
                                size: 18, color: FormaColors.goldenYellow),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'GROUP INVITE CODE',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.1,
                                        color: FormaColors.concreteGrey),
                                  ),
                                  Text(
                                    group.joinCode,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? FormaColors.darkPrimaryText
                                          : FormaColors.lightPrimaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.copy_rounded,
                                size: 18, color: FormaColors.goldenYellow),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Members (${group.memberIds.length})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? FormaColors.darkPrimaryText
                      : FormaColors.lightPrimaryText,
                ),
              ),
              const SizedBox(height: 12),

              // Real members list from Firestore subcollection
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('groups')
                    .doc(group.id)
                    .collection('members')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? FormaColors.charcoal : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${group.memberIds.length} athlete(s) in this group.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? FormaColors.darkSecondaryText
                              : FormaColors.lightSecondaryText,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final memberId = docs[index].id;
                      final memberName =
                          data['displayName'] as String? ?? 'Athlete';
                      final memberRole = data['role'] as String? ?? 'member';

                      final memberPhotoUrl = (data['photoUrl'] ??
                          data['photoURL'] ??
                          data['avatarUrl']) as String?;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? FormaColors.charcoal : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white10
                                : FormaColors.divider.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Row(
                          children: [
                            FormaAvatar(
                              photoUrl: memberPhotoUrl,
                              name: memberName,
                              size: 40,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    memberName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: isDark
                                          ? FormaColors.darkPrimaryText
                                          : FormaColors.lightPrimaryText,
                                    ),
                                  ),
                                  if (memberId == currentUserId)
                                    const Text('(You)',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: FormaColors.concreteGrey)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (memberRole == 'owner'
                                        ? FormaColors.goldenYellow
                                        : (memberRole == 'admin'
                                            ? FormaColors.primaryAccent
                                            : FormaColors.concreteGrey))
                                    .withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                memberRole.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: memberRole == 'owner'
                                      ? FormaColors.goldenYellow
                                      : (memberRole == 'admin'
                                          ? FormaColors.primaryAccent
                                          : FormaColors.concreteGrey),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 32),

              // Group Actions
              if (isOwner)
                FormaBounceable(
                  onTap: _isLoading ? null : _handleDeleteGroup,
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: FormaColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        'Delete Group Permanently',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: FormaColors.error,
                        ),
                      ),
                    ),
                  ),
                )
              else
                FormaBounceable(
                  onTap: _isLoading ? null : _handleLeaveGroup,
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: FormaColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        'Leave Group',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
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

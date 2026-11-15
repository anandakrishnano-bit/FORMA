import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forma/core/components/forma_bounceable.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/repositories/friends_social_repository.dart';

class CreateGroupDialog extends ConsumerStatefulWidget {
  const CreateGroupDialog({super.key});

  @override
  ConsumerState<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends ConsumerState<CreateGroupDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isPrivate = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter a group name.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final (success, message) =
        await ref.read(friendsSocialRepositoryProvider).createGroup(
              name: name,
              description: _descController.text.trim(),
              isPrivate: _isPrivate,
            );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: FormaColors.success,
          ),
        );
      } else {
        setState(() => _error = message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark
          ? FormaColors.darkCardBackground
          : FormaColors.lightCardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: FormaColors.goldenYellow.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.group_add_rounded,
                      color: FormaColors.goldenYellow, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  'Create Private Group',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? FormaColors.darkPrimaryText
                        : FormaColors.lightPrimaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Group Name',
                hintText: 'e.g. Iron Legion, Morning Runners',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'What is this group about?',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 18, color: FormaColors.concreteGrey),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Private Membership',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Members can only join via your secret invite code',
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
                Switch(
                  value: _isPrivate,
                  activeTrackColor: FormaColors.goldenYellow,
                  onChanged: (val) => setState(() => _isPrivate = val),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(fontSize: 12, color: FormaColors.error),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FormaBounceable(
                  onTap: _isLoading ? null : _handleCreate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: FormaColors.goldenYellow,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: FormaColors.charcoal),
                          )
                        : Text(
                            'Create Group',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: FormaColors.charcoal,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

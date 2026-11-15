import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:forma/core/components/forma_avatar.dart';
import 'package:forma/core/components/forma_button.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/models/preset_avatar_model.dart';
import 'package:forma/features/authentication/providers/auth_providers.dart';

class AvatarPickerScreen extends ConsumerStatefulWidget {
  const AvatarPickerScreen({super.key});

  @override
  ConsumerState<AvatarPickerScreen> createState() => _AvatarPickerScreenState();
}

class _AvatarPickerScreenState extends ConsumerState<AvatarPickerScreen> {
  String? _selectedAvatarKey;
  File? _localImageFile;
  bool _isSaving = false;
  String? _errorMessage;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _selectedAvatarKey = user?.photoURL;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (picked != null) {
        setState(() {
          _localImageFile = File(picked.path);
          _selectedAvatarKey = 'file:${picked.path}';
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to pick image: $e');
    }
  }

  Future<void> _handleSave() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      String finalPhotoUrl = _selectedAvatarKey ?? '';

      // If user uploaded a new local file, attempt upload to Firebase Storage under users/{uid}/profile/
      if (_localImageFile != null) {
        try {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('users')
              .child(user.uid)
              .child('profile')
              .child('avatar_${DateTime.now().millisecondsSinceEpoch}.jpg');

          final uploadTask = await storageRef
              .putFile(
                _localImageFile!,
                SettableMetadata(contentType: 'image/jpeg'),
              )
              .timeout(const Duration(seconds: 12));
          finalPhotoUrl = await uploadTask.ref.getDownloadURL();
        } catch (storageError) {
          debugPrint(
              'Firebase Storage upload unavailable ($storageError). Storing directly in user profile as Base64 data.');
          final bytes = await _localImageFile!.readAsBytes();
          final base64String = base64Encode(bytes);
          finalPhotoUrl = 'data:image/jpeg;base64,$base64String';
        }
      }

      // Update Firebase Auth user (if finalPhotoUrl is a standard URL; Base64 data URLs exceed Firebase Auth's 2048 character photoURL limit)
      try {
        if (!finalPhotoUrl.startsWith('data:')) {
          await user
              .updatePhotoURL(finalPhotoUrl.isEmpty ? null : finalPhotoUrl);
          await user.reload();
        }
      } catch (_) {}

      // Update Firestore user document with multi-field compatibility
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'photoURL': finalPhotoUrl,
        'photoUrl': finalPhotoUrl,
        'avatarUrl': finalPhotoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ref.invalidate(currentUserProfileStreamProvider);
      ref.invalidate(currentUserProvider);

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile avatar updated successfully!',
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
        setState(() {
          _isSaving = false;
          _errorMessage = 'Failed to update avatar: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentFirebaseUserProvider);
    final userName = user?.displayName ?? 'Athlete';

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
          'Profile Avatar & Photo',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: isDark ? FormaColors.darkPrimaryText : FormaColors.charcoal,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Live Avatar Preview
            Center(
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: FormaColors.goldenYellow, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _localImageFile != null
                    ? ClipOval(
                        child: Image.file(
                          _localImageFile!,
                          fit: BoxFit.cover,
                          width: 130,
                          height: 130,
                        ),
                      )
                    : FormaAvatar(
                        photoUrl: _selectedAvatarKey,
                        name: userName,
                        size: 130,
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              userName,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: isDark ? Colors.white : FormaColors.charcoal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select an original FORMA preset avatar or upload your photo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? FormaColors.darkSecondaryText
                    : FormaColors.lightSecondaryText,
              ),
            ),
            const SizedBox(height: 24),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: FormaColors.coralPink.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: FormaColors.coralPink.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: FormaColors.coralPink),
                ),
              ),
            ],

            // 2. Upload / Camera Actions Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library_rounded, size: 18),
                    label: const Text('Gallery Photo',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          isDark ? Colors.white : FormaColors.charcoal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: isDark
                            ? Colors.white24
                            : FormaColors.concreteGrey.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt_rounded, size: 18),
                    label: const Text('Take Photo',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          isDark ? Colors.white : FormaColors.charcoal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: isDark
                            ? Colors.white24
                            : FormaColors.concreteGrey.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // 3. FORMA Preset Avatars Grid (Part 3.1)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'FORMA Preset Avatars',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: isDark ? Colors.white : FormaColors.charcoal,
                  ),
                ),
                Text(
                  '${FormaPresetAvatar.collection.length} Presets',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: FormaColors.primaryAccent),
                ),
              ],
            ),
            const SizedBox(height: 14),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: FormaPresetAvatar.collection.length,
              itemBuilder: (context, index) {
                final preset = FormaPresetAvatar.collection[index];
                final isSelected = _selectedAvatarKey == preset.storageKey &&
                    _localImageFile == null;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedAvatarKey = preset.storageKey;
                      _localImageFile = null;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? FormaColors.charcoal : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? FormaColors.primaryAccent
                            : (isDark
                                ? Colors.white10
                                : FormaColors.concreteGrey
                                    .withValues(alpha: 0.2)),
                        width: isSelected ? 2.2 : 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: preset.backgroundColor,
                            border: Border.all(
                                color:
                                    preset.primaryColor.withValues(alpha: 0.5),
                                width: 1.5),
                          ),
                          child: Icon(preset.icon,
                              size: 24, color: preset.primaryColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          preset.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight:
                                isSelected ? FontWeight.w900 : FontWeight.w700,
                            fontSize: 11,
                            color: isDark ? Colors.white : FormaColors.charcoal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          preset.badgeText,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: preset.primaryColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Save Button
            FormaButton(
              label: 'Save Profile Avatar',
              onPressed: _isSaving ? null : _handleSave,
              isLoading: _isSaving,
              icon: Icons.check_circle_rounded,
            ),
            const SizedBox(height: 12),

            // Reset action
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedAvatarKey = '';
                  _localImageFile = null;
                });
              },
              child: const Text('Reset to Initial',
                  style:
                      TextStyle(color: FormaColors.concreteGrey, fontSize: 13)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

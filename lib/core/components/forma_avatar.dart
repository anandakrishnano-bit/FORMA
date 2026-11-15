import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/models/preset_avatar_model.dart';

/// Unified Brand Avatar Widget for FORMA
/// Handles:
/// 1. FORMA-themed preset vector avatars (`preset:<id>`)
/// 2. User uploaded photographic URLs
/// 3. Initial letter fallback with brand styling
class FormaAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double size;
  final double borderWidth;
  final Color? borderColor;

  const FormaAvatar({
    super.key,
    required this.photoUrl,
    required this.name,
    this.size = 44.0,
    this.borderWidth = 0.0,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final cleanName = name.trim();
    final initial = cleanName.isNotEmpty ? cleanName[0].toUpperCase() : 'A';

    // 1. Check for FORMA Preset Avatar
    if (photoUrl != null && photoUrl!.startsWith('preset:')) {
      final preset = FormaPresetAvatar.fromKey(photoUrl) ??
          FormaPresetAvatar.collection.first;
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: preset.backgroundColor,
          border: borderWidth > 0
              ? Border.all(
                  color: borderColor ?? preset.primaryColor, width: borderWidth)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            preset.icon,
            size: size * 0.52,
            color: preset.primaryColor,
          ),
        ),
      );
    }

    // 2. Check for Uploaded Photo URL
    if (photoUrl != null && photoUrl!.startsWith('http')) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: borderWidth > 0
              ? Border.all(
                  color: borderColor ?? FormaColors.goldenYellow,
                  width: borderWidth)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.network(
            photoUrl!,
            fit: BoxFit.cover,
            width: size,
            height: size,
            errorBuilder: (_, __, ___) => _buildInitialAvatar(initial),
          ),
        ),
      );
    }

    // 3. Fallback Initial Avatar
    return _buildInitialAvatar(initial);
  }

  Widget _buildInitialAvatar(String initial) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: FormaColors.warmCream,
        border: borderWidth > 0
            ? Border.all(
                color: borderColor ?? FormaColors.goldenYellow,
                width: borderWidth)
            : Border.all(
                color: FormaColors.goldenYellow.withValues(alpha: 0.5),
                width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.plusJakartaSans(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w900,
            color: FormaColors.charcoal,
          ),
        ),
      ),
    );
  }
}

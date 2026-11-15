import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/core/components/forma_button.dart';
import 'package:forma/core/components/forma_text_field.dart';
import 'package:forma/core/services/forma_haptics.dart';

/// Screen handling Firebase Auth email action links:
/// - verifyEmail
/// - resetPassword
/// - recoverEmail
///
/// Route: /auth/action
class EmailActionHandlerScreen extends StatefulWidget {
  final String? mode;
  final String? oobCode;
  final String? continueUrl;

  const EmailActionHandlerScreen({
    super.key,
    this.mode,
    this.oobCode,
    this.continueUrl,
  });

  @override
  State<EmailActionHandlerScreen> createState() =>
      _EmailActionHandlerScreenState();
}

class _EmailActionHandlerScreenState extends State<EmailActionHandlerScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSuccess = false;
  String _successTitle = '';
  String _successMessage = '';

  // Password reset state
  String? _verifiedEmail;
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmittingPassword = false;

  @override
  void initState() {
    super.initState();
    _processActionCode();
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _processActionCode() async {
    final mode = widget.mode;
    final oobCode = widget.oobCode;

    if (oobCode == null || oobCode.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Invalid or missing action code. Please check your verification link.';
      });
      return;
    }

    try {
      switch (mode) {
        case 'verifyEmail':
          await _auth.applyActionCode(oobCode);
          await _auth.currentUser?.reload();
          FormaHaptics.success();
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isSuccess = true;
              _successTitle = 'Email Verified!';
              _successMessage =
                  'Your email address has been successfully verified. Your FORMA account is fully active and secure.';
            });
          }
          break;

        case 'resetPassword':
          // Verify code and retrieve the target email
          final email = await _auth.verifyPasswordResetCode(oobCode);
          if (mounted) {
            setState(() {
              _isLoading = false;
              _verifiedEmail = email;
            });
          }
          break;

        case 'recoverEmail':
          await _auth.applyActionCode(oobCode);
          FormaHaptics.success();
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isSuccess = true;
              _successTitle = 'Email Restored';
              _successMessage =
                  'Your primary account email address has been restored. If you did not authorize this change, please update your password immediately.';
            });
          }
          break;

        default:
          setState(() {
            _isLoading = false;
            _errorMessage =
                'Unsupported auth action ($mode). Please open the link again.';
          });
      }
    } on FirebaseAuthException catch (e) {
      FormaHaptics.error();
      String message;
      switch (e.code) {
        case 'expired-action-code':
          message =
              'This link has expired. For your security, please request a new verification or reset link.';
          break;
        case 'invalid-action-code':
          message =
              'This link is invalid or has already been used. Please request a new link.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled. Please contact support.';
          break;
        case 'user-not-found':
          message = 'No FORMA account was found matching this request.';
          break;
        default:
          message = e.message ??
              'Failed to process security action. Please try again.';
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = message;
        });
      }
    } catch (e) {
      FormaHaptics.error();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An unexpected error occurred: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _submitNewPassword() async {
    final password = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.length < 6) {
      setState(
          () => _errorMessage = 'Password must be at least 6 characters long.');
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isSubmittingPassword = true;
      _errorMessage = null;
    });

    try {
      await _auth.confirmPasswordReset(
        code: widget.oobCode!,
        newPassword: password,
      );
      FormaHaptics.success();

      if (mounted) {
        setState(() {
          _isSubmittingPassword = false;
          _isSuccess = true;
          _successTitle = 'Password Reset!';
          _successMessage =
              'Your password has been securely updated. You can now sign in with your new credentials.';
        });
      }
    } on FirebaseAuthException catch (e) {
      FormaHaptics.error();
      if (mounted) {
        setState(() {
          _isSubmittingPassword = false;
          _errorMessage = e.code == 'weak-password'
              ? 'Password is too weak. Please use numbers and letters.'
              : (e.message ?? 'Failed to reset password.');
        });
      }
    } catch (e) {
      FormaHaptics.error();
      if (mounted) {
        setState(() {
          _isSubmittingPassword = false;
          _errorMessage = 'An error occurred: ${e.toString()}';
        });
      }
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
        centerTitle: true,
        title: Text(
          'ACCOUNT SECURITY',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: isDark
                ? FormaColors.darkSecondaryText
                : FormaColors.lightSecondaryText,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _buildBody(isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: FormaColors.primaryAccent),
          const SizedBox(height: 24),
          Text(
            'Verifying security credentials...',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? FormaColors.darkPrimaryText
                  : FormaColors.lightPrimaryText,
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null && !_isSuccess && _verifiedEmail == null) {
      return _buildErrorState(isDark);
    }

    if (_isSuccess) {
      return _buildSuccessState(isDark);
    }

    if (widget.mode == 'resetPassword' && _verifiedEmail != null) {
      return _buildResetPasswordForm(isDark);
    }

    return _buildErrorState(isDark);
  }

  Widget _buildSuccessState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark
            ? FormaColors.darkCardBackground
            : FormaColors.lightCardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: FormaColors.success.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FormaColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: FormaColors.success,
              size: 54,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _successTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? FormaColors.darkPrimaryText
                  : FormaColors.lightPrimaryText,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _successMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark
                  ? FormaColors.darkSecondaryText
                  : FormaColors.lightSecondaryText,
            ),
          ),
          const SizedBox(height: 28),
          FormaButton(
            label: _auth.currentUser != null ? 'Continue to FORMA' : 'Sign In',
            onPressed: () {
              if (_auth.currentUser != null) {
                context.go('/home');
              } else {
                context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark
            ? FormaColors.darkCardBackground
            : FormaColors.lightCardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: FormaColors.coralPink.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FormaColors.coralPink.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: FormaColors.coralPink,
              size: 54,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Verification Failed',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? FormaColors.darkPrimaryText
                  : FormaColors.lightPrimaryText,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'The action code is invalid or has expired.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark
                  ? FormaColors.darkSecondaryText
                  : FormaColors.lightSecondaryText,
            ),
          ),
          const SizedBox(height: 28),
          FormaButton(
            label: 'Return to Login',
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
    );
  }

  Widget _buildResetPasswordForm(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark
            ? FormaColors.darkCardBackground
            : FormaColors.lightCardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: FormaColors.primaryAccent.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: FormaColors.primaryAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                color: FormaColors.primaryAccent,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Reset Password',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? FormaColors.darkPrimaryText
                    : FormaColors.lightPrimaryText,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Account: $_verifiedEmail',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? FormaColors.darkSecondaryText
                    : FormaColors.lightSecondaryText,
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FormaColors.coralPink.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: FormaColors.coralPink.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: FormaColors.coralPink, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                          color: FormaColors.coralPink, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'New Password',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? FormaColors.darkPrimaryText
                  : FormaColors.lightPrimaryText,
            ),
          ),
          const SizedBox(height: 8),
          FormaTextField(
            hint: 'At least 6 characters',
            controller: _newPasswordController,
            obscureText: _obscurePassword,
            prefixIcon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Confirm New Password',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? FormaColors.darkPrimaryText
                  : FormaColors.lightPrimaryText,
            ),
          ),
          const SizedBox(height: 8),
          FormaTextField(
            hint: 'Re-enter your password',
            controller: _confirmPasswordController,
            obscureText: _obscurePassword,
            prefixIcon: Icons.lock_outline_rounded,
          ),
          const SizedBox(height: 28),
          FormaButton(
            label: 'Save New Password',
            isLoading: _isSubmittingPassword,
            onPressed: _submitNewPassword,
          ),
        ],
      ),
    );
  }
}

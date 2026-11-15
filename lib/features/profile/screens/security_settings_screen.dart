import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';

import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/core/components/forma_text_field.dart';
import 'package:forma/core/components/forma_button.dart';
import 'package:forma/core/components/section_header.dart';
import 'package:forma/core/services/biometric_auth_service.dart';
import 'package:forma/core/services/forma_haptics.dart';
import 'package:forma/features/authentication/widgets/country_code_picker.dart';

/// Comprehensive Account Security, Biometrics, and Authentication Settings.
///
/// Route: /profile/security-settings
class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final BiometricAuthService _biometrics = BiometricAuthService();

  bool _isLoading = false;
  bool _isSendingVerification = false;
  bool _biometricsAvailable = false;
  bool _appLockEnabled = false;
  bool _expensesLockEnabled = false;
  bool _hapticsEnabled = true;

  User? get _currentUser => _auth.currentUser;
  List<String> get _providerIds =>
      _currentUser?.providerData.map((p) => p.providerId).toList() ?? [];

  bool get _hasGoogle => _providerIds.contains('google.com');
  bool get _hasPassword => _providerIds.contains('password');
  bool get _hasPhone => _providerIds.contains('phone');

  String? get _googleEmail => _currentUser?.providerData
      .firstWhere((p) => p.providerId == 'google.com',
          orElse: () => _currentUser!.providerData.first)
      .email;

  String? get _passwordEmail => _currentUser?.providerData
      .firstWhere((p) => p.providerId == 'password',
          orElse: () => _currentUser!.providerData.first)
      .email;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final available = await _biometrics.isBiometricsAvailable();
    final appLock = await _biometrics.isAppLockEnabled();
    final expensesLock = await _biometrics.isExpensesLockEnabled();
    await FormaHaptics.init();

    if (mounted) {
      setState(() {
        _biometricsAvailable = available;
        _appLockEnabled = appLock;
        _expensesLockEnabled = expensesLock;
        _hapticsEnabled = FormaHaptics.isEnabled;
      });
    }
  }

  // ──────────────────────── Email Verification ────────────────────────
  Future<void> _sendVerificationEmail() async {
    final user = _currentUser;
    if (user == null || user.email == null) return;

    setState(() => _isSendingVerification = true);
    FormaHaptics.lightImpact();

    try {
      await user.sendEmailVerification();
      FormaHaptics.success();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Verification email sent! Check your inbox.'),
            backgroundColor: FormaColors.success,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      FormaHaptics.error();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.code == 'too-many-requests'
                ? 'Too many attempts. Please wait 60 seconds.'
                : (e.message ?? 'Failed to send verification email.')),
            backgroundColor: FormaColors.coralPink,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingVerification = false);
    }
  }

  Future<void> _refreshVerificationStatus() async {
    setState(() => _isLoading = true);
    await _currentUser?.reload();
    FormaHaptics.selection();
    if (mounted) {
      setState(() => _isLoading = false);
      final isVerified = _currentUser?.emailVerified ?? false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isVerified
              ? '✓ Email address verified!'
              : 'Status refreshed: Email still unverified.'),
          backgroundColor:
              isVerified ? FormaColors.success : FormaColors.charcoal,
        ),
      );
    }
  }

  // ──────────────────────── Provider Linking & Unlinking ────────────────────────
  Future<void> _linkGoogle() async {
    setState(() => _isLoading = true);
    FormaHaptics.lightImpact();

    try {
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _currentUser?.linkWithCredential(credential);
      await _currentUser?.reload();
      FormaHaptics.success();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Google account connected successfully!'),
            backgroundColor: FormaColors.success,
          ),
        );
        setState(() {});
      }
    } on FirebaseAuthException catch (e) {
      FormaHaptics.error();
      String message = 'Failed to link Google account.';
      if (e.code == 'credential-already-in-use') {
        message =
            'This Google account is already linked to another FORMA profile.';
      } else if (e.code == 'provider-already-linked') {
        message = 'A Google account is already connected.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(message), backgroundColor: FormaColors.coralPink),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unlinkProvider(String providerId, String providerName) async {
    if (_providerIds.length <= 1) {
      FormaHaptics.error();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Cannot unlink $providerName. You must have at least one sign-in method active.'),
            backgroundColor: FormaColors.coralPink,
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Unlink $providerName?'),
        content: Text(
            'You will no longer be able to use $providerName to sign into FORMA.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: FormaColors.coralPink),
            child: const Text('Unlink',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    FormaHaptics.lightImpact();

    try {
      await _currentUser?.unlink(providerId);
      await _currentUser?.reload();
      FormaHaptics.success();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('✓ $providerName unlinked.'),
              backgroundColor: FormaColors.success),
        );
      }
    } catch (e) {
      FormaHaptics.error();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to unlink: $e'),
              backgroundColor: FormaColors.coralPink),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ──────────────────────── Reauthentication & Sensitive Actions ────────────────────────
  Future<bool> _promptReauthenticate(String reason) async {
    final passwordController = TextEditingController();
    bool isAuthenticating = false;
    String? error;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor:
                  isDark ? FormaColors.charcoal : FormaColors.warmCream,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22)),
              title: Row(
                children: [
                  const Icon(Icons.shield_rounded,
                      color: FormaColors.primaryAccent),
                  const SizedBox(width: 10),
                  const Text('Confirm Identity',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reason,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? FormaColors.darkSecondaryText
                          : FormaColors.lightSecondaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_hasPassword) ...[
                    FormaTextField(
                      hint: 'Current account password',
                      controller: passwordController,
                      obscureText: true,
                      prefixIcon: Icons.lock_outline_rounded,
                    ),
                  ] else ...[
                    const Text(
                        'Sign in again to confirm this sensitive change.',
                        style: TextStyle(fontSize: 13)),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(error!,
                        style: const TextStyle(
                            color: FormaColors.coralPink, fontSize: 12)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isAuthenticating
                      ? null
                      : () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isAuthenticating
                      ? null
                      : () async {
                          setDialogState(() {
                            isAuthenticating = true;
                            error = null;
                          });

                          try {
                            if (_hasPassword && _currentUser?.email != null) {
                              final cred = EmailAuthProvider.credential(
                                email: _currentUser!.email!,
                                password: passwordController.text,
                              );
                              await _currentUser
                                  ?.reauthenticateWithCredential(cred);
                              if (ctx.mounted) Navigator.of(ctx).pop(true);
                            } else if (_hasGoogle) {
                              final googleSignIn =
                                  GoogleSignIn(scopes: ['email', 'profile']);
                              final googleUser = await googleSignIn.signIn();
                              if (googleUser != null) {
                                final googleAuth =
                                    await googleUser.authentication;
                                final cred = GoogleAuthProvider.credential(
                                  accessToken: googleAuth.accessToken,
                                  idToken: googleAuth.idToken,
                                );
                                await _currentUser
                                    ?.reauthenticateWithCredential(cred);
                                if (ctx.mounted) Navigator.of(ctx).pop(true);
                              } else {
                                setDialogState(() => isAuthenticating = false);
                              }
                            } else {
                              if (ctx.mounted) Navigator.of(ctx).pop(true);
                            }
                          } on FirebaseAuthException catch (e) {
                            setDialogState(() {
                              isAuthenticating = false;
                              error = e.code == 'wrong-password' ||
                                      e.code == 'invalid-credential'
                                  ? 'Incorrect current password.'
                                  : (e.message ?? 'Authentication failed.');
                            });
                          } catch (e) {
                            setDialogState(() {
                              isAuthenticating = false;
                              error = 'Authentication failed: $e';
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FormaColors.primaryAccent,
                    foregroundColor: FormaColors.charcoal,
                  ),
                  child: const Text('Confirm',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            );
          },
        );
      },
    );

    return result ?? false;
  }

  void _showChangePasswordDialog() async {
    final authenticated = await _promptReauthenticate(
        'Please enter your current password before choosing a new one.');
    if (!authenticated || !mounted) return;

    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    bool isSaving = false;
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor:
                  isDark ? FormaColors.charcoal : FormaColors.warmCream,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22)),
              title: const Text('Change Password',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FormaTextField(
                    hint: 'New password (min 6 chars)',
                    controller: newPassController,
                    obscureText: true,
                    prefixIcon: Icons.lock_reset_rounded,
                  ),
                  const SizedBox(height: 12),
                  FormaTextField(
                    hint: 'Confirm new password',
                    controller: confirmPassController,
                    obscureText: true,
                    prefixIcon: Icons.lock_outline_rounded,
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 10),
                    Text(dialogError!,
                        style: const TextStyle(
                            color: FormaColors.coralPink, fontSize: 12)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newPass = newPassController.text;
                          final confirm = confirmPassController.text;
                          if (newPass.length < 6) {
                            setDialogState(() => dialogError =
                                'Password must be at least 6 characters.');
                            return;
                          }
                          if (newPass != confirm) {
                            setDialogState(
                                () => dialogError = 'Passwords do not match.');
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                            dialogError = null;
                          });

                          try {
                            await _currentUser?.updatePassword(newPass);
                            FormaHaptics.success();
                            if (mounted) {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('✓ Password updated successfully!'),
                                  backgroundColor: FormaColors.success,
                                ),
                              );
                            }
                          } on FirebaseAuthException catch (e) {
                            FormaHaptics.error();
                            setDialogState(() {
                              isSaving = false;
                              dialogError =
                                  e.message ?? 'Failed to update password.';
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FormaColors.primaryAccent,
                    foregroundColor: FormaColors.charcoal,
                  ),
                  child: const Text('Update Password',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteAccountDialog() async {
    final reauthed = await _promptReauthenticate(
      'Account deletion is irreversible. Your workouts, nutrition records, and private data will be permanently wiped.',
    );
    if (!reauthed || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permanently Delete Account?'),
        content: const Text(
          'This action cannot be undone. Are you completely sure you want to permanently delete your FORMA account?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: FormaColors.coralPink,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Delete My Account',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await _currentUser?.delete();
      FormaHaptics.heavyImpact();
      if (mounted) {
        context.go('/welcome');
      }
    } catch (e) {
      FormaHaptics.error();
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to delete account: $e'),
              backgroundColor: FormaColors.coralPink),
        );
      }
    }
  }

  void _showLinkPhoneDialog() {
    final phoneController = TextEditingController();
    final otpController = TextEditingController();
    CountryInfo selectedCountry = CountryInfo.defaultCountry;
    String? verificationId;
    bool codeSent = false;
    bool dialogLoading = false;
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return AlertDialog(
              backgroundColor:
                  isDark ? FormaColors.charcoal : FormaColors.warmCream,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22)),
              title: Text(
                codeSent ? 'Enter SMS Code' : 'Connect Phone Number',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!codeSent) ...[
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final chosen = await showCountryCodePicker(
                              context,
                              selectedCountry: selectedCountry,
                            );
                            if (chosen != null) {
                              setDialogState(() => selectedCountry = chosen);
                            }
                          },
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? FormaColors.darkCardBackground
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: FormaColors.concreteGrey
                                    .withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(selectedCountry.flag,
                                    style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 4),
                                Text(
                                  selectedCountry.dialCode,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FormaTextField(
                            hint: 'Phone number',
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      'Enter the 6-digit verification code sent to ${selectedCountry.dialCode} ${phoneController.text.trim()}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    FormaTextField(
                      hint: '6-digit OTP',
                      controller: otpController,
                      prefixIcon: Icons.pin_rounded,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                  if (dialogError != null) ...[
                    const SizedBox(height: 10),
                    Text(dialogError!,
                        style: const TextStyle(
                            color: FormaColors.coralPink, fontSize: 12)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: dialogLoading
                      ? null
                      : () async {
                          if (!codeSent) {
                            final raw = phoneController.text
                                .replaceAll(RegExp(r'\D'), '');
                            if (raw.length < selectedCountry.minDigits) {
                              setDialogState(() => dialogError =
                                  'Enter a valid ${selectedCountry.minDigits}-digit number.');
                              return;
                            }
                            setDialogState(() {
                              dialogLoading = true;
                              dialogError = null;
                            });

                            final fullNumber =
                                '${selectedCountry.dialCode}$raw';
                            await _auth.verifyPhoneNumber(
                              phoneNumber: fullNumber,
                              verificationCompleted:
                                  (PhoneAuthCredential credential) async {
                                await _currentUser
                                    ?.linkWithCredential(credential);
                                if (mounted) {
                                  Navigator.of(ctx).pop();
                                  setState(() {});
                                }
                              },
                              verificationFailed: (FirebaseAuthException e) {
                                setDialogState(() {
                                  dialogLoading = false;
                                  dialogError =
                                      e.message ?? 'Verification failed.';
                                });
                              },
                              codeSent: (String vId, int? resendToken) {
                                setDialogState(() {
                                  verificationId = vId;
                                  codeSent = true;
                                  dialogLoading = false;
                                });
                              },
                              codeAutoRetrievalTimeout: (String vId) {
                                verificationId = vId;
                              },
                            );
                          } else {
                            final smsCode = otpController.text.trim();
                            if (smsCode.length < 6 || verificationId == null) {
                              setDialogState(() => dialogError =
                                  'Enter the complete 6-digit code.');
                              return;
                            }
                            setDialogState(() {
                              dialogLoading = true;
                              dialogError = null;
                            });

                            try {
                              final cred = PhoneAuthProvider.credential(
                                verificationId: verificationId!,
                                smsCode: smsCode,
                              );
                              await _currentUser?.linkWithCredential(cred);
                              await _currentUser?.reload();
                              FormaHaptics.success();
                              if (mounted) {
                                Navigator.of(ctx).pop();
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        '✓ Phone number linked successfully!'),
                                    backgroundColor: FormaColors.success,
                                  ),
                                );
                              }
                            } catch (e) {
                              FormaHaptics.error();
                              setDialogState(() {
                                dialogLoading = false;
                                dialogError =
                                    'Incorrect or expired code. Try again.';
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FormaColors.primaryAccent,
                    foregroundColor: FormaColors.charcoal,
                  ),
                  child: Text(
                    codeSent ? 'Verify & Link' : 'Send OTP',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEmailVerified = _currentUser?.emailVerified ?? false;

    return Scaffold(
      backgroundColor:
          isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
      appBar: AppBar(
        title: const Text('Account Security',
            style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: isDark ? Colors.white : FormaColors.charcoal),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoading) ...[
                const LinearProgressIndicator(color: FormaColors.primaryAccent),
                const SizedBox(height: 16),
              ],

              // ── 1. Email Verification Status Card ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? FormaColors.darkCardBackground
                      : FormaColors.lightCardBackground,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: (isEmailVerified
                            ? FormaColors.success
                            : FormaColors.coralPink)
                        .withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isEmailVerified
                              ? Icons.verified_rounded
                              : Icons.mark_email_unread_rounded,
                          color: isEmailVerified
                              ? FormaColors.success
                              : FormaColors.coralPink,
                          size: 26,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEmailVerified
                                    ? 'Email Verified'
                                    : 'Email Unverified',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                _currentUser?.email ?? 'No email associated',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? FormaColors.darkSecondaryText
                                      : FormaColors.lightSecondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isEmailVerified
                                    ? FormaColors.success
                                    : FormaColors.coralPink)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isEmailVerified ? 'VERIFIED' : 'ACTION NEEDED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: isEmailVerified
                                  ? FormaColors.success
                                  : FormaColors.coralPink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!isEmailVerified) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Verifying your email ensures your training history, expenses and friends network can be safely recovered if you switch devices.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: isDark
                              ? FormaColors.darkSecondaryText
                              : FormaColors.lightSecondaryText,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: FormaButton(
                              label: 'Send Verification Email',
                              isLoading: _isSendingVerification,
                              onPressed: _sendVerificationEmail,
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded),
                            tooltip: 'Refresh Status',
                            onPressed: _refreshVerificationStatus,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── 2. Linked Sign-In Providers ──
              const FormaSectionHeader(title: 'Connected Sign-In Methods'),
              const SizedBox(height: 12),

              _buildProviderTile(
                icon: Icons.g_mobiledata_rounded,
                iconColor: const Color(0xFF4285F4),
                title: 'Google Account',
                detail: _hasGoogle
                    ? (_googleEmail ?? 'Connected')
                    : 'Not connected',
                isConnected: _hasGoogle,
                onConnect: _linkGoogle,
                onUnlink: () => _unlinkProvider('google.com', 'Google'),
              ),
              const SizedBox(height: 12),

              _buildProviderTile(
                icon: Icons.email_outlined,
                iconColor: FormaColors.goldenYellow,
                title: 'Email & Password',
                detail: _hasPassword
                    ? (_passwordEmail ?? _currentUser?.email ?? 'Connected')
                    : 'Not connected',
                isConnected: _hasPassword,
                actionLabel: _hasPassword ? 'Change' : 'Connect',
                onConnect: _hasPassword ? _showChangePasswordDialog : null,
                onUnlink: _hasPassword
                    ? () => _unlinkProvider('password', 'Email & Password')
                    : null,
              ),
              const SizedBox(height: 12),

              _buildProviderTile(
                icon: Icons.phone_android_rounded,
                iconColor: FormaColors.sage,
                title: 'Phone Number (OTP)',
                detail: _hasPhone || _currentUser?.phoneNumber != null
                    ? (_currentUser?.phoneNumber ?? 'Connected')
                    : 'Not connected',
                isConnected: _hasPhone || _currentUser?.phoneNumber != null,
                onConnect: (_hasPhone || _currentUser?.phoneNumber != null)
                    ? null
                    : _showLinkPhoneDialog,
                onUnlink: (_hasPhone || _currentUser?.phoneNumber != null)
                    ? () => _unlinkProvider('phone', 'Phone Number')
                    : null,
              ),

              const SizedBox(height: 28),

              // ── 3. Device Biometrics & Privacy ──
              const FormaSectionHeader(title: 'Biometrics & App Lock'),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? FormaColors.darkCardBackground
                      : FormaColors.lightCardBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('App Lock',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text(
                        'Require fingerprint or face authentication on resume',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _appLockEnabled,
                      activeThumbColor: FormaColors.primaryAccent,
                      onChanged: _biometricsAvailable
                          ? (value) async {
                              final success = await _biometrics.authenticate(
                                reason:
                                    'Confirm biometric identity to update App Lock setting',
                              );
                              if (success) {
                                await _biometrics.setAppLockEnabled(value);
                                setState(() => _appLockEnabled = value);
                                FormaHaptics.selection();
                              }
                            }
                          : null,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Lock Personal Expenses',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text(
                        'Require biometric authentication to view private spending ledgers',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _expensesLockEnabled,
                      activeThumbColor: FormaColors.primaryAccent,
                      onChanged: _biometricsAvailable
                          ? (value) async {
                              final success = await _biometrics.authenticate(
                                reason:
                                    'Confirm biometric identity to update Personal Expenses Lock',
                              );
                              if (success) {
                                await _biometrics.setExpensesLockEnabled(value);
                                setState(() => _expensesLockEnabled = value);
                                FormaHaptics.selection();
                              }
                            }
                          : null,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Tactile Haptic Feedback',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text(
                        'Subtle vibrations for set completion, timers and navigation',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _hapticsEnabled,
                      activeThumbColor: FormaColors.primaryAccent,
                      onChanged: (value) async {
                        await FormaHaptics.setEnabled(value);
                        setState(() => _hapticsEnabled = value);
                        if (value) FormaHaptics.mediumImpact();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── 4. Danger Zone ──
              const FormaSectionHeader(title: 'Account Actions'),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? FormaColors.darkCardBackground
                      : FormaColors.lightCardBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.logout_rounded,
                          color: FormaColors.concreteGrey),
                      title: const Text('Sign Out',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text(
                          'Sign out of your FORMA session on this device',
                          style: TextStyle(fontSize: 12)),
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Sign Out?'),
                            content: const Text(
                                'Are you sure you want to sign out of FORMA?'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel')),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Sign Out',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && mounted) {
                          await _auth.signOut();
                          await GoogleSignIn().signOut();
                          if (mounted) context.go('/welcome');
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_forever_rounded,
                          color: FormaColors.coralPink),
                      title: const Text('Delete Account',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: FormaColors.coralPink)),
                      subtitle: const Text(
                          'Permanently delete your profile and all private records',
                          style: TextStyle(fontSize: 12)),
                      onTap: _showDeleteAccountDialog,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String detail,
    required bool isConnected,
    String? actionLabel,
    VoidCallback? onConnect,
    VoidCallback? onUnlink,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? FormaColors.darkCardBackground
            : FormaColors.lightCardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 12,
                    color: isConnected
                        ? FormaColors.success
                        : (isDark
                            ? FormaColors.darkSecondaryText
                            : FormaColors.lightSecondaryText),
                    fontWeight:
                        isConnected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (isConnected) ...[
            if (actionLabel != null && onConnect != null)
              TextButton(
                onPressed: onConnect,
                child: Text(actionLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              )
            else
              const Icon(Icons.check_circle_rounded,
                  color: FormaColors.success, size: 20),
            if (onUnlink != null)
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    size: 18, color: FormaColors.concreteGrey),
                tooltip: 'Unlink',
                onPressed: onUnlink,
              ),
          ] else
            TextButton(
              onPressed: onConnect,
              child: const Text('Connect',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

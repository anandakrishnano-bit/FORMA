import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/core/theme/app_spacing.dart';
import 'package:forma/core/components/forma_logo.dart';
import 'package:forma/core/components/forma_button.dart';
import 'package:forma/core/components/forma_text_field.dart';
import 'package:forma/core/components/forma_loading_overlay.dart';
import 'package:forma/features/authentication/widgets/country_code_picker.dart';

/// Complete, production-ready Firebase Authentication screen.
/// Supports Google Sign-In, Email/Password (Login & Register), and Phone Number (OTP).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _resetEmailController = TextEditingController();

  // State
  bool _isRegisterMode = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  // Phone OTP State
  bool _isPhoneMode = false;
  bool _otpSent = false;
  String? _verificationId;
  int _resendCooldown = 60;
  Timer? _cooldownTimer;
  CountryInfo _selectedCountry = CountryInfo.defaultCountry;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _resetEmailController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown > 1) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      }
    });
  }

  /// Consolidated post-authentication user profile check & routing.
  Future<void> _routeAfterAuth(User user, {String? displayNameFallback}) async {
    try {
      final userDocRef = _firestore.collection('users').doc(user.uid);
      final doc = await userDocRef.get();
      final isExistingUser = !_isRegisterMode;

      if (!doc.exists) {
        final displayName =
            (user.displayName != null && user.displayName!.isNotEmpty)
                ? user.displayName!
                : (displayNameFallback ?? 'Athlete');

        await userDocRef.set({
          'uid': user.uid,
          'displayName': displayName,
          'email': user.email ?? '',
          'phoneNumber': user.phoneNumber ?? '',
          'photoURL': user.photoURL ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'onboardingComplete': isExistingUser,
          'onboardingCompleted': isExistingUser,
          'preferredAuthProviders':
              user.providerData.map((p) => p.providerId).toList(),
          'accountStatus': 'active',
        });

        if (mounted) {
          if (isExistingUser) {
            context.go('/home');
          } else {
            context.go('/onboarding-flow');
          }
        }
      } else {
        // Preserve existing profile; merge only timestamp and provider metadata
        await userDocRef.set({
          'updatedAt': FieldValue.serverTimestamp(),
          'preferredAuthProviders':
              user.providerData.map((p) => p.providerId).toList(),
        }, SetOptions(merge: true));

        final data = doc.data() ?? {};
        // Check both onboardingComplete and onboardingCompleted flags.
        // Existing registered users who sign in must always enter directly to Home.
        final isComplete = (data['onboardingComplete'] as bool?) ??
            (data['onboardingCompleted'] as bool?) ??
            isExistingUser;

        if (mounted) {
          if (isComplete) {
            context.go('/home');
          } else {
            context.go('/onboarding-flow');
          }
        }
      }
    } catch (e) {
      // In case of offline or Firestore rule latency, route directly
      if (mounted) {
        if (!_isRegisterMode) {
          context.go('/home');
        } else {
          context.go('/onboarding-flow');
        }
      }
    }
  }

  // ──────────────────────── Google Sign-In ────────────────────────
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        await _routeAfterAuth(userCredential.user!);
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Google sign-in could not be completed.';
      if (e.code == 'account-exists-with-different-credential') {
        message =
            'An account already exists with this email using another method. Please sign in with that method and link Google in Settings.';
      } else if (e.code == 'network-request-failed') {
        message = 'Network error. Please check your internet connection.';
      } else {
        message = e.message ?? message;
      }
      if (mounted) {
        setState(() {
          _errorMessage = message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred during Google sign-in: $e';
          _isLoading = false;
        });
      }
    }
  }

  // ──────────────────────── Email & Password ────────────────────────
  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both email and password.');
      return;
    }

    if (_isRegisterMode) {
      final name = _nameController.text.trim();
      final confirm = _confirmPasswordController.text;

      if (name.isEmpty) {
        setState(() => _errorMessage = 'Please enter your full name.');
        return;
      }
      if (password.length < 6) {
        setState(
            () => _errorMessage = 'Password must be at least 6 characters.');
        return;
      }
      if (password != confirm) {
        setState(() => _errorMessage = 'Passwords do not match.');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isRegisterMode) {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        final user = credential.user;
        if (user != null) {
          final name = _nameController.text.trim();
          await user.updateDisplayName(name);
          await user.sendEmailVerification();
          await _routeAfterAuth(user, displayNameFallback: name);
        }
      } else {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (credential.user != null) {
          await _routeAfterAuth(credential.user!);
        }
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email. Please register.';
          break;
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Incorrect email or password. Please try again.';
          break;
        case 'email-already-in-use':
          message = 'This email is already registered. Please sign in instead.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'weak-password':
          message = 'Password is too weak. Please use at least 6 characters.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          message = 'Too many failed attempts. Please try again later.';
          break;
        case 'network-request-failed':
          message = 'Network error. Please check your internet connection.';
          break;
        default:
          message = e.message ?? 'Authentication failed. Please try again.';
      }
      if (mounted) {
        setState(() {
          _errorMessage = message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  // ──────────────────────── Phone Number & OTP ────────────────────────
  Future<void> _sendPhoneOtp() async {
    final rawDigits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (rawDigits.length < _selectedCountry.minDigits ||
        rawDigits.length > _selectedCountry.maxDigits) {
      setState(() => _errorMessage =
          'Please enter a valid ${_selectedCountry.minDigits}-digit phone number for ${_selectedCountry.name}.');
      return;
    }

    final fullPhoneNumber = '${_selectedCountry.dialCode}$rawDigits';

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await _auth.verifyPhoneNumber(
      phoneNumber: fullPhoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        final userCredential = await _auth.signInWithCredential(credential);
        if (userCredential.user != null) {
          await _routeAfterAuth(userCredential.user!);
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                e.message ?? 'Phone verification failed. Verify phone format.';
          });
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (mounted) {
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
            _isLoading = false;
          });
          _startCooldown();
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _verifyPhoneOtp() async {
    final smsCode = _otpController.text.trim();
    if (smsCode.length < 6 || _verificationId == null) {
      setState(
          () => _errorMessage = 'Please enter the complete 6-digit OTP code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        await _routeAfterAuth(userCredential.user!);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.code == 'invalid-verification-code'
              ? 'Incorrect verification code. Please check SMS.'
              : (e.message ?? 'Verification failed.');
        });
      }
    }
  }

  void _showForgotPasswordDialog() {
    _resetEmailController.text = _emailController.text.trim();
    showDialog(
      context: context,
      builder: (ctx) {
        bool isSending = false;
        String? dialogStatus;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return AlertDialog(
              backgroundColor:
                  isDark ? FormaColors.charcoal : FormaColors.warmCream,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Reset Password',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: isDark
                      ? FormaColors.darkPrimaryText
                      : FormaColors.lightPrimaryText,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter your account email to receive a password reset link.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? FormaColors.darkSecondaryText
                          : FormaColors.lightSecondaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FormaTextField(
                    hint: 'Email address',
                    controller: _resetEmailController,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  if (dialogStatus != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      dialogStatus!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: dialogStatus!.contains('sent')
                            ? FormaColors.success
                            : FormaColors.coralPink,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('Cancel',
                      style: TextStyle(
                          color:
                              isDark ? Colors.white70 : FormaColors.charcoal)),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          final email = _resetEmailController.text.trim();
                          if (email.isEmpty) {
                            setDialogState(() =>
                                dialogStatus = 'Please enter your email.');
                            return;
                          }
                          setDialogState(() => isSending = true);
                          try {
                            await _auth.sendPasswordResetEmail(email: email);
                            setDialogState(() {
                              isSending = false;
                              dialogStatus =
                                  'Reset link sent! Check your inbox.';
                            });
                          } catch (_) {
                            setDialogState(() {
                              isSending = false;
                              dialogStatus =
                                  'Failed to send reset email. Verify address.';
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FormaColors.primaryAccent,
                    foregroundColor: FormaColors.charcoal,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Send Reset Link',
                          style: TextStyle(fontWeight: FontWeight.w800)),
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

    return Scaffold(
      backgroundColor:
          isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: isDark ? Colors.white : FormaColors.charcoal),
          onPressed: () {
            if (_isPhoneMode) {
              setState(() {
                _isPhoneMode = false;
                _otpSent = false;
                _errorMessage = null;
              });
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: FormaSpacing.lg, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Official FORMA Brand Header
                  const FormaLogo(
                    size: 44,
                    showWordmark: true,
                    wordmarkSize: 22,
                  ),
                  const SizedBox(height: 24),

                  Text(
                    _isPhoneMode
                        ? (_otpSent ? 'Enter SMS Code' : 'Sign in with Phone')
                        : (_isRegisterMode ? 'Create Account' : 'Welcome back'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                      color: isDark
                          ? FormaColors.darkPrimaryText
                          : FormaColors.lightPrimaryText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isPhoneMode
                        ? (_otpSent
                            ? 'We sent a 6-digit verification code to ${_selectedCountry.dialCode} ${_phoneController.text.trim()}'
                            : 'Enter your phone number to receive an instant OTP.')
                        : (_isRegisterMode
                            ? 'Begin your personalized fitness journey.'
                            : 'Sign in to access your workouts, food logs & progress.'),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? FormaColors.darkSecondaryText
                          : FormaColors.lightSecondaryText,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Error Banner
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: FormaColors.coralPink.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color:
                                FormaColors.coralPink.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: FormaColors.coralPink, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: FormaColors.coralPink,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── Mode 1: Phone Authentication Flow ──
                  if (_isPhoneMode) ...[
                    if (!_otpSent) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tappable Country Code Picker Pill
                          GestureDetector(
                            onTap: () async {
                              final chosen = await showCountryCodePicker(
                                context,
                                selectedCountry: _selectedCountry,
                              );
                              if (chosen != null) {
                                setState(() => _selectedCountry = chosen);
                              }
                            },
                            child: Container(
                              height: 54,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? FormaColors.charcoal
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : FormaColors.concreteGrey
                                          .withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _selectedCountry.flag,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _selectedCountry.dialCode,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.white
                                          : FormaColors.charcoal,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_drop_down_rounded,
                                    size: 20,
                                    color: isDark
                                        ? Colors.white70
                                        : FormaColors.charcoal,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FormaTextField(
                              hint:
                                  'Phone (${_selectedCountry.minDigits} digits)',
                              controller: _phoneController,
                              prefixIcon: Icons.phone_rounded,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      FormaButton(
                        label: 'Send Verification Code',
                        onPressed: _isLoading ? null : _sendPhoneOtp,
                        isLoading: _isLoading,
                        icon: Icons.sms_rounded,
                      ),
                    ] else ...[
                      FormaTextField(
                        hint: '6-digit OTP code',
                        controller: _otpController,
                        prefixIcon: Icons.pin_rounded,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed:
                                _resendCooldown > 0 ? null : _sendPhoneOtp,
                            child: Text(
                              _resendCooldown > 0
                                  ? 'Resend code in ${_resendCooldown}s'
                                  : 'Resend OTP',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _resendCooldown > 0
                                    ? FormaColors.concreteGrey
                                    : FormaColors.primaryAccent,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _otpSent = false;
                                _errorMessage = null;
                              });
                            },
                            child: const Text('Change number',
                                style: TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      FormaButton(
                        label: 'Verify & Sign In',
                        onPressed: _isLoading ? null : _verifyPhoneOtp,
                        isLoading: _isLoading,
                        icon: Icons.check_circle_rounded,
                      ),
                    ],
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _isPhoneMode = false;
                            _errorMessage = null;
                          });
                        },
                        child: const Text('Use Email or Google instead',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ] else ...[
                    // ── Mode 2: Multi-Method (Google, Email, Phone) ──

                    // 1. Primary Google Sign-In Action
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isDark
                            ? FormaColors.darkCardBackground
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white12
                              : FormaColors.charcoal.withValues(alpha: 0.15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: _isLoading ? null : _handleGoogleSignIn,
                        borderRadius: BorderRadius.circular(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                              width: 22,
                              height: 22,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.g_mobiledata_rounded,
                                  size: 28,
                                  color: Color(0xFF4285F4)),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? FormaColors.darkPrimaryText
                                    : FormaColors.lightPrimaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Divider with "or with email"
                    Row(
                      children: [
                        Expanded(
                            child: Divider(
                                color:
                                    isDark ? Colors.white12 : Colors.black12)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'or',
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? FormaColors.darkSecondaryText
                                    : FormaColors.lightSecondaryText),
                          ),
                        ),
                        Expanded(
                            child: Divider(
                                color:
                                    isDark ? Colors.white12 : Colors.black12)),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Email Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (_isRegisterMode) ...[
                            FormaTextField(
                              hint: 'Full name',
                              controller: _nameController,
                              prefixIcon: Icons.person_outline_rounded,
                            ),
                            const SizedBox(height: 14),
                          ],
                          FormaTextField(
                            hint: 'Email address',
                            controller: _emailController,
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          FormaTextField(
                            hint: 'Password',
                            controller: _passwordController,
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: FormaColors.concreteGrey,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          if (_isRegisterMode) ...[
                            const SizedBox(height: 14),
                            FormaTextField(
                              hint: 'Confirm password',
                              controller: _confirmPasswordController,
                              prefixIcon: Icons.lock_outline_rounded,
                              obscureText: _obscurePassword,
                            ),
                          ],
                        ],
                      ),
                    ),

                    if (!_isRegisterMode) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPasswordDialog,
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: FormaColors.primaryAccent,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Submit Email Action
                    FormaButton(
                      label: _isRegisterMode ? 'Create Account' : 'Sign In',
                      onPressed: _isLoading ? null : _handleEmailAuth,
                      isLoading: _isLoading,
                      icon: _isRegisterMode
                          ? Icons.person_add_rounded
                          : Icons.login_rounded,
                    ),

                    const SizedBox(height: 14),

                    // Continue with Phone Number CTA
                    Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.phone_android_rounded, size: 18),
                        label: const Text('Continue with Phone Number (OTP)',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        onPressed: () {
                          setState(() {
                            _isPhoneMode = true;
                            _errorMessage = null;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Toggle Register / Sign In
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isRegisterMode
                                ? 'Already have an account?'
                                : "Don't have an account?",
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? FormaColors.darkSecondaryText
                                  : FormaColors.lightSecondaryText,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isRegisterMode = !_isRegisterMode;
                                _errorMessage = null;
                              });
                            },
                            child: Text(
                              _isRegisterMode ? 'Sign In' : 'Create one',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: FormaColors.primaryAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Privacy & Terms Footer
                  Center(
                    child: Text(
                      'By continuing, you agree to FORMA’s Terms & Privacy Policy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? FormaColors.darkSecondaryText
                            : FormaColors.lightSecondaryText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const FormaLoadingOverlay(title: 'Authenticating with FORMA...'),
        ],
      ),
    );
  }
}

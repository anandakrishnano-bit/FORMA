import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';

import 'package:forma/core/components/forma_button.dart';
import 'package:forma/core/components/forma_text_field.dart';
import 'package:forma/core/components/forma_loading_overlay.dart';
import 'package:forma/core/components/forma_logo.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/core/legal/terms_data.dart';
import 'package:forma/data/models/preset_avatar_model.dart';
import 'package:forma/features/authentication/widgets/country_code_picker.dart';
import 'package:forma/features/home/repositories/home_customization_repository.dart';

/// Progressive, premium first-time user onboarding journey:
/// - Screen 2: Authentication Choice (Google, Email, Phone OTP, or Sign In)
/// - Screen 3: Basic Personalization (Display Name + Optional Profile Picture)
/// - Screen 4: Focus Areas ("What would you like to focus on?" 4 feature cards)
/// - Screen 5: You're all set! ("Your FORMA space is ready. Let's make today count.")
class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() =>
      _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  final PageController _pageController = PageController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  int _currentStep = 0;

  // Auth Form Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  // Personalization State
  final _displayNameController = TextEditingController();
  String? _selectedAvatarKey;

  // Feature Focus Selection (Screen 4)
  final Set<String> _selectedFocusAreas = {'Workouts', 'Habits'};

  // State
  bool _isLoading = false;
  String? _errorMessage;
  bool _showEmailFields = false;
  bool _isPhoneMode = false;
  bool _otpSent = false;
  String? _verificationId;
  int _resendCooldown = 60;
  Timer? _cooldownTimer;
  CountryInfo _selectedCountry = CountryInfo.defaultCountry;
  bool _obscurePassword = true;
  bool _termsAccepted = false;

  @override
  void initState() {
    super.initState();
    // If user is already authenticated (e.g. via Google or Phone and redirected),
    // skip directly to Screen 3 (Basic Personalization)
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      _currentStep = 1;
      _displayNameController.text = currentUser.displayName ?? '';
      _selectedAvatarKey = currentUser.photoURL;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(1);
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _displayNameController.dispose();
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

  void _goToStep(int step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _currentStep = step;
      _errorMessage = null;
    });
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  void _prevStep() {
    FocusScope.of(context).unfocus();
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    } else {
      context.pop();
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
      // Always clear any cached session so the user can choose which Google account to use
      try {
        await googleSignIn.signOut();
      } catch (_) {}
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
      final user = userCredential.user;
      if (user != null) {
        _displayNameController.text = user.displayName ?? '';
        _selectedAvatarKey = user.photoURL;

        // Check if this existing user already completed onboarding
        final doc = await _firestore.collection('users').doc(user.uid).get();
        final isComplete = (doc.data()?['onboardingComplete'] as bool?) ??
            (doc.data()?['onboardingCompleted'] as bool?) ??
            false;

        if (isComplete && mounted) {
          context.go('/home');
          return;
        }

        if (mounted) {
          setState(() => _isLoading = false);
          _goToStep(1); // Advance to Personalization
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Google sign in could not be completed.';
      if (e.code == 'account-exists-with-different-credential') {
        message =
            'An account already exists with this email. Please sign in with your password.';
      } else if (e.code == 'network-request-failed') {
        message = 'Could not connect. Please check your internet connection.';
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
      final errStr = e.toString();
      String message = 'Could not sign in with Google: $e';
      if (errStr.contains('ApiException: 10') ||
          errStr.contains('api_exception: 10') ||
          errStr.contains('code: 10')) {
        message =
            'Google Sign-In configuration error (ApiException: 10). The release SHA-1 certificate fingerprint is not registered in Firebase Console.';
      } else if (errStr.contains('network') || errStr.contains('SocketException')) {
        message = 'Could not connect. Please check your internet connection.';
      }
      if (mounted) {
        setState(() {
          _errorMessage = message;
          _isLoading = false;
        });
      }
    }
  }

  // ──────────────────────── Email Registration ────────────────────────
  Future<void> _handleEmailRegister() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your name.');
      return;
    }
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }
    if (!_termsAccepted) {
      setState(() => _errorMessage =
          'Please read and agree to the Terms and Conditions to continue.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(name).catchError((_) {});
        _displayNameController.text = name;
        if (mounted) {
          setState(() => _isLoading = false);
          _goToStep(1); // Advance to Personalization
        }
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message =
              'An account with this email already exists. Please sign in instead.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'weak-password':
          message = 'Password must be at least 6 characters.';
          break;
        case 'network-request-failed':
          message = 'Could not connect. Please check your internet connection.';
          break;
        case 'operation-not-allowed':
          message =
              'Email/Password sign-in is disabled in Firebase Console. Please enable Email/Password under Authentication > Sign-in method in Firebase Console.';
          break;
        default:
          message = e.message ??
              'We could not create your account. Please check your details.';
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
          _errorMessage =
              'An error occurred while creating your account: ${e.toString()}';
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
          'Please enter a valid ${_selectedCountry.minDigits}-digit phone number.');
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
          if (mounted) {
            setState(() => _isLoading = false);
            _goToStep(1);
          }
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                'Verification failed. Please check the phone number format.';
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
      setState(() => _errorMessage = 'Please enter the complete 6-digit code.');
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
      final user = userCredential.user;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        final isComplete = (doc.data()?['onboardingComplete'] as bool?) ??
            (doc.data()?['onboardingCompleted'] as bool?) ??
            false;

        if (isComplete && mounted) {
          context.go('/home');
          return;
        }

        if (mounted) {
          setState(() => _isLoading = false);
          _goToStep(1); // Advance to Personalization
        }
      }
    } on FirebaseAuthException catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Incorrect code. Please check your SMS and try again.';
        });
      }
    }
  }

  // ──────────────────────── Final Completion (Screen 5) ────────────────────────
  Future<void> _completeOnboardingAndEnter() async {
    final user = _auth.currentUser;
    if (user == null) {
      // If user session lost, return to Auth choice
      _goToStep(0);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final finalName = _displayNameController.text.trim().isNotEmpty
          ? _displayNameController.text.trim()
          : (user.displayName ?? 'Athlete');

      await user.updateDisplayName(finalName).catchError((_) {});

      final friendCode = 'FORMA-${user.uid.substring(0, 6).toUpperCase()}';
      final focusList = _selectedFocusAreas.toList();

      // Write verified user document to Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email ?? '',
        'phoneNumber': user.phoneNumber ?? '',
        'displayName': finalName,
        'photoURL': _selectedAvatarKey ?? user.photoURL ?? '',
        'friendCode': friendCode,
        'friends': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'onboardingComplete': true,
        'onboardingCompleted': true,
        'termsAcceptedVersion': FormaTermsData.currentVersion,
        'termsAcceptedAt': FieldValue.serverTimestamp(),
        'accountStatus': 'active',
        'preferences': {
          'focusAreas': focusList,
        },
      }, SetOptions(merge: true));

      // Personalize Home card layout based on user's chosen focus areas
      await ref
          .read(homeCardConfigsProvider.notifier)
          .applyFocusAreas(focusList);

      if (mounted) {
        context.go('/home');
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Could not save your preferences. Please tap below to try again.';
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
        leading: _currentStep > 0
            ? IconButton(
                icon: Icon(Icons.arrow_back_rounded,
                    color: isDark ? Colors.white : FormaColors.charcoal),
                onPressed: _prevStep,
              )
            : IconButton(
                icon: Icon(Icons.close_rounded,
                    color: isDark ? Colors.white : FormaColors.charcoal),
                onPressed: () => context.pop(),
              ),
        title: Text(
          _currentStep == 0 ? 'Join FORMA' : 'Step $_currentStep of 3',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark
                ? FormaColors.darkSecondaryText
                : FormaColors.lightSecondaryText,
          ),
        ),
        centerTitle: true,
        actions: [
          // Skip option for optional personalization steps (1: Name/Avatar, 2: Focus)
          if (_currentStep == 1 || _currentStep == 2)
            TextButton(
              onPressed: () {
                if (_currentStep == 1) {
                  _goToStep(2);
                } else if (_currentStep == 2) {
                  _goToStep(3);
                }
              },
              child: const Text(
                'Skip',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: FormaColors.primaryAccent,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Step Progress Indicator (Steps 1 through 3)
                if (_currentStep > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _currentStep / 3.0,
                        minHeight: 4,
                        backgroundColor: isDark
                            ? Colors.white10
                            : FormaColors.charcoal.withValues(alpha: 0.08),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            FormaColors.primaryAccent),
                      ),
                    ),
                  ),

                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // Screen 2: Authentication Choice
                      _buildAuthChoiceSlide(isDark),

                      // Screen 3: Basic Personalization (Display Name + Optional Profile Picture)
                      _buildProfileSlide(isDark),

                      // Screen 4: Personalize your FORMA experience ("What would you like to focus on?")
                      _buildFocusSelectionSlide(isDark),

                      // Screen 5: You're all set!
                      _buildCompletionSlide(isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            FormaLoadingOverlay(
              title: _currentStep == 3
                  ? 'Preparing your space...'
                  : 'Getting your account ready...',
            ),
        ],
      ),
    );
  }

  // ──────────────────────── SCREEN 2: AUTHENTICATION CHOICE ────────────────────────
  Widget _buildAuthChoiceSlide(bool isDark) {
    final primaryTextColor =
        isDark ? FormaColors.darkPrimaryText : FormaColors.lightPrimaryText;
    final secondaryTextColor =
        isDark ? FormaColors.darkSecondaryText : FormaColors.lightSecondaryText;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Official FORMA Brand Header
          const FormaLogo(
            size: 40,
            showWordmark: true,
            wordmarkSize: 20,
          ),
          const SizedBox(height: 20),

          Text(
            _isPhoneMode
                ? (_otpSent ? 'Enter verification code' : 'Continue with Phone')
                : 'Create your account',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isPhoneMode
                ? (_otpSent
                    ? 'We sent a 6-digit code to ${_selectedCountry.dialCode} ${_phoneController.text.trim()}'
                    : 'Enter your phone number to receive a verification code.')
                : 'Join FORMA to build better routines, track your progress, and stay organised.',
            style: TextStyle(
              fontSize: 14,
              color: secondaryTextColor,
              height: 1.4,
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
                    color: FormaColors.coralPink.withValues(alpha: 0.4)),
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

          // ── Mode A: Phone Authentication Flow ──
          if (_isPhoneMode) ...[
            if (!_otpSent) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? FormaColors.charcoal : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white12
                              : FormaColors.concreteGrey
                                  .withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_selectedCountry.flag,
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 6),
                          Text(
                            _selectedCountry.dialCode,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_drop_down_rounded,
                              size: 20, color: secondaryTextColor),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FormaTextField(
                      hint: 'Phone number',
                      controller: _phoneController,
                      prefixIcon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FormaButton(
                label: 'Send Verification Code',
                onPressed: _isLoading ? null : _sendPhoneOtp,
                isLoading: _isLoading,
                icon: Icons.sms_rounded,
              ),
            ] else ...[
              FormaTextField(
                hint: '6-digit code',
                controller: _otpController,
                prefixIcon: Icons.pin_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _resendCooldown > 0 ? null : _sendPhoneOtp,
                    child: Text(
                      _resendCooldown > 0
                          ? 'Resend code in ${_resendCooldown}s'
                          : 'Resend code',
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
                label: 'Verify & Continue',
                onPressed: _isLoading ? null : _verifyPhoneOtp,
                isLoading: _isLoading,
                icon: Icons.check_circle_rounded,
              ),
            ],
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _isPhoneMode = false;
                    _errorMessage = null;
                  });
                },
                child: const Text('Use other sign up options',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ] else ...[
            // ── Mode B: Multi-Method Choice (Google, Email, Phone) ──

            // 1. Continue with Google
            Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                color: isDark ? FormaColors.darkCardBackground : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white12
                      : FormaColors.charcoal.withValues(alpha: 0.15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
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
                        color: primaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 2. Continue with Email
            if (!_showEmailFields) ...[
              Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  color: isDark ? FormaColors.charcoal : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white12
                        : FormaColors.charcoal.withValues(alpha: 0.15),
                  ),
                ),
                child: InkWell(
                  onTap: () => setState(() => _showEmailFields = true),
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.email_outlined,
                          size: 20, color: primaryTextColor),
                      const SizedBox(width: 12),
                      Text(
                        'Continue with email',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? FormaColors.charcoal : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white12
                        : FormaColors.charcoal.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  children: [
                    FormaTextField(
                      hint: 'Your name',
                      controller: _nameController,
                      prefixIcon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 12),
                    FormaTextField(
                      hint: 'Email address',
                      controller: _emailController,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    FormaTextField(
                      hint: 'Password (min. 6 characters)',
                      controller: _passwordController,
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: FormaColors.concreteGrey,
                          size: 18,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _termsAccepted,
                            onChanged: (val) =>
                                setState(() => _termsAccepted = val ?? false),
                            activeColor: FormaColors.primaryAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(
                                () => _termsAccepted = !_termsAccepted),
                            child: Text.rich(
                              TextSpan(
                                text: 'I agree to the ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: secondaryTextColor,
                                  height: 1.4,
                                ),
                                children: [
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.baseline,
                                    baseline: TextBaseline.alphabetic,
                                    child: GestureDetector(
                                      onTap: () =>
                                          context.push('/terms-and-conditions'),
                                      child: const Text(
                                        'Terms and Conditions',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: FormaColors.primaryAccent,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const TextSpan(text: ' of FORMA.'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FormaButton(
                      label: 'Create Account',
                      onPressed: _isLoading ? null : _handleEmailRegister,
                      isLoading: _isLoading,
                      icon: Icons.arrow_forward_rounded,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // 3. Continue with Phone Number
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.phone_android_rounded, size: 18),
                label: const Text('Continue with phone number',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: () {
                  setState(() {
                    _isPhoneMode = true;
                    _errorMessage = null;
                  });
                },
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Divider and Existing User Sign-In CTA
          Row(
            children: [
              Expanded(
                  child:
                      Divider(color: isDark ? Colors.white12 : Colors.black12)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'Already have an account?',
                  style: TextStyle(
                    fontSize: 13,
                    color: secondaryTextColor,
                  ),
                ),
              ),
              Expanded(
                  child:
                      Divider(color: isDark ? Colors.white12 : Colors.black12)),
            ],
          ),
          const SizedBox(height: 14),

          Center(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark
                      ? Colors.white24
                      : FormaColors.charcoal.withValues(alpha: 0.2),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              onPressed: () => context.push('/login'),
              child: Text(
                'Sign In to Existing Account',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: primaryTextColor,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ──────────────────────── SCREEN 3: BASIC PERSONALIZATION ────────────────────────
  Widget _buildProfileSlide(bool isDark) {
    final primaryTextColor =
        isDark ? FormaColors.darkPrimaryText : FormaColors.lightPrimaryText;
    final secondaryTextColor =
        isDark ? FormaColors.darkSecondaryText : FormaColors.lightSecondaryText;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What should we call you?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your name will appear on your progress logs and profile.',
            style: TextStyle(
              fontSize: 14,
              color: secondaryTextColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),

          // Avatar Selector Node
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _showAvatarOptionsSheet,
                  child: Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? FormaColors.charcoal
                              : FormaColors.warmCream,
                          border: Border.all(
                            color: FormaColors.primaryAccent,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: isDark ? 0.3 : 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _selectedAvatarKey != null &&
                                  _selectedAvatarKey!.startsWith('preset:')
                              ? Icon(
                                  _getPresetIcon(_selectedAvatarKey!),
                                  size: 42,
                                  color: FormaColors.primaryAccent,
                                )
                              : (_selectedAvatarKey != null &&
                                      _selectedAvatarKey!.isNotEmpty
                                  ? ClipOval(
                                      child: Image.network(
                                        _selectedAvatarKey!,
                                        width: 96,
                                        height: 96,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                          Icons.person_rounded,
                                          size: 48,
                                          color: FormaColors.primaryAccent,
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person_rounded,
                                      size: 48,
                                      color: FormaColors.primaryAccent,
                                    )),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: FormaColors.primaryAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.palette_rounded,
                            size: 16,
                            color: FormaColors.charcoal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _showAvatarOptionsSheet,
                  child: const Text(
                    'Choose profile avatar',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Name Input Field
          Text(
            'DISPLAY NAME',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          FormaTextField(
            hint: 'e.g. Alex Smith',
            controller: _displayNameController,
            prefixIcon: Icons.badge_outlined,
          ),

          const SizedBox(height: 36),

          FormaButton(
            label: 'Continue',
            onPressed: () {
              FocusScope.of(context).unfocus();
              _goToStep(2); // Advance to Feature Personalization
            },
            icon: Icons.arrow_forward_rounded,
          ),
        ],
      ),
    );
  }

  // ──────────────────────── SCREEN 4: FEATURE FOCUS SELECTION ────────────────────────
  Widget _buildFocusSelectionSlide(bool isDark) {
    final primaryTextColor =
        isDark ? FormaColors.darkPrimaryText : FormaColors.lightPrimaryText;
    final secondaryTextColor =
        isDark ? FormaColors.darkSecondaryText : FormaColors.lightSecondaryText;

    final features = [
      {
        'id': 'Workouts',
        'title': 'Workouts',
        'subtitle': 'Track workouts and training activity.',
        'icon': Icons.fitness_center_rounded,
        'accent': FormaColors.coralPink,
      },
      {
        'id': 'Nutrition',
        'title': 'Nutrition',
        'subtitle': 'Organise food logs and nutrition information.',
        'icon': Icons.restaurant_rounded,
        'accent': FormaColors.goldenYellow,
      },
      {
        'id': 'Habits',
        'title': 'Habits',
        'subtitle': 'Build and track everyday routines.',
        'icon': Icons.check_circle_outline_rounded,
        'accent': FormaColors.sage,
      },
      {
        'id': 'Expenses',
        'title': 'Expenses',
        'subtitle': 'Keep track of personal spending.',
        'icon': Icons.account_balance_wallet_rounded,
        'accent': FormaColors.icyBlue,
      },
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What would you like to focus on?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Choose what you'd like to explore. You can change this anytime.",
            style: TextStyle(
              fontSize: 14,
              color: secondaryTextColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // 4 Selectable Feature Cards
          ...features.map((feature) {
            final id = feature['id'] as String;
            final title = feature['title'] as String;
            final subtitle = feature['subtitle'] as String;
            final icon = feature['icon'] as IconData;
            final accent = feature['accent'] as Color;
            final isSelected = _selectedFocusAreas.contains(id);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (isSelected) {
                      _selectedFocusAreas.remove(id);
                    } else {
                      _selectedFocusAreas.add(id);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? (isSelected
                            ? FormaColors.charcoal
                            : FormaColors.darkCardBackground)
                        : (isSelected ? Colors.white : FormaColors.warmCream),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? accent
                          : (isDark
                              ? Colors.white10
                              : FormaColors.divider.withValues(alpha: 0.5)),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 22, color: accent),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? accent : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? accent
                                : (isDark ? Colors.white30 : Colors.black26),
                            width: 1.5,
                          ),
                        ),
                        child: isSelected
                            ? const Center(
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          FormaButton(
            label: 'Continue',
            onPressed: () => _goToStep(3), // Advance to Completion
            icon: Icons.arrow_forward_rounded,
          ),
        ],
      ),
    );
  }

  // ──────────────────────── SCREEN 5: YOU'RE ALL SET! ────────────────────────
  Widget _buildCompletionSlide(bool isDark) {
    final primaryTextColor =
        isDark ? FormaColors.darkPrimaryText : FormaColors.lightPrimaryText;
    final secondaryTextColor =
        isDark ? FormaColors.darkSecondaryText : FormaColors.lightSecondaryText;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
              minWidth: constraints.maxWidth,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Official FORMA Logo
                  const FormaLogo(
                    size: 80,
                    isCropped: false,
                  ),
                  const SizedBox(height: 28),

                  // Refined Completion Checkmark Badge
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: FormaColors.sage.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 40,
                        color: FormaColors.sage,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Heading
                  Text(
                    "You're all set!",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      color: primaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Your FORMA space is ready. Let's make today count.",
                      style: TextStyle(
                        fontSize: 15,
                        color: secondaryTextColor,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  if (_selectedFocusAreas.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: _selectedFocusAreas.map((f) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? FormaColors.charcoal
                                : FormaColors.warmCream,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white12
                                  : FormaColors.charcoal.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: primaryTextColor,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FormaColors.coralPink.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: FormaColors.coralPink),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: FormaColors.coralPink,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Primary Action: Enter FORMA
                  FormaButton(
                    label: 'Enter FORMA',
                    onPressed: _isLoading ? null : _completeOnboardingAndEnter,
                    isLoading: _isLoading,
                    icon: Icons.arrow_forward_rounded,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ──────────────────────── AVATAR PICKER SHEET ────────────────────────
  void _showAvatarOptionsSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor:
          isDark ? FormaColors.darkBackground : FormaColors.warmCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Choose an Avatar',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? FormaColors.darkPrimaryText
                        : FormaColors.lightPrimaryText,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: FormaPresetAvatar.collection.length,
                    itemBuilder: (context, i) {
                      final preset = FormaPresetAvatar.collection[i];
                      final isSelected =
                          _selectedAvatarKey == preset.storageKey;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedAvatarKey = preset.storageKey;
                          });
                          Navigator.of(ctx).pop();
                        },
                        child: Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 12),
                          child: Column(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: preset.backgroundColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? FormaColors.primaryAccent
                                        : Colors.transparent,
                                    width: 2.5,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    preset.icon,
                                    size: 30,
                                    color: preset.primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                preset.name,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getPresetIcon(String storageKey) {
    for (final p in FormaPresetAvatar.collection) {
      if (p.storageKey == storageKey) {
        return p.icon;
      }
    }
    return Icons.person_rounded;
  }
}

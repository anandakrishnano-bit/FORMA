import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'package:forma/core/components/forma_button.dart';
import 'package:forma/core/components/forma_text_field.dart';
import 'package:forma/core/components/forma_loading_overlay.dart';
import 'package:forma/core/components/forma_logo.dart';
import 'package:forma/core/services/notification_service.dart';
import 'package:forma/core/services/secure_storage_service.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/models/habit.dart';
import 'package:forma/data/repositories/habit_repository.dart';

class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() =>
      _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 11;

  // Controllers for account creation
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();

  String? _accountStepError;
  String? _registrationError;
  bool _isRegistering = false;
  bool _obscurePassword = true;

  // Onboarding user preferences
  String _unitSystem = 'Metric (kg, km)';
  final List<String> _trainingDays = ['Mon', 'Wed', 'Fri'];
  final List<String> _selectedHabits = [
    'Drink 3L Water',
    'Daily Workout Session'
  ];
  final TextEditingController _customHabitController = TextEditingController();
  bool _wantsWorkoutReminders = true;
  bool _wantsDailySummary = true;
  String _personalGeminiKey = '';

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _customHabitController.dispose();
    super.dispose();
  }

  void _nextPage() {
    // If on account creation slide (index 1), validate inputs before proceeding
    if (_currentStep == 1) {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
        setState(
            () => _accountStepError = 'Please enter a valid email address.');
        return;
      }
      if (password.length < 6) {
        setState(() =>
            _accountStepError = 'Password must be at least 6 characters.');
        return;
      }
      setState(() => _accountStepError = null);
    }

    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeRegistrationAndEnterApp();
    }
  }

  void _prevPage() {
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.pop();
    }
  }

  Future<void> _completeRegistrationAndEnterApp() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Only require email and password if the user is not already authenticated
    if (currentUser == null && (email.isEmpty || password.isEmpty)) {
      // Jump back to account creation step if fields were skipped
      _pageController.jumpToPage(1);
      setState(() => _accountStepError =
          'Email and password are required to create an account.');
      return;
    }

    setState(() {
      _isRegistering = true;
      _registrationError = null;
    });

    try {
      final String uid;
      final String userEmail;

      if (currentUser != null) {
        // User already authenticated (Google, Phone OTP, or active session)
        uid = currentUser.uid;
        userEmail = currentUser.email ?? email;
      } else {
        final credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        uid = credential.user!.uid;
        userEmail = email;
      }

      final name = _displayNameController.text.trim().isNotEmpty
          ? _displayNameController.text.trim()
          : (currentUser?.displayName ?? 'Athlete');

      final activeUser = FirebaseAuth.instance.currentUser;
      if (activeUser != null && name.isNotEmpty) {
        await activeUser.updateDisplayName(name).catchError((_) {});
      }

      // Save real user document in Firestore with both onboarding flags set
      final friendCode = 'FORMA-${uid.substring(0, 6).toUpperCase()}';
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'email': userEmail,
        'displayName': name,
        'unitSystem': _unitSystem,
        'trainingDays': _trainingDays,
        'selectedHabits': _selectedHabits,
        'wantsWorkoutReminders': _wantsWorkoutReminders,
        'wantsDailySummary': _wantsDailySummary,
        'friendCode': friendCode,
        'friends': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'onboardingComplete': true,
        'onboardingCompleted': true,
      }, SetOptions(merge: true));

      // Save custom & selected habits into HabitRepository for immediate daily use
      final habitRepo = ref.read(habitRepositoryProvider);
      for (final hTitle in _selectedHabits) {
        habitRepo.addHabit(
          Habit(
            id: 'h_${DateTime.now().millisecondsSinceEpoch}_${hTitle.hashCode.abs()}',
            userId: uid,
            title: hTitle,
            frequency: 'Daily',
            streakCount: 0,
            createdAt: DateTime.now(),
          ),
        );
      }
      ref.invalidate(habitsListProvider);

      // Securely store personal Gemini API key if provided
      if (_personalGeminiKey.isNotEmpty) {
        await SecureStorageService().saveUserGeminiApiKey(_personalGeminiKey);
      }

      if (mounted) {
        context.go('/home');
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
          message = 'Password is too weak. Please use at least 6 characters.';
          break;
        case 'network-request-failed':
          message = 'Network error. Please check your internet connection.';
          break;
        default:
          message = e.message ?? 'Registration failed. Please try again.';
      }

      if (mounted) {
        setState(() {
          _isRegistering = false;
          _registrationError = message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRegistering = false;
          _registrationError = 'Error creating account: ${e.toString()}';
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _prevPage,
        ),
        title: Text(
          'Step ${_currentStep + 1} of $_totalSteps',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_currentStep > 1 && _currentStep < _totalSteps - 1)
            TextButton(
              onPressed: _nextPage,
              child: const Text('Skip',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Linear Progress Bar
                LinearProgressIndicator(
                  value: (_currentStep + 1) / _totalSteps,
                  backgroundColor: isDark
                      ? FormaColors.charcoal
                      : FormaColors.lightSecondaryBackground,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      FormaColors.primaryAccent),
                ),

                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics:
                        const NeverScrollableScrollPhysics(), // Controlled steps
                    onPageChanged: (page) =>
                        setState(() => _currentStep = page),
                    children: [
                      // 1. WELCOME
                      _buildSlide(
                        title: 'Welcome to FORMA',
                        subtitle:
                            'Your workouts, food, habits, and progress — all in one place.',
                        content: const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: FormaLogo(size: 130),
                          ),
                        ),
                        buttonLabel: 'Get Started',
                        onAction: _nextPage,
                      ),

                      // 2. CREATE ACCOUNT
                      _buildSlide(
                        title: 'Create Account',
                        subtitle: 'Secure email and password registration.',
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_accountStepError != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color: FormaColors.coralPink
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: FormaColors.coralPink
                                          .withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded,
                                        color: FormaColors.coralPink, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _accountStepError!,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: FormaColors.coralPink,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            FormaTextField(
                              hint: 'Email address',
                              controller: _emailController,
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 14),
                            FormaTextField(
                              hint: 'Password (min. 6 characters)',
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              prefixIcon: Icons.lock_outline,
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
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account?',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? FormaColors.darkSecondaryText
                                        : FormaColors.lightSecondaryText,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.push('/login'),
                                  child: const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: FormaColors.primaryAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        buttonLabel: 'Continue',
                        onAction: _nextPage,
                      ),

                      // 3. BASIC PROFILE
                      _buildSlide(
                        title: 'What should we call you?',
                        subtitle:
                            'Your name will appear on your workout logs and profile.',
                        content: Column(
                          children: [
                            FormaTextField(
                              hint: 'Your Name (e.g. Alex)',
                              controller: _displayNameController,
                              prefixIcon: Icons.person_outline_rounded,
                            ),
                          ],
                        ),
                        buttonLabel: 'Continue',
                        onAction: _nextPage,
                      ),

                      // 4. UNITS AND PREFERENCES
                      _buildSlide(
                        title: 'Select Units',
                        subtitle: 'You can change this anytime in Settings.',
                        content: Column(
                          children: [
                            _buildChoiceTile('Metric (kg, km)',
                                _unitSystem == 'Metric (kg, km)', () {
                              setState(() => _unitSystem = 'Metric (kg, km)');
                            }),
                            _buildChoiceTile('Imperial (lbs, miles)',
                                _unitSystem == 'Imperial (lbs, miles)', () {
                              setState(
                                  () => _unitSystem = 'Imperial (lbs, miles)');
                            }),
                          ],
                        ),
                        buttonLabel: 'Continue',
                        onAction: _nextPage,
                      ),

                      // 5. WORKOUT PREFERENCES
                      _buildSlide(
                        title: 'Workout Days',
                        subtitle: 'Select days you prefer to exercise.',
                        content: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            'Mon',
                            'Tue',
                            'Wed',
                            'Thu',
                            'Fri',
                            'Sat',
                            'Sun'
                          ].map((day) {
                            final isSel = _trainingDays.contains(day);
                            return ChoiceChip(
                              label: Text(day),
                              selected: isSel,
                              selectedColor: FormaColors.primaryAccent,
                              labelStyle: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isSel
                                    ? FormaColors.charcoal
                                    : (isDark
                                        ? Colors.white
                                        : FormaColors.charcoal),
                              ),
                              onSelected: (val) {
                                setState(() {
                                  if (val) {
                                    _trainingDays.add(day);
                                  } else {
                                    _trainingDays.remove(day);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        buttonLabel: 'Continue',
                        onAction: _nextPage,
                      ),

                      // 6. HABIT SELECTION (Multi-select & Custom Habits)
                      _buildSlide(
                        title: 'Your Daily Habits',
                        subtitle:
                            'Choose or add custom habits you want to track daily.',
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...[
                              'Drink 3L Water',
                              'Daily Workout Session',
                              'Hit Protein Target',
                              'Read 15 min',
                              '8 Hours Sleep',
                              'Morning Stretch',
                              '10,000 Steps',
                            ].map((habit) {
                              final isSelected =
                                  _selectedHabits.contains(habit);
                              return _buildChoiceTile(habit, isSelected, () {
                                setState(() {
                                  if (isSelected) {
                                    if (_selectedHabits.length > 1) {
                                      _selectedHabits.remove(habit);
                                    }
                                  } else {
                                    _selectedHabits.add(habit);
                                  }
                                });
                              });
                            }),

                            // Display any custom added habits
                            if (_selectedHabits.any((h) => ![
                                  'Drink 3L Water',
                                  'Daily Workout Session',
                                  'Hit Protein Target',
                                  'Read 15 min',
                                  '8 Hours Sleep',
                                  'Morning Stretch',
                                  '10,000 Steps',
                                ].contains(h))) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _selectedHabits
                                    .where((h) => ![
                                          'Drink 3L Water',
                                          'Daily Workout Session',
                                          'Hit Protein Target',
                                          'Read 15 min',
                                          '8 Hours Sleep',
                                          'Morning Stretch',
                                          '10,000 Steps',
                                        ].contains(h))
                                    .map((custom) => Chip(
                                          backgroundColor: FormaColors
                                              .primaryAccent
                                              .withValues(alpha: 0.2),
                                          label: Text(custom,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12)),
                                          deleteIcon: const Icon(
                                              Icons.close_rounded,
                                              size: 14),
                                          onDeleted: () {
                                            setState(() =>
                                                _selectedHabits.remove(custom));
                                          },
                                        ))
                                    .toList(),
                              ),
                            ],

                            const SizedBox(height: 12),
                            // Add custom habit input row
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _customHabitController,
                                    decoration: InputDecoration(
                                      hintText:
                                          'Add custom habit (e.g. Creatine 5g, Walk)...',
                                      hintStyle: const TextStyle(fontSize: 13),
                                      filled: true,
                                      fillColor: isDark
                                          ? FormaColors.darkCardBackground
                                          : FormaColors.warmCream,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    onSubmitted: (val) {
                                      if (val.trim().isNotEmpty) {
                                        setState(() {
                                          if (!_selectedHabits
                                              .contains(val.trim())) {
                                            _selectedHabits.add(val.trim());
                                          }
                                          _customHabitController.clear();
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filled(
                                  style: IconButton.styleFrom(
                                      backgroundColor:
                                          FormaColors.primaryAccent),
                                  icon: const Icon(Icons.add_rounded,
                                      color: FormaColors.charcoal),
                                  onPressed: () {
                                    final text =
                                        _customHabitController.text.trim();
                                    if (text.isNotEmpty) {
                                      setState(() {
                                        if (!_selectedHabits.contains(text)) {
                                          _selectedHabits.add(text);
                                        }
                                        _customHabitController.clear();
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        buttonLabel: 'Continue',
                        onAction: _nextPage,
                      ),

                      // 7. PRIVACY MANDATE
                      _buildSlide(
                        title: 'Private by Design',
                        subtitle:
                            'Your fitness and food diaries are 100% private.',
                        content: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark
                                ? FormaColors.charcoal
                                : FormaColors.warmCream,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: FormaColors.primaryAccent
                                          .withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.lock_rounded,
                                        size: 20,
                                        color: FormaColors.primaryAccent),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Private by Default',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Your personal workouts, weights, food entries, and habits are private. Only activities and challenges you explicitly choose to share with friends are visible.',
                                style: TextStyle(fontSize: 13, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                        buttonLabel: 'I Understand',
                        onAction: _nextPage,
                      ),

                      // 8. OPTIONAL GEMINI KEY
                      _buildSlide(
                        title: 'Personal AI Key (Optional)',
                        subtitle:
                            'Connect your personal Gemini API key for workout & nutrition clearing.',
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FormaTextField(
                              hint: 'AIzaSy... (leave blank to skip)',
                              obscureText: true,
                              prefixIcon: Icons.key_rounded,
                              onChanged: (v) =>
                                  setState(() => _personalGeminiKey = v.trim()),
                            ),
                            const SizedBox(height: 12),
                            if (_personalGeminiKey.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: FormaColors.success
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: FormaColors.success
                                          .withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded,
                                        size: 18, color: FormaColors.success),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _personalGeminiKey.startsWith('AIzaSy')
                                            ? 'Valid Gemini API key format detected'
                                            : 'Key entered: tap "Confirm API Key" below to save',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: FormaColors.success,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? FormaColors.charcoal
                                    : FormaColors.warmCream,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.shield_rounded,
                                      size: 16,
                                      color: FormaColors.primaryAccent),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Your key is encrypted in Android Keystore and never stored on any shared server. You can add or update this anytime in Settings.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? FormaColors.darkSecondaryText
                                            : FormaColors.lightSecondaryText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        bottomAction: _personalGeminiKey.isNotEmpty
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FormaButton(
                                    label: 'Confirm & Save API Key',
                                    icon: Icons.check_circle_rounded,
                                    onPressed: () async {
                                      FocusScope.of(context).unfocus();
                                      ScaffoldMessenger.of(context)
                                          .hideCurrentSnackBar();
                                      await SecureStorageService()
                                          .saveUserGeminiApiKey(
                                              _personalGeminiKey);
                                      _nextPage();
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: _nextPage,
                                    child: Text(
                                      'Skip for Now',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? FormaColors.darkSecondaryText
                                            : FormaColors.lightSecondaryText,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : FormaButton(
                                label: 'Skip for Now',
                                variant: FormaButtonVariant.secondary,
                                onPressed: _nextPage,
                              ),
                      ),

                      // 9. NOTIFICATION PERMISSIONS
                      _buildSlide(
                        title: 'Reminders & Quiet Hours',
                        subtitle:
                            'Stay on track without overwhelming notifications.',
                        content: Column(
                          children: [
                            SwitchListTile(
                              title: const Text('Workout Reminders',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
                              value: _wantsWorkoutReminders,
                              activeThumbColor: FormaColors.primaryAccent,
                              onChanged: (v) =>
                                  setState(() => _wantsWorkoutReminders = v),
                            ),
                            SwitchListTile(
                              title: const Text('Your Day in Review (Evening)',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
                              value: _wantsDailySummary,
                              activeThumbColor: FormaColors.primaryAccent,
                              onChanged: (v) =>
                                  setState(() => _wantsDailySummary = v),
                            ),
                          ],
                        ),
                        buttonLabel: 'Save Preferences',
                        onAction: () async {
                          await NotificationService().requestPermissions();
                          _nextPage();
                        },
                      ),

                      // 10. RECAP
                      _buildSlide(
                        title: 'Setup Summary',
                        subtitle: 'Review your personalized training profile.',
                        content: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? FormaColors.charcoal
                                : FormaColors.warmCream,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildRecapRow('Units', _unitSystem),
                              const Divider(height: 16),
                              _buildRecapRow(
                                  'Training Days', _trainingDays.join(', ')),
                              const Divider(height: 16),
                              _buildRecapRow(
                                  'Daily Habits', _selectedHabits.join(', ')),
                            ],
                          ),
                        ),
                        buttonLabel: 'Looks Great',
                        onAction: _nextPage,
                      ),

                      // 11. COMPLETION & ACCOUNT CREATION
                      _buildSlide(
                        title: "You're All Set!",
                        subtitle:
                            'Tap below to create your secure account and enter FORMA.',
                        content: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (_registrationError != null)
                              Container(
                                padding: const EdgeInsets.all(14),
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: FormaColors.coralPink
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: FormaColors.coralPink
                                          .withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded,
                                        color: FormaColors.coralPink, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _registrationError!,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: FormaColors.coralPink,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color:
                                    FormaColors.success.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_circle_rounded,
                                  size: 72, color: FormaColors.success),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Your private dashboard is ready.',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? FormaColors.darkSecondaryText
                                    : FormaColors.lightSecondaryText,
                              ),
                            ),
                          ],
                        ),
                        buttonLabel: _isRegistering
                            ? 'Creating Account...'
                            : (_registrationError != null
                                ? 'Retry Setup'
                                : 'Open Home Dashboard'),
                        isLoading: _isRegistering,
                        onAction: _isRegistering
                            ? () {}
                            : _completeRegistrationAndEnterApp,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isRegistering)
            const FormaLoadingOverlay(
                title: 'Setting up your personal FORMA...'),
        ],
      ),
    );
  }

  Widget _buildRecapRow(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: FormaColors.primaryAccent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlide({
    required String title,
    required String subtitle,
    required Widget content,
    String buttonLabel = 'Continue',
    VoidCallback? onAction,
    Widget? bottomAction,
    bool isLoading = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: isDark
                  ? FormaColors.darkPrimaryText
                  : FormaColors.lightPrimaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? FormaColors.darkSecondaryText
                  : FormaColors.lightSecondaryText,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                      minWidth: constraints.maxWidth,
                    ),
                    child: IntrinsicHeight(
                      child: content,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (bottomAction != null)
            bottomAction
          else
            FormaButton(
              label: buttonLabel,
              onPressed: isLoading ? null : (onAction ?? () {}),
              isLoading: isLoading,
            ),
        ],
      ),
    );
  }

  Widget _buildChoiceTile(String label, bool isSelected, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? FormaColors.darkCardBackground : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? FormaColors.primaryAccent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isDark
                    ? FormaColors.darkPrimaryText
                    : FormaColors.lightPrimaryText,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: FormaColors.primaryAccent, size: 20),
          ],
        ),
      ),
    );
  }
}

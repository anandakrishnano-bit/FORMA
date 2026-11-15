import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/core/components/forma_text_field.dart';

/// Account Connections & Firebase Provider Linking Screen.
///
/// Route: /account-connections
class AccountConnectionsScreen extends StatefulWidget {
  const AccountConnectionsScreen({super.key});

  @override
  State<AccountConnectionsScreen> createState() =>
      _AccountConnectionsScreenState();
}

class _AccountConnectionsScreenState extends State<AccountConnectionsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

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

  String? get _phoneNumber => _currentUser?.phoneNumber;

  Future<void> _linkGoogle() async {
    setState(() => _isLoading = true);
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: FormaColors.coralPink),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLinkEmailDialog() {
    final emailController = TextEditingController();
    final passController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        bool dialogLoading = false;
        String? dialogError;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return AlertDialog(
              backgroundColor:
                  isDark ? FormaColors.charcoal : FormaColors.warmCream,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22)),
              title: const Text('Connect Email & Password',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FormaTextField(
                      hint: 'Email address',
                      controller: emailController,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    FormaTextField(
                      hint: 'Password (min 6 chars)',
                      controller: passController,
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
                          final email = emailController.text.trim();
                          final pass = passController.text;
                          if (email.isEmpty || pass.length < 6) {
                            setDialogState(() => dialogError =
                                'Valid email and 6+ character password required.');
                            return;
                          }
                          setDialogState(() {
                            dialogLoading = true;
                            dialogError = null;
                          });

                          try {
                            final cred = EmailAuthProvider.credential(
                                email: email, password: pass);
                            await _currentUser?.linkWithCredential(cred);
                            await _currentUser?.sendEmailVerification();
                            await _currentUser?.reload();
                            if (mounted) {
                              Navigator.of(ctx).pop();
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      '✓ Email connected! Verification email sent.'),
                                  backgroundColor: FormaColors.success,
                                ),
                              );
                            }
                          } on FirebaseAuthException catch (e) {
                            setDialogState(() {
                              dialogLoading = false;
                              dialogError = e.message ?? 'Linking failed.';
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FormaColors.primaryAccent,
                    foregroundColor: FormaColors.charcoal,
                  ),
                  child: const Text('Connect',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLinkPhoneDialog() {
    final phoneController = TextEditingController(text: '+91 ');
    final otpController = TextEditingController();
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
                    FormaTextField(
                      hint: 'Phone number (e.g. +91 9876543210)',
                      controller: phoneController,
                      prefixIcon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                  ] else ...[
                    Text(
                      'Enter the 6-digit verification code sent to ${phoneController.text.trim()}',
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
                            final raw = phoneController.text.trim();
                            if (raw.length < 8) {
                              setDialogState(() => dialogError =
                                  'Enter a valid phone number with country code.');
                              return;
                            }
                            setDialogState(() {
                              dialogLoading = true;
                              dialogError = null;
                            });

                            await _auth.verifyPhoneNumber(
                              phoneNumber: raw,
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
                              setDialogState(() =>
                                  dialogError = 'Enter full 6-digit code.');
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
                              if (mounted) {
                                Navigator.of(ctx).pop();
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        '✓ Phone number connected successfully!'),
                                    backgroundColor: FormaColors.success,
                                  ),
                                );
                              }
                            } catch (e) {
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

    return Scaffold(
      backgroundColor:
          isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
      appBar: AppBar(
        title: const Text('Account Connections',
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
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoading) ...[
                const LinearProgressIndicator(color: FormaColors.primaryAccent),
                const SizedBox(height: 16),
              ],
              Text(
                'Linked Sign-In Methods',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? FormaColors.darkPrimaryText
                      : FormaColors.lightPrimaryText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Link Google, Email and Phone to sign into your existing FORMA account from any device without creating duplicate profiles.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? FormaColors.darkSecondaryText
                      : FormaColors.lightSecondaryText,
                ),
              ),

              const SizedBox(height: 24),

              // 1. Google Provider Tile
              _buildProviderTile(
                icon: Icons.g_mobiledata_rounded,
                iconColor: const Color(0xFF4285F4),
                title: 'Google Account',
                detail:
                    _hasGoogle ? (_googleEmail ?? 'Connected') : 'Not linked',
                isConnected: _hasGoogle,
                onConnect: _hasGoogle ? null : _linkGoogle,
              ),

              const SizedBox(height: 14),

              // 2. Email / Password Tile
              _buildProviderTile(
                icon: Icons.email_outlined,
                iconColor: FormaColors.goldenYellow,
                title: 'Email & Password',
                detail: _hasPassword
                    ? '${_passwordEmail ?? _currentUser?.email ?? ''} (${_currentUser?.emailVerified == true ? 'Verified' : 'Unverified'})'
                    : 'Not linked',
                isConnected: _hasPassword,
                onConnect: _hasPassword ? null : _showLinkEmailDialog,
              ),

              const SizedBox(height: 14),

              // 3. Phone Provider Tile
              _buildProviderTile(
                icon: Icons.phone_android_rounded,
                iconColor: FormaColors.sage,
                title: 'Phone Number (OTP)',
                detail: _hasPhone || _phoneNumber != null
                    ? (_phoneNumber ?? 'Connected')
                    : 'Not linked',
                isConnected: _hasPhone || _phoneNumber != null,
                onConnect: (_hasPhone || _phoneNumber != null)
                    ? null
                    : _showLinkPhoneDialog,
              ),

              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? FormaColors.charcoal : FormaColors.warmCream,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: FormaColors.concreteGrey.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_outline_rounded,
                        color: FormaColors.primaryAccent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your UID (${_currentUser?.uid.substring(0, 8)}...) is preserved across all connected sign-in methods. Your workouts, nutrition and habits remain safe and consolidated.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
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
    VoidCallback? onConnect,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? FormaColors.darkCardBackground
            : FormaColors.lightCardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
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
          if (isConnected)
            const ContainerBadge(label: 'Connected', isSuccess: true)
          else
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

class ContainerBadge extends StatelessWidget {
  final String label;
  final bool isSuccess;

  const ContainerBadge({super.key, required this.label, this.isSuccess = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isSuccess ? FormaColors.success : FormaColors.concreteGrey)
            .withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: isSuccess ? FormaColors.success : FormaColors.concreteGrey,
        ),
      ),
    );
  }
}

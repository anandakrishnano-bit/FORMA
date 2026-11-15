import 'package:flutter/material.dart';
import 'package:forma/core/components/forma_button.dart';
import 'package:forma/core/components/forma_text_field.dart';
import 'package:forma/core/services/secure_storage_service.dart';
import 'package:forma/core/theme/app_colors.dart';

class UserApiKeySettingsScreen extends StatefulWidget {
  const UserApiKeySettingsScreen({super.key});

  @override
  State<UserApiKeySettingsScreen> createState() =>
      _UserApiKeySettingsScreenState();
}

class _UserApiKeySettingsScreenState extends State<UserApiKeySettingsScreen> {
  final TextEditingController _keyController = TextEditingController();
  final SecureStorageService _secureStorage = SecureStorageService();
  bool _isLoading = true;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  Future<void> _loadKey() async {
    final existingKey = await _secureStorage.getUserGeminiKey();
    if (mounted) {
      setState(() {
        if (existingKey != null && existingKey.isNotEmpty) {
          _keyController.text = existingKey;
          _isSaved = true;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _saveKey() async {
    final text = _keyController.text.trim();
    if (text.isEmpty) {
      await _secureStorage.removeUserGeminiKey();
      if (mounted) {
        setState(() => _isSaved = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Assistant disconnected. Standard coaching guidance will be used.')),
        );
      }
      return;
    }

    await _secureStorage.saveUserGeminiKey(text);
    if (mounted) {
      setState(() => _isSaved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI Assistant connected securely!')),
      );
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
      appBar: AppBar(
        title: const Text('AI Assistant Connection',
            style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                physics: const BouncingScrollPhysics(),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color:
                          isDark ? FormaColors.charcoal : FormaColors.warmCream,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color:
                              FormaColors.primaryAccent.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: FormaColors.primaryAccent
                                    .withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: FormaColors.goldenYellow,
                                  size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AI Assistant',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? FormaColors.darkPrimaryText
                                          : FormaColors.lightPrimaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Connect your private coaching service.',
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
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your assistant helps you review workouts, nutrition, and daily routines. Your connection code is encrypted on your device and remains completely private.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: isDark
                                ? FormaColors.darkPrimaryText
                                : FormaColors.lightPrimaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'CONNECTION CODE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: isDark
                          ? FormaColors.darkSecondaryText
                          : FormaColors.lightSecondaryText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FormaTextField(
                    controller: _keyController,
                    hint: 'Paste your connection code (starts with AIzaSy...)',
                    obscureText: true,
                    prefixIcon: Icons.key_rounded,
                  ),
                  const SizedBox(height: 20),
                  FormaButton(
                    label: _isSaved ? 'Update Connection' : 'Save Connection',
                    onPressed: _saveKey,
                  ),
                  const SizedBox(height: 16),
                  if (_isSaved)
                    OutlinedButton(
                      onPressed: () {
                        _keyController.clear();
                        _saveKey();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: FormaColors.coralPink,
                        side: const BorderSide(color: FormaColors.coralPink),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Center(
                        child: Text('Disconnect Assistant',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? FormaColors.darkCardBackground
                          : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'How to get a connection code',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '1. Visit aistudio.google.com\n2. Sign in with your Google account\n3. Tap "Get API key" and copy your personal code here.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
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
      ),
    );
  }
}

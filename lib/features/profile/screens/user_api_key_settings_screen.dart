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
                  'Key removed. Personal Trainer will use standard guidance.')),
        );
      }
      return;
    }

    await _secureStorage.saveUserGeminiKey(text);
    if (mounted) {
      setState(() => _isSaved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Key saved securely in Android Keystore!')),
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
        title: const Text('Personal Trainer Connection',
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
                              child: const Icon(Icons.fitness_center_rounded,
                                  color: FormaColors.goldenYellow, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Personal Trainer Connection',
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
                          'Your key powers your private Personal Trainer and daily reviews. It is hardware-encrypted on your phone and never shared with other users or friends.',
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
                    'API KEY',
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
                    hint: 'Paste your key (starts with AIzaSy...)',
                    obscureText: true,
                    prefixIcon: Icons.key_rounded,
                  ),
                  const SizedBox(height: 20),
                  FormaButton(
                    label:
                        _isSaved ? 'Update Saved Key' : 'Save Key to Keystore',
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
                        child: Text('Remove Key',
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
                          'Where do I get a free key?',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '1. Visit aistudio.google.com\n2. Sign in with your Google account\n3. Tap "Get API key" and copy it here.',
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

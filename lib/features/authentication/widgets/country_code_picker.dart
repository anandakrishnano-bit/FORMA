import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forma/core/theme/app_colors.dart';

class CountryInfo {
  final String name;
  final String dialCode;
  final String flag;
  final String isoCode;
  final int minDigits;
  final int maxDigits;

  const CountryInfo({
    required this.name,
    required this.dialCode,
    required this.flag,
    required this.isoCode,
    this.minDigits = 8,
    this.maxDigits = 11,
  });

  static const List<CountryInfo> all = [
    CountryInfo(
      name: 'India',
      dialCode: '+91',
      flag: '🇮🇳',
      isoCode: 'IN',
      minDigits: 10,
      maxDigits: 10,
    ),
    CountryInfo(
      name: 'United States',
      dialCode: '+1',
      flag: '🇺🇸',
      isoCode: 'US',
      minDigits: 10,
      maxDigits: 10,
    ),
    CountryInfo(
      name: 'Canada',
      dialCode: '+1',
      flag: '🇨🇦',
      isoCode: 'CA',
      minDigits: 10,
      maxDigits: 10,
    ),
    CountryInfo(
      name: 'United Kingdom',
      dialCode: '+44',
      flag: '🇬🇧',
      isoCode: 'GB',
      minDigits: 10,
      maxDigits: 10,
    ),
    CountryInfo(
      name: 'Australia',
      dialCode: '+61',
      flag: '🇦🇺',
      isoCode: 'AU',
      minDigits: 9,
      maxDigits: 9,
    ),
    CountryInfo(
      name: 'United Arab Emirates',
      dialCode: '+971',
      flag: '🇦🇪',
      isoCode: 'AE',
      minDigits: 9,
      maxDigits: 9,
    ),
    CountryInfo(
      name: 'Germany',
      dialCode: '+49',
      flag: '🇩🇪',
      isoCode: 'DE',
      minDigits: 10,
      maxDigits: 11,
    ),
    CountryInfo(
      name: 'France',
      dialCode: '+33',
      flag: '🇫🇷',
      isoCode: 'FR',
      minDigits: 9,
      maxDigits: 9,
    ),
    CountryInfo(
      name: 'Singapore',
      dialCode: '+65',
      flag: '🇸🇬',
      isoCode: 'SG',
      minDigits: 8,
      maxDigits: 8,
    ),
    CountryInfo(
      name: 'Japan',
      dialCode: '+81',
      flag: '🇯🇵',
      isoCode: 'JP',
      minDigits: 10,
      maxDigits: 10,
    ),
    CountryInfo(
      name: 'New Zealand',
      dialCode: '+64',
      flag: '🇳🇿',
      isoCode: 'NZ',
      minDigits: 9,
      maxDigits: 9,
    ),
    CountryInfo(
      name: 'Netherlands',
      dialCode: '+31',
      flag: '🇳🇱',
      isoCode: 'NL',
      minDigits: 9,
      maxDigits: 9,
    ),
    CountryInfo(
      name: 'Spain',
      dialCode: '+34',
      flag: '🇪🇸',
      isoCode: 'ES',
      minDigits: 9,
      maxDigits: 9,
    ),
    CountryInfo(
      name: 'Italy',
      dialCode: '+39',
      flag: '🇮🇹',
      isoCode: 'IT',
      minDigits: 10,
      maxDigits: 10,
    ),
    CountryInfo(
      name: 'Brazil',
      dialCode: '+55',
      flag: '🇧🇷',
      isoCode: 'BR',
      minDigits: 10,
      maxDigits: 11,
    ),
    CountryInfo(
      name: 'South Africa',
      dialCode: '+27',
      flag: '🇿🇦',
      isoCode: 'ZA',
      minDigits: 9,
      maxDigits: 9,
    ),
  ];

  static CountryInfo get defaultCountry => all.first; // India (+91)
}

/// Modal bottom sheet to select a country code
Future<CountryInfo?> showCountryCodePicker(
  BuildContext context, {
  CountryInfo? selectedCountry,
}) {
  return showModalBottomSheet<CountryInfo>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _CountryPickerSheet(selectedCountry: selectedCountry),
  );
}

class _CountryPickerSheet extends StatefulWidget {
  final CountryInfo? selectedCountry;

  const _CountryPickerSheet({this.selectedCountry});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchController = TextEditingController();
  List<CountryInfo> _filtered = CountryInfo.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = CountryInfo.all;
      } else {
        _filtered = CountryInfo.all.where((c) {
          return c.name.toLowerCase().contains(query) ||
              c.dialCode.toLowerCase().contains(query) ||
              c.isoCode.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? FormaColors.charcoal : FormaColors.warmCream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: FormaColors.concreteGrey.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Country Code',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: isDark ? Colors.white : FormaColors.charcoal,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by country or code (e.g. India, +91)...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? FormaColors.darkSecondaryText
                      : FormaColors.lightSecondaryText,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : FormaColors.concreteGrey.withValues(alpha: 0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : FormaColors.concreteGrey.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: FormaColors.primaryAccent,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: _filtered.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: 64,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : FormaColors.concreteGrey.withValues(alpha: 0.15),
              ),
              itemBuilder: (context, index) {
                final country = _filtered[index];
                final isSelected =
                    widget.selectedCountry?.isoCode == country.isoCode;

                return ListTile(
                  leading: Text(
                    country.flag,
                    style: const TextStyle(fontSize: 26),
                  ),
                  title: Text(
                    country.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 15,
                      color: isDark ? Colors.white : FormaColors.charcoal,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        country.dialCode,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: isSelected
                              ? FormaColors.primaryAccent
                              : (isDark
                                  ? Colors.white70
                                  : FormaColors.charcoal),
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.check_circle_rounded,
                          color: FormaColors.primaryAccent,
                          size: 18,
                        ),
                      ],
                    ],
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop(country);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

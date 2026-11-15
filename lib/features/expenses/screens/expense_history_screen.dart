import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forma/core/components/expense_card.dart';
import 'package:forma/core/components/forma_bounceable.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/models/expense_model.dart';
import 'package:forma/data/repositories/expense_repository.dart';

/// Expense History Screen with real-time search and category filtering.
class ExpenseHistoryScreen extends ConsumerStatefulWidget {
  const ExpenseHistoryScreen({super.key});

  @override
  ConsumerState<ExpenseHistoryScreen> createState() =>
      _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState extends ConsumerState<ExpenseHistoryScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? FormaColors.darkPrimaryText : FormaColors.lightPrimaryText;
    final secondaryTextColor =
        isDark ? FormaColors.darkSecondaryText : FormaColors.lightSecondaryText;
    final cardBg = isDark ? FormaColors.charcoal : Colors.white;

    final expensesAsync = ref.watch(personalExpensesStreamProvider);

    return Scaffold(
      backgroundColor:
          isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: primaryTextColor, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Expense History',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: primaryTextColor,
          ),
        ),
      ),
      body: SafeArea(
        child: expensesAsync.when(
          data: (allExpenses) {
            // Apply search query
            final query = _searchController.text.trim().toLowerCase();
            final filtered = allExpenses.where((exp) {
              final matchesQuery = query.isEmpty ||
                  exp.title.toLowerCase().contains(query) ||
                  (exp.note?.toLowerCase().contains(query) ?? false);

              final matchesCat = _selectedCategory == 'All' ||
                  exp.category.toLowerCase() == _selectedCategory.toLowerCase();

              return matchesQuery && matchesCat;
            }).toList();

            final totalSum =
                filtered.fold<double>(0.0, (sum, e) => sum + e.amount);

            final categoriesList = [
              'All',
              ...ExpenseCategory.defaultCategories.map((c) => c.name)
            ];

            return Column(
              children: [
                // Search Bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(color: primaryTextColor, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search by title or note...',
                      hintStyle: TextStyle(
                          color: secondaryTextColor.withValues(alpha: 0.6)),
                      prefixIcon:
                          Icon(Icons.search_rounded, color: secondaryTextColor),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: cardBg,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                            color:
                                isDark ? Colors.white10 : FormaColors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                            color:
                                isDark ? Colors.white10 : FormaColors.divider),
                      ),
                    ),
                  ),
                ),

                // Category Filter Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Row(
                    children: categoriesList.map((cat) {
                      final isSel =
                          _selectedCategory.toLowerCase() == cat.toLowerCase();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FormaBounceable(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSel ? FormaColors.primaryAccent : cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSel
                                    ? FormaColors.primaryAccent
                                    : (isDark
                                        ? Colors.white10
                                        : FormaColors.divider),
                              ),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    isSel ? FontWeight.w800 : FontWeight.w600,
                                color: isSel
                                    ? FormaColors.charcoal
                                    : primaryTextColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Total Filtered Bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${filtered.length} record${filtered.length == 1 ? "" : "s"}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: secondaryTextColor,
                        ),
                      ),
                      Text(
                        'Total: ₹${totalSum.toStringAsFixed(totalSum.truncateToDouble() == totalSum ? 0 : 2)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: FormaColors.primaryAccent,
                        ),
                      ),
                    ],
                  ),
                ),

                // List of Expenses
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off_rounded,
                                  size: 48, color: secondaryTextColor),
                              const SizedBox(height: 12),
                              Text(
                                'No matching expenses found',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: primaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          physics: const BouncingScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (context, idx) {
                            final expense = filtered[idx];
                            return ExpenseCard(
                              expense: expense,
                              heroPrefix: 'hist_exp',
                              onTap: () => context.push(
                                '/expenses/detail',
                                extra: expense,
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
          loading: () => const Center(
              child:
                  CircularProgressIndicator(color: FormaColors.primaryAccent)),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}

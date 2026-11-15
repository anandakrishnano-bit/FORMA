import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/core/bug_report/models/bug_report_category.dart';
import 'package:forma/core/bug_report/models/bug_report_model.dart';
import 'package:forma/core/bug_report/models/bug_report_status.dart';
import 'package:forma/core/bug_report/providers/bug_report_providers.dart';

/// Developer/Maintainer Dashboard listing all incoming bug reports with status tabs,
/// category filters, and search capabilities.
class MaintainerBugReportsScreen extends ConsumerStatefulWidget {
  const MaintainerBugReportsScreen({super.key});

  @override
  ConsumerState<MaintainerBugReportsScreen> createState() =>
      _MaintainerBugReportsScreenState();
}

class _MaintainerBugReportsScreenState
    extends ConsumerState<MaintainerBugReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  BugReportCategory? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: BugReportStatus.values.length + 1,
      vsync: this,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  BugReportStatus? get _currentStatusFilter {
    if (_tabController.index == 0) return null; // "All"
    return BugReportStatus.values[_tabController.index - 1];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filter = MaintainerReportsFilter(
      status: _currentStatusFilter,
      category: _selectedCategory,
    );
    final reportsAsync = ref.watch(allBugReportsProvider(filter));

    return Scaffold(
      backgroundColor:
          isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Bug Investigation Dashboard',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            indicatorColor: FormaColors.primaryAccent,
            tabs: [
              const Tab(text: 'All Reports'),
              ...BugReportStatus.values.map((s) => Tab(text: s.label)),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter & Search Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.trim().toLowerCase()),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search reference or keyword...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      filled: true,
                      fillColor: isDark
                          ? FormaColors.darkCardBackground
                          : FormaColors.lightCardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white10 : Colors.black12,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white10 : Colors.black12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<BugReportCategory?>(
                  icon: Icon(
                    Icons.filter_list_rounded,
                    color: _selectedCategory != null
                        ? FormaColors.primaryAccent
                        : (isDark ? Colors.white70 : Colors.black54),
                  ),
                  tooltip: 'Filter category',
                  onSelected: (cat) => setState(() => _selectedCategory = cat),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: null,
                      child: Text('All Categories'),
                    ),
                    ...BugReportCategory.values.map(
                      (c) => PopupMenuItem(
                        value: c,
                        child: Text(c.label),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Report List
          Expanded(
            child: reportsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text('Error loading reports: $err'),
              ),
              data: (reports) {
                // Apply search filter
                final filtered = reports.where((r) {
                  if (_searchQuery.isEmpty) return true;
                  return r.referenceCode.toLowerCase().contains(_searchQuery) ||
                      r.description.toLowerCase().contains(_searchQuery) ||
                      (r.userEmail?.toLowerCase().contains(_searchQuery) ??
                          false);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No bug reports match this criteria.',
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final report = filtered[index];
                    return _buildMaintainerCard(context, report, isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintainerCard(
      BuildContext context, BugReportModel report, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? FormaColors.darkCardBackground
            : FormaColors.lightCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.push(
              '/profile/help/maintainer-reports/detail',
              extra: report,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: report.status.badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        report.status.label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: report.status.badgeColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      report.referenceCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    if (report.screenshotUrl != null) ...[
                      const Icon(Icons.image_outlined,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      _formatDate(report.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? FormaColors.darkSecondaryText
                            : FormaColors.lightSecondaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  report.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, height: 1.3),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${report.deviceInfo['model'] ?? "Device"} • ${report.appInfo['version'] ?? "v1.0"}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? FormaColors.darkSecondaryText
                            : FormaColors.lightSecondaryText,
                      ),
                    ),
                    const Spacer(),
                    if (report.internalNotes != null &&
                        report.internalNotes!.isNotEmpty)
                      const Row(
                        children: [
                          Icon(Icons.notes_rounded,
                              size: 13, color: FormaColors.goldenYellow),
                          SizedBox(width: 4),
                          Text(
                            'Has Notes',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: FormaColors.goldenYellow,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

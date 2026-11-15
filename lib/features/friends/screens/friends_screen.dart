import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:forma/core/components/forma_avatar.dart';
import 'package:forma/core/components/forma_bounceable.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/models/friends_model.dart';
import 'package:forma/data/repositories/friends_social_repository.dart';
import 'package:forma/features/friends/screens/create_group_dialog.dart';
import 'package:forma/features/friends/screens/friend_profile_screen.dart';
import 'package:forma/features/friends/screens/group_details_screen.dart';

/// Complete Friends & Social Hub for FORMA.
///
/// ZERO FAKE DATA GUARANTEE:
/// - Connected purely to Firebase Firestore.
/// - 6 sections: Friend Requests, Your Friends, Find Friends, Friend Code Card, Private Groups, Shared Activity.
class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  int _selectedTab =
      0; // 0 = Friends & Requests, 1 = Find Friends, 2 = Groups, 3 = Activity
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _joinGroupCodeController =
      TextEditingController();

  List<FriendUser>? _searchResults;
  bool _isSearching = false;
  String? _searchError;
  final Set<String> _sentRequestUids = {};

  @override
  void dispose() {
    _searchController.dispose();
    _joinGroupCodeController.dispose();
    super.dispose();
  }

  void _copyMyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Friend code $code copied to clipboard!'),
        backgroundColor: FormaColors.charcoal,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareMyCode(String code) {
    SharePlus.instance.share(
      ShareParams(
        text:
            'Connect with me on FORMA! Add my friend code: $code to share workouts and progress.',
      ),
    );
  }

  Future<void> _handleSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    final results =
        await ref.read(friendsSocialRepositoryProvider).searchUsers(query);

    if (mounted) {
      setState(() {
        _isSearching = false;
        _searchResults = results;
        if (results.isEmpty) {
          _searchError =
              'No registered athlete found for "$query". Check username or friend code.';
        }
      });
    }
  }

  Future<void> _sendRequest(FriendUser user) async {
    HapticFeedback.lightImpact();
    setState(() => _sentRequestUids.add(user.uid));

    final (success, message) =
        await ref.read(friendsSocialRepositoryProvider).sendFriendRequest(user);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? FormaColors.success : FormaColors.charcoal,
        ),
      );
      if (!success) {
        setState(() => _sentRequestUids.remove(user.uid));
      }
    }
  }

  Future<void> _handleJoinGroup() async {
    final code = _joinGroupCodeController.text.trim();
    if (code.isEmpty) return;

    final (success, message) =
        await ref.read(friendsSocialRepositoryProvider).joinGroupByCode(code);

    if (mounted) {
      Navigator.of(context).pop();
      _joinGroupCodeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? FormaColors.success : FormaColors.error,
        ),
      );
    }
  }

  void _showJoinGroupDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join Private Group'),
        content: TextField(
          controller: _joinGroupCodeController,
          decoration: const InputDecoration(
            labelText: 'Group Join Code',
            hintText: 'e.g. GRP-XYZ123',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          TextButton(
            onPressed: _handleJoinGroup,
            style:
                TextButton.styleFrom(foregroundColor: FormaColors.goldenYellow),
            child: const Text('Join Group',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final incomingRequestsAsync = ref.watch(incomingFriendRequestsProvider);
    final outgoingRequestsAsync = ref.watch(outgoingFriendRequestsProvider);
    final confirmedFriendsAsync = ref.watch(confirmedFriendsStreamProvider);
    final groupsAsync = ref.watch(userGroupsStreamProvider);
    final activitiesAsync = ref.watch(socialActivitiesStreamProvider);
    final myCodeAsync = ref.watch(myFriendCodeStreamProvider);

    final incomingCount = incomingRequestsAsync.valueOrNull?.length ?? 0;

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
        backgroundColor:
            isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back to Home',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          title: const Text('Friends & Social',
              style: TextStyle(fontWeight: FontWeight.w800)),
          centerTitle: false,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Top Bento Segment Switcher
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color:
                        isDark ? FormaColors.charcoal : const Color(0xFFF0ECE4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSegmentButton(
                          index: 0,
                          label: 'Friends',
                          badgeCount: incomingCount,
                          isDark: isDark,
                        ),
                      ),
                      Expanded(
                        child: _buildSegmentButton(
                          index: 1,
                          label: 'Find',
                          badgeCount: 0,
                          isDark: isDark,
                        ),
                      ),
                      Expanded(
                        child: _buildSegmentButton(
                          index: 2,
                          label: 'Groups',
                          badgeCount: 0,
                          isDark: isDark,
                        ),
                      ),
                      Expanded(
                        child: _buildSegmentButton(
                          index: 3,
                          label: 'Activity',
                          badgeCount: 0,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: IndexedStack(
                  index: _selectedTab,
                  children: [
                    // Tab 0: Friends & Requests (Sections 1 & 2 & 4)
                    _buildFriendsTab(
                      incomingRequestsAsync: incomingRequestsAsync,
                      outgoingRequestsAsync: outgoingRequestsAsync,
                      confirmedFriendsAsync: confirmedFriendsAsync,
                      myCodeAsync: myCodeAsync,
                      isDark: isDark,
                    ),

                    // Tab 1: Find Friends (Section 3)
                    _buildFindFriendsTab(isDark: isDark),

                    // Tab 2: Groups (Section 5)
                    _buildGroupsTab(groupsAsync: groupsAsync, isDark: isDark),

                    // Tab 3: Activity (Section 6)
                    _buildActivityTab(
                        activitiesAsync: activitiesAsync, isDark: isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required int index,
    required String label,
    required int badgeCount,
    required bool isDark,
  }) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedTab = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? FormaColors.goldenYellow : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? FormaColors.charcoal
                    : (isDark
                        ? FormaColors.darkSecondaryText
                        : FormaColors.lightSecondaryText),
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: const BoxDecoration(
                  color: FormaColors.coralPink,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // TAB 0: YOUR FRIENDS & REQUESTS + FRIEND CODE CARD
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildFriendsTab({
    required AsyncValue<List<FriendRequest>> incomingRequestsAsync,
    required AsyncValue<List<FriendRequest>> outgoingRequestsAsync,
    required AsyncValue<List<FriendUser>> confirmedFriendsAsync,
    required AsyncValue<String> myCodeAsync,
    required bool isDark,
  }) {
    final incoming = incomingRequestsAsync.valueOrNull ?? [];
    final outgoing = outgoingRequestsAsync.valueOrNull ?? [];
    final friends = confirmedFriendsAsync.valueOrNull ?? [];
    final myCode = myCodeAsync.valueOrNull ?? 'FORMA-ATHLETE';

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(incomingFriendRequestsProvider);
        ref.invalidate(outgoingFriendRequestsProvider);
        ref.invalidate(confirmedFriendsStreamProvider);
        ref.invalidate(myFriendCodeStreamProvider);
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // 4. Friend Code Card
          _buildMyFriendCodeCard(myCode, isDark),
          const SizedBox(height: 20),

          // 1. Pending Friend Requests (Incoming)
          if (incoming.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.mark_email_unread_rounded,
                    size: 18, color: FormaColors.goldenYellow),
                const SizedBox(width: 8),
                Text(
                  'Friend Requests (${incoming.length})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? FormaColors.darkPrimaryText
                        : FormaColors.lightPrimaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...incoming.map((req) => _buildIncomingRequestCard(req, isDark)),
            const SizedBox(height: 20),
          ],

          // Outgoing Requests
          if (outgoing.isNotEmpty) ...[
            Text(
              'Pending Outgoing Requests (${outgoing.length})',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? FormaColors.darkSecondaryText
                    : FormaColors.lightSecondaryText,
              ),
            ),
            const SizedBox(height: 8),
            ...outgoing.map((req) => _buildOutgoingRequestCard(req, isDark)),
            const SizedBox(height: 20),
          ],

          // 2. Confirmed Friends
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Friends (${friends.length})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? FormaColors.darkPrimaryText
                      : FormaColors.lightPrimaryText,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _selectedTab = 1),
                child: const Text(
                  '+ Find Friends',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: FormaColors.secondaryAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (confirmedFriendsAsync.isLoading &&
              !confirmedFriendsAsync.hasValue)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: FormaColors.goldenYellow),
              ),
            )
          else if (friends.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              decoration: BoxDecoration(
                color: isDark ? FormaColors.charcoal : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : FormaColors.divider.withValues(alpha: 0.6)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.people_outline_rounded,
                      size: 44, color: FormaColors.concreteGrey),
                  const SizedBox(height: 12),
                  Text(
                    'No Training Partners Yet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? FormaColors.darkPrimaryText
                          : FormaColors.lightPrimaryText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Share your friend code or search by username to connect with real athletes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? FormaColors.darkSecondaryText
                          : FormaColors.lightSecondaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FormaBounceable(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: FormaColors.goldenYellow,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Search by Username',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: FormaColors.charcoal),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: friends.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final friend = friends[index];
                return _buildFriendCard(friend, isDark);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMyFriendCodeCard(String myCode, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? FormaColors.charcoal : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white10
              : FormaColors.divider.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: FormaColors.goldenYellow.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.qr_code_2_rounded,
                        size: 20, color: FormaColors.goldenYellow),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'YOUR FRIEND CODE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: FormaColors.goldenYellow,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded, size: 18),
                onPressed: () => _shareMyCode(myCode),
                tooltip: 'Share code',
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _copyMyCode(myCode),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : const Color(0xFFF7F5F0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: FormaColors.goldenYellow.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      myCode,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: isDark
                            ? FormaColors.darkPrimaryText
                            : FormaColors.lightPrimaryText,
                      ),
                    ),
                  ),
                  const Icon(Icons.copy_rounded,
                      size: 18, color: FormaColors.goldenYellow),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Friends use this code to connect. Your personal finances and food intake remain strictly private.',
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? FormaColors.darkSecondaryText
                  : FormaColors.lightSecondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingRequestCard(FriendRequest req, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? FormaColors.charcoal : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: FormaColors.goldenYellow.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          FormaAvatar(
            photoUrl: req.senderAvatarUrl,
            name: req.senderName,
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.senderName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14),
                ),
                if (req.senderUsername.isNotEmpty)
                  Text(
                    '@${req.senderUsername}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? FormaColors.darkSecondaryText
                          : FormaColors.lightSecondaryText,
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    size: 20, color: FormaColors.concreteGrey),
                onPressed: () async {
                  await ref
                      .read(friendsSocialRepositoryProvider)
                      .declineFriendRequest(req.id);
                },
                tooltip: 'Decline',
              ),
              FormaBounceable(
                onTap: () async {
                  await ref
                      .read(friendsSocialRepositoryProvider)
                      .acceptFriendRequest(req);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: FormaColors.goldenYellow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Accept',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: FormaColors.charcoal),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutgoingRequestCard(FriendRequest req, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? FormaColors.charcoal : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Request to ${req.receiverName} (${req.receiverUsername.isNotEmpty ? "@${req.receiverUsername}" : "pending"})',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? FormaColors.darkSecondaryText
                    : FormaColors.lightSecondaryText,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await ref
                  .read(friendsSocialRepositoryProvider)
                  .cancelFriendRequest(req.id);
            },
            child: const Text('Cancel',
                style: TextStyle(fontSize: 12, color: FormaColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendCard(FriendUser friend, bool isDark) {
    return FormaBounceable(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => FriendProfileScreen(friend: friend)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? FormaColors.charcoal : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: isDark
                  ? Colors.white10
                  : FormaColors.divider.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Hero(
              tag: 'friend_avatar_${friend.uid}',
              child: FormaAvatar(
                photoUrl: friend.avatarUrl ?? friend.photoUrl,
                name: friend.displayName,
                size: 44,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.displayName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? FormaColors.darkPrimaryText
                          : FormaColors.lightPrimaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    friend.username.isNotEmpty
                        ? '@${friend.username}'
                        : friend.friendCode,
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
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: FormaColors.concreteGrey),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // TAB 1: FIND FRIENDS (Section 3)
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildFindFriendsTab({required bool isDark}) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        Text(
          'Find Friends',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark
                ? FormaColors.darkPrimaryText
                : FormaColors.lightPrimaryText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Search for genuine registered athletes by exact username or unique friend code.',
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? FormaColors.darkSecondaryText
                : FormaColors.lightSecondaryText,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText:
                      'Enter username (e.g. john) or code (FORMA-XXXX)...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: isDark ? FormaColors.charcoal : Colors.white,
                ),
                onSubmitted: (_) => _handleSearch(),
              ),
            ),
            const SizedBox(width: 10),
            FormaBounceable(
              onTap: _isSearching ? null : _handleSearch,
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: FormaColors.goldenYellow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: FormaColors.charcoal),
                        )
                      : const Text(
                          'Search',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: FormaColors.charcoal),
                        ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_searchError != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? FormaColors.charcoal : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _searchError!,
              style: const TextStyle(
                  fontSize: 13, color: FormaColors.concreteGrey),
            ),
          )
        else if (_searchResults != null) ...[
          Text(
            'Results (${_searchResults!.length})',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ..._searchResults!.map((target) {
            final isSent = _sentRequestUids.contains(target.uid);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? FormaColors.charcoal : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : FormaColors.divider.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  FormaAvatar(
                    photoUrl: target.avatarUrl ?? target.photoUrl,
                    name: target.displayName,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          target.displayName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        if (target.username.isNotEmpty)
                          Text(
                            '@${target.username}',
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
                  FormaBounceable(
                    onTap: isSent ? null : () => _sendRequest(target),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSent
                            ? (isDark ? Colors.white12 : Colors.black12)
                            : FormaColors.goldenYellow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isSent ? 'Sent' : 'Add Friend',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isSent
                              ? FormaColors.concreteGrey
                              : FormaColors.charcoal,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // TAB 2: PRIVATE GROUPS (Section 5)
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildGroupsTab({
    required AsyncValue<List<SocialGroup>> groupsAsync,
    required bool isDark,
  }) {
    final groups = groupsAsync.valueOrNull ?? [];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Private Groups (${groups.length})',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? FormaColors.darkPrimaryText
                    : FormaColors.lightPrimaryText,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.vpn_key_rounded, size: 20),
                  onPressed: _showJoinGroupDialog,
                  tooltip: 'Join with Code',
                ),
                FormaBounceable(
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (_) => const CreateGroupDialog());
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: FormaColors.goldenYellow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '+ Create',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: FormaColors.charcoal),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (groupsAsync.isLoading && !groupsAsync.hasValue)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: FormaColors.goldenYellow),
            ),
          )
        else if (groups.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: isDark ? FormaColors.charcoal : Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                const Icon(Icons.groups_outlined,
                    size: 44, color: FormaColors.concreteGrey),
                const SizedBox(height: 12),
                Text(
                  'No Groups Yet',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? FormaColors.darkPrimaryText
                        : FormaColors.lightPrimaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Create a private group for your gym buddies or enter an invite code to join one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? FormaColors.darkSecondaryText
                        : FormaColors.lightSecondaryText,
                  ),
                ),
              ],
            ),
          )
        else
          ...groups.map((group) {
            return FormaBounceable(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => GroupDetailsScreen(group: group)),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? FormaColors.charcoal : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : FormaColors.divider.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FormaColors.goldenYellow.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.groups_rounded,
                          color: FormaColors.goldenYellow, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${group.memberIds.length} members • Code: ${group.joinCode}',
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
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: FormaColors.concreteGrey),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // TAB 3: SHARED ACTIVITY FEED (Section 6)
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildActivityTab({
    required AsyncValue<List<SocialActivityItem>> activitiesAsync,
    required bool isDark,
  }) {
    final activities = activitiesAsync.valueOrNull ?? [];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        Text(
          'Shared Activity',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark
                ? FormaColors.darkPrimaryText
                : FormaColors.lightPrimaryText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Milestones and training consistency shared by your connected friends.',
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? FormaColors.darkSecondaryText
                : FormaColors.lightSecondaryText,
          ),
        ),
        const SizedBox(height: 16),
        if (activitiesAsync.isLoading && !activitiesAsync.hasValue)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: FormaColors.goldenYellow),
            ),
          )
        else if (activities.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: isDark ? FormaColors.charcoal : Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                const Icon(Icons.timeline_rounded,
                    size: 40, color: FormaColors.concreteGrey),
                const SizedBox(height: 12),
                Text(
                  'No Recent Activity',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? FormaColors.darkPrimaryText
                        : FormaColors.lightPrimaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'When your connected friends complete workouts or milestones, they will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? FormaColors.darkSecondaryText
                        : FormaColors.lightSecondaryText,
                  ),
                ),
              ],
            ),
          )
        else
          ...activities.map((act) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? FormaColors.charcoal : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? Colors.white10
                      : FormaColors.divider.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FormaAvatar(
                    photoUrl: act.userAvatarUrl,
                    name: act.userName,
                    size: 36,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          act.title,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          act.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? FormaColors.darkSecondaryText
                                : FormaColors.lightSecondaryText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          act.timeAgo,
                          style: const TextStyle(
                              fontSize: 11, color: FormaColors.concreteGrey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

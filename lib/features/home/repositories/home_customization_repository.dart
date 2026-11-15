import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:forma/core/services/app_logger.dart';
import 'package:forma/features/home/models/home_card_config.dart';

/// Manages persistent home screen card configuration with local SharedPreferences
/// and background Firestore sync.
class HomeCustomizationNotifier extends StateNotifier<List<HomeCardConfig>> {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  static const String _prefKey = 'forma_home_cards_v1';

  HomeCustomizationNotifier({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        super(HomeCardConfig.defaults) {
    _loadConfiguration();
  }

  Future<void> _loadConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString(_prefKey);

      if (localJson != null && localJson.isNotEmpty) {
        final decoded = jsonDecode(localJson) as List<dynamic>;
        final merged = _mergeWithDefaults(decoded);
        state = merged;
      }

      // Sync from Firestore if available
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        final doc = await _firestore
            .collection('users')
            .doc(uid)
            .collection('settings')
            .doc('home_cards')
            .get();
        if (doc.exists && doc.data() != null) {
          final cards = doc.data()!['cards'] as List<dynamic>?;
          if (cards != null && cards.isNotEmpty) {
            final merged = _mergeWithDefaults(cards);
            state = merged;
            // Update local cache
            await prefs.setString(
                _prefKey, jsonEncode(merged.map((c) => c.toMap()).toList()));
          }
        }
      }
    } catch (e) {
      AppLogger.warn(
          'HOME_CONFIG', 'Error loading home cards configuration: $e');
    }
  }

  List<HomeCardConfig> _mergeWithDefaults(List<dynamic> stored) {
    final defaults = HomeCardConfig.defaults;
    final Map<String, HomeCardConfig> defaultMap = {
      for (var d in defaults) d.id: d,
    };

    final List<HomeCardConfig> result = [];
    final Set<String> seenIds = {};

    for (var item in stored) {
      if (item is Map<String, dynamic>) {
        final id = item['id'] as String?;
        if (id != null && defaultMap.containsKey(id)) {
          final fallback = defaultMap[id]!;
          result.add(HomeCardConfig.fromMap(item, fallback));
          seenIds.add(id);
        }
      }
    }

    // Append any newly added default cards not present in stored config
    for (var d in defaults) {
      if (!seenIds.contains(d.id)) {
        result.add(d.copyWith(order: result.length));
      }
    }

    result.sort((a, b) => a.order.compareTo(b.order));
    return result;
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final items = List<HomeCardConfig>.from(state);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final movedItem = items.removeAt(oldIndex);
    items.insert(newIndex, movedItem);

    // Re-index orders
    final updated = <HomeCardConfig>[];
    for (int i = 0; i < items.length; i++) {
      updated.add(items[i].copyWith(order: i));
    }

    state = updated;
    await _persist(updated);
  }

  Future<void> toggleVisibility(String cardId) async {
    final updated = state.map((c) {
      if (c.id == cardId) {
        return c.copyWith(isVisible: !c.isVisible);
      }
      return c;
    }).toList();

    state = updated;
    await _persist(updated);
  }

  Future<void> applyFocusAreas(List<String> focusAreas) async {
    if (focusAreas.isEmpty) return;

    final preferredCardIds = <String>[];
    if (focusAreas.contains('Workouts')) {
      preferredCardIds.addAll(['today_focus', 'muscle_split']);
    }
    if (focusAreas.contains('Habits')) {
      preferredCardIds.addAll(['daily_habits', 'energy_score']);
    }
    if (focusAreas.contains('Nutrition')) {
      preferredCardIds.add('daily_pillars');
    }
    if (focusAreas.contains('Expenses')) {
      preferredCardIds.add('quick_tools');
    }

    final currentCards = List<HomeCardConfig>.from(state);
    final prioritized = <HomeCardConfig>[];
    final remaining = <HomeCardConfig>[];

    for (var card in currentCards) {
      if (preferredCardIds.contains(card.id)) {
        prioritized.add(card.copyWith(isVisible: true));
      } else {
        remaining.add(card.copyWith(isVisible: true));
      }
    }

    prioritized.sort((a, b) => preferredCardIds
        .indexOf(a.id)
        .compareTo(preferredCardIds.indexOf(b.id)));

    final combined = [...prioritized, ...remaining];
    final updated = <HomeCardConfig>[];
    for (int i = 0; i < combined.length; i++) {
      updated.add(combined[i].copyWith(order: i));
    }

    state = updated;
    await _persist(updated);
  }

  Future<void> resetToDefault() async {
    state = HomeCardConfig.defaults;
    await _persist(HomeCardConfig.defaults);
  }

  Future<void> _persist(List<HomeCardConfig> cards) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = cards.map((c) => c.toMap()).toList();
      await prefs.setString(_prefKey, jsonEncode(data));

      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('settings')
            .doc('home_cards')
            .set({'cards': data, 'updatedAt': FieldValue.serverTimestamp()},
                SetOptions(merge: true));
      }
    } catch (e) {
      AppLogger.warn('HOME_CONFIG', 'Failed to persist home cards: $e');
    }
  }
}

final homeCardConfigsProvider =
    StateNotifierProvider<HomeCustomizationNotifier, List<HomeCardConfig>>(
        (ref) {
  return HomeCustomizationNotifier();
});

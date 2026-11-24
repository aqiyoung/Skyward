import 'dart:convert';

import 'package:skyward/common/common.dart';
import 'package:skyward/core/core.dart';
import 'package:skyward/models/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _chainsKey = 'link-chains';

/// Loads saved chains from preferences. Kept independent of the generated
/// providers so this works without code generation.
Future<List<SavedChain>> loadSavedChains() async {
  final preferences = await Preferences().getString(_chainsKey);
  if (preferences == null || preferences.isEmpty) return const [];
  try {
    final decoded = json.decode(preferences) as List;
    return decoded
        .map((e) => SavedChain.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return const [];
  }
}

Future<void> storeSavedChains(List<SavedChain> chains) async {
  await Preferences().setString(
    _chainsKey,
    json.encode(chains.map((e) => e.toJson()).toList()),
  );
}

class _ChainsState extends Notifier<List<SavedChain>> {
  @override
  List<SavedChain> build() => const [];

  Future<void> load() async => state = await loadSavedChains();

  Future<void> upsert(SavedChain chain) async {
    final next = [
      for (final existing in state)
        if (existing.id != chain.id) existing,
      chain,
    ];
    state = next;
    await _commit();
  }

  Future<void> remove(int id) async {
    state = [for (final chain in state) if (chain.id != id) chain];
    await _commit();
  }

  Future<void> _commit() async {
    await storeSavedChains(state);
    // Make the enabled chains take effect on the next config apply.
    final enabled = [for (final chain in state) if (chain.enabled) chain];
    setActiveChains(
      enabled.isEmpty ? null : enabled.map((e) => e.toSpec()).toList(),
    );
  }
}

final chainsProvider = NotifierProvider<_ChainsState, List<SavedChain>>(
  _ChainsState.new,
);

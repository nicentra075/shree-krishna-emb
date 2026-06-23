import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

/// Stores the most-recently-opened design ids locally (newest first, capped).
/// Written by the design detail screen; read by the home feed datasource.
class RecentlyViewedStore {
  final Box<String> _box;
  static const _key = 'recent_design_ids';
  static const _cap = 20;

  RecentlyViewedStore(this._box);

  List<String> getIds() {
    final raw = _box.get(_key);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List).map((e) => e.toString()).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> add(String id) async {
    final ids = getIds().where((e) => e != id).toList()..insert(0, id);
    final capped = ids.take(_cap).toList();
    await _box.put(_key, jsonEncode(capped));
  }
}

import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/trophy_model.dart';

class TrophyAssetDataSource {
  const TrophyAssetDataSource(this._bundle);

  final AssetBundle _bundle;

  static String assetPathFor(String gameId) =>
      'assets/data/trophies/$gameId.json';

  Future<List<TrophyModel>> loadTrophies(String gameId) async {
    final raw = await _bundle.loadString(assetPathFor(gameId));
    final list = json.decode(raw) as List<dynamic>;
    return list
        .map((e) => TrophyModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

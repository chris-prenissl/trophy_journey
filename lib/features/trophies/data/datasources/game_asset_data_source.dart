import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/game_model.dart';

class GameAssetDataSource {
  const GameAssetDataSource(this._bundle);

  static const assetPath = 'assets/data/games.json';

  final AssetBundle _bundle;

  Future<List<GameModel>> loadGames() async {
    final raw = await _bundle.loadString(assetPath);
    final list = json.decode(raw) as List<dynamic>;
    return list
        .map((e) => GameModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

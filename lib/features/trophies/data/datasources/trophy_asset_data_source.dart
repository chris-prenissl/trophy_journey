import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/trophy_model.dart';

class TrophyAssetDataSource {
  const TrophyAssetDataSource(this._bundle);

  static const assetPath = 'assets/data/ffx_trophies.json';

  final AssetBundle _bundle;

  Future<List<TrophyModel>> loadTrophies() async {
    final raw = await _bundle.loadString(assetPath);
    final list = json.decode(raw) as List<dynamic>;
    return list
        .map((e) => TrophyModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

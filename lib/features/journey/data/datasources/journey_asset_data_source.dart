import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/journey_model.dart';

class JourneyAssetDataSource {
  JourneyAssetDataSource(this._bundle);

  final AssetBundle _bundle;
  Set<String>? _manifestKeys;

  static String assetPathFor(String gameId) =>
      'assets/data/journeys/$gameId.json';

  Future<JourneyModel> loadJourney(String gameId) async {
    final raw = await _bundle.loadString(assetPathFor(gameId));
    return JourneyModel.fromJson(json.decode(raw) as Map<String, dynamic>);
  }

  Future<bool> hasJourney(String gameId) async {
    final keys = _manifestKeys ??= (await AssetManifest.loadFromAssetBundle(
      _bundle,
    )).listAssets().toSet();
    return keys.contains(assetPathFor(gameId));
  }
}

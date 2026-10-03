import 'dart:convert';

import 'package:http/http.dart';

import '../models/psn_trophy_definition_model.dart';
import '../models/psn_trophy_title_model.dart';

class const PsnRequestException(final int statusCode) implements Exception {
  @override
  String toString() => 'PlayStation Network request failed ($statusCode)';
}

class PsnTrophyDataSource({Client? client, final String baseUrl = _baseUrl}) {
  static const _baseUrl = 'https://m.np.playstation.com';
  static const _titlePageSize = 800;

  final Client _client = client ?? Client();
  Future<List<PsnTrophyTitleModel>> fetchTrophyTitles() async {
    final titles = <PsnTrophyTitleModel>[];
    var offset = 0;

    while (true) {
      final json = await _get('/api/trophy/v1/users/me/trophyTitles', {
        'limit': '$_titlePageSize',
        'offset': '$offset',
      });
      final page = (json['trophyTitles'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();
      titles.addAll(page.map(PsnTrophyTitleModel.fromJson));

      final nextOffset = json['nextOffset'];
      if (page.isEmpty || nextOffset == null) {
        break;
      }

      offset = (nextOffset as num).toInt();
    }

    return titles;
  }

  Future<List<PsnTrophyDefinitionModel>> fetchTrophyDefinitions({
    required String npCommunicationId,
    required String npServiceName,
  }) async {
    final json = await _get(
      '/api/trophy/v1/npCommunicationIds/$npCommunicationId'
      '/trophyGroups/all/trophies',
      {'npServiceName': npServiceName},
    );
    return _trophyList(json).map(PsnTrophyDefinitionModel.fromJson).toList();
  }

  Future<Set<int>> fetchEarnedTrophyIds({
    required String npCommunicationId,
    required String npServiceName,
  }) async {
    final json = await _get(
      '/api/trophy/v1/users/me/npCommunicationIds/$npCommunicationId'
      '/trophyGroups/all/trophies',
      {'npServiceName': npServiceName},
    );
    return {
      for (final trophy in _trophyList(json).map(PsnEarnedTrophyModel.fromJson))
        if (trophy.earned) trophy.trophyId,
    };
  }

  static List<Map<String, dynamic>> _trophyList(Map<String, dynamic> json) =>
      (json['trophies'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> query,
  ) async {
    final response = await _client.get(
      Uri.parse(baseUrl).replace(path: path, queryParameters: query),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw PsnRequestException(response.statusCode);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

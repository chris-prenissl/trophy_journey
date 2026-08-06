import 'dart:convert';

import 'package:trophy_journey/features/trophies/data/datasources/psn_trophy_data_source.dart';
import 'package:trophy_journey/features/trophies/domain/entities/trophy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const baseUrl = 'https://psn.example.test';

({PsnTrophyDataSource dataSource, List<http.Request> requests}) buildDataSource({
  required List<Map<String, dynamic>> Function(http.Request) bodies,
  int statusCode = 200,
}) {
  final requests = <http.Request>[];
  final client = MockClient((request) async {
    requests.add(request);
    final path = request.url.path;
    final Object body = path.endsWith('/trophyTitles')
        ? {'trophyTitles': bodies(request)}
        : {'trophies': bodies(request)};
    return http.Response(jsonEncode(body), statusCode);
  });
  return (
    dataSource: PsnTrophyDataSource(client: client, baseUrl: baseUrl),
    requests: requests,
  );
}

void main() {
  group('failures', () {
    test('surfaces the status code when PSN rejects the call', () async {
      final (:dataSource, requests: _) = buildDataSource(
        bodies: (_) => [],
        statusCode: 401,
      );

      await expectLater(
        dataSource.fetchTrophyTitles(),
        throwsA(
          isA<PsnRequestException>().having((e) => e.statusCode, 'status', 401),
        ),
      );
    });
  });

  group('fetchTrophyTitles', () {
    test('parses the library entries', () async {
      final (:dataSource, :requests) = buildDataSource(
        bodies: (_) => [
          {
            'npCommunicationId': 'NPWR05698_00',
            'npServiceName': 'trophy',
            'trophyTitleName': 'FINAL FANTASY X HD Remaster',
            'trophyTitleIconUrl': 'https://img.example/ffx.png',
            'trophyTitlePlatform': 'PS4',
            'definedTrophies': {'bronze': 22, 'silver': 7, 'gold': 4, 'platinum': 1},
            'earnedTrophies': {'bronze': 5, 'silver': 1, 'gold': 0, 'platinum': 0},
            'lastUpdatedDateTime': '2026-07-30T12:00:00Z',
          },
        ],
      );

      final titles = await dataSource.fetchTrophyTitles();

      final title = titles.single;
      expect(title.npCommunicationId, 'NPWR05698_00');
      expect(title.trophyTitleName, 'FINAL FANTASY X HD Remaster');
      expect(title.definedTrophies.total, 34);
      expect(title.earnedTrophies.total, 6);
      expect(title.lastUpdatedDateTime, DateTime.parse('2026-07-30T12:00:00Z'));
      expect(
        requests.single.url.path,
        '/api/trophy/v1/users/me/trophyTitles',
      );
    });

    test('walks nextOffset until the library is complete', () async {
      final offsets = <String?>[];
      final client = MockClient((request) async {
        offsets.add(request.url.queryParameters['offset']);
        // The first page points at a second one; the second ends the walk.
        return http.Response(
          jsonEncode({
            'trophyTitles': [
              {'npCommunicationId': 'NPWR_PAGE_${offsets.length}'},
            ],
            if (offsets.length == 1) 'nextOffset': 800,
          }),
          200,
        );
      });
      final dataSource = PsnTrophyDataSource(client: client, baseUrl: baseUrl);

      final titles = await dataSource.fetchTrophyTitles();

      expect(titles, hasLength(2));
      expect(offsets, ['0', '800']);
    });
  });

  group('fetchTrophyDefinitions', () {
    test('parses the trophy list and keeps unknown grades bronze', () async {
      final (:dataSource, :requests) = buildDataSource(
        bodies: (_) => [
          {
            'trophyId': 0,
            'trophyName': 'Completion',
            'trophyDetail': 'Obtain all available trophies',
            'trophyType': 'platinum',
            'trophyIconUrl': 'https://img.example/plat.png',
            'trophyHidden': false,
          },
          {'trophyId': 3, 'trophyName': 'Oddity', 'trophyType': 'mystery'},
        ],
      );

      final definitions = await dataSource.fetchTrophyDefinitions(
        npCommunicationId: 'NPWR05698_00',
        npServiceName: 'trophy',
      );

      expect(definitions.first.trophyType, TrophyType.platinum);
      expect(definitions.last.trophyType, TrophyType.bronze);
      expect(
        requests.single.url.path,
        '/api/trophy/v1/npCommunicationIds/NPWR05698_00/trophyGroups/all/trophies',
      );
      expect(requests.single.url.queryParameters['npServiceName'], 'trophy');
    });
  });

  group('fetchEarnedTrophyIds', () {
    test('keeps only the earned ids, under either field spelling', () async {
      final (:dataSource, :requests) = buildDataSource(
        bodies: (_) => [
          {'trophyId': 1, 'earned': true},
          {'trophyId': 2, 'earned': false},
          {'trophyId': 3, 'trophyEarned': true},
          {'trophyId': 4},
        ],
      );

      final earned = await dataSource.fetchEarnedTrophyIds(
        npCommunicationId: 'NPWR05698_00',
        npServiceName: 'trophy',
      );

      expect(earned, {1, 3});
      expect(
        requests.single.url.path,
        '/api/trophy/v1/users/me/npCommunicationIds/NPWR05698_00'
        '/trophyGroups/all/trophies',
      );
    });
  });
}

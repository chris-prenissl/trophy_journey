import 'dart:convert';

import 'package:trophy_journey/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:trophy_journey/features/auth/data/models/auth_session_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'auth_local_data_source_test.mocks.dart';

@GenerateNiceMocks([MockSpec<FlutterSecureStorage>()])
void main() {
  late MockFlutterSecureStorage storage;
  late AuthLocalDataSourceImpl dataSource;

  final session = AuthSessionModel(
    userId: 'psn_user',
    accessToken: 'access',
    refreshToken: 'refresh',
    expiresAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() {
    storage = MockFlutterSecureStorage();
    dataSource = AuthLocalDataSourceImpl(storage);
  });

  group('getStoredSession', () {
    test('decodes the stored session', () async {
      when(
        storage.read(key: 'auth_session'),
      ).thenAnswer((_) async => jsonEncode(session.toJson()));

      final result = await dataSource.getStoredSession();

      expect(result?.userId, session.userId);
      expect(result?.accessToken, session.accessToken);
      expect(result?.expiresAt, session.expiresAt);
    });

    test('is null when nothing is stored', () async {
      when(storage.read(key: 'auth_session')).thenAnswer((_) async => null);

      expect(await dataSource.getStoredSession(), isNull);
    });

    test('is null when the stored value is malformed', () async {
      when(
        storage.read(key: 'auth_session'),
      ).thenAnswer((_) async => 'not json');

      expect(await dataSource.getStoredSession(), isNull);
    });
  });

  group('saveSession', () {
    test('writes the encoded session', () async {
      when(
        storage.write(key: anyNamed('key'), value: anyNamed('value')),
      ).thenAnswer((_) => Future.value());

      await dataSource.saveSession(session);

      final captured = verify(
        storage.write(key: 'auth_session', value: captureAnyNamed('value')),
      ).captured.single as String;
      expect(
        jsonDecode(captured) as Map<String, dynamic>,
        session.toJson(),
      );
    });
  });

  group('clearSession', () {
    test('deletes the stored session', () async {
      when(storage.delete(key: anyNamed('key'))).thenAnswer((_) => Future.value());

      await dataSource.clearSession();

      verify(storage.delete(key: 'auth_session')).called(1);
    });
  });
}

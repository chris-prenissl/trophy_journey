import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/auth_session.dart';

part 'auth_session_model.g.dart';

@JsonSerializable()
class AuthSessionModel {
  const AuthSessionModel({
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) =>
      _$AuthSessionModelFromJson(json);

  final String userId;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  Map<String, dynamic> toJson() => _$AuthSessionModelToJson(this);

  AuthSession toEntity() => AuthSession(
    userId: userId,
    accessToken: accessToken,
    refreshToken: refreshToken,
    expiresAt: expiresAt,
  );

  factory AuthSessionModel.fromEntity(AuthSession entity) => AuthSessionModel(
    userId: entity.userId,
    accessToken: entity.accessToken,
    refreshToken: entity.refreshToken,
    expiresAt: entity.expiresAt,
  );
}

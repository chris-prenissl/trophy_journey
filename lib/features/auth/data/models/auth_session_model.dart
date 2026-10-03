import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/auth_session.dart';

part 'auth_session_model.g.dart';

@JsonSerializable()
class const AuthSessionModel({
  required final String userId,
  required final String accessToken,
  required final String refreshToken,
  required final DateTime expiresAt,
}) {
  factory AuthSessionModel.fromJson(Map<String, dynamic> json) =>
      _$AuthSessionModelFromJson(json);

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

import 'package:json_annotation/json_annotation.dart';

part 'auth_token.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class AuthToken {
  @JsonKey(required: true)
  final String accessToken;

  @JsonKey(required: true)
  final String refreshToken;

  AuthToken({
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthToken.fromJson(Map<String, dynamic> json) =>
      _$AuthTokenFromJson(json);

  Map<String, dynamic> toJson() => _$AuthTokenToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class WsAuthToken {
  @JsonKey(required: true)
  final String accessToken;

  WsAuthToken({
    required this.accessToken,
  });

  factory WsAuthToken.fromJson(Map<String, dynamic> json) =>
      _$WsAuthTokenFromJson(json);

  Map<String, dynamic> toJson() => _$WsAuthTokenToJson(this);
}

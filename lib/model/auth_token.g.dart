// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthToken _$AuthTokenFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['access_token', 'refresh_token'],
  );
  return AuthToken(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String,
  );
}

Map<String, dynamic> _$AuthTokenToJson(AuthToken instance) => <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
    };

WsAuthToken _$WsAuthTokenFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['access_token'],
  );
  return WsAuthToken(
    accessToken: json['access_token'] as String,
  );
}

Map<String, dynamic> _$WsAuthTokenToJson(WsAuthToken instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
    };

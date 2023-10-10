// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Package _$PackageFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['code', 'owner_id', 'create_time', 'expire_time'],
  );
  return Package(
    code: json['code'] as String,
    ownerId: json['owner_id'] as String,
    createTime: DateTime.parse(json['create_time'] as String),
    expireTime: DateTime.parse(json['expire_time'] as String),
  );
}

Map<String, dynamic> _$PackageToJson(Package instance) => <String, dynamic>{
      'code': instance.code,
      'owner_id': instance.ownerId,
      'create_time': instance.createTime.toIso8601String(),
      'expire_time': instance.expireTime.toIso8601String(),
    };

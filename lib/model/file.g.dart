// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FileInfo _$FileInfoFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['name', 'size'],
  );
  return FileInfo(
    name: json['name'] as String,
    size: json['size'] as int,
    path: json['path'] as String?,
  );
}

Map<String, dynamic> _$FileInfoToJson(FileInfo instance) => <String, dynamic>{
      'name': instance.name,
      'size': instance.size,
      'path': instance.path,
    };

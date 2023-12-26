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
    textData: json['text_data'] as String?,
    path: json['path'] as String?,
  );
}

Map<String, dynamic> _$FileInfoToJson(FileInfo instance) => <String, dynamic>{
      'name': instance.name,
      'size': instance.size,
      'text_data': instance.textData,
      'path': instance.path,
    };

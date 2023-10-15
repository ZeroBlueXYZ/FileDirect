// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_signal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DataSignal _$DataSignalFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['type', 'message'],
  );
  return DataSignal(
    type: json['type'] as String,
    message: json['message'] as String,
  );
}

Map<String, dynamic> _$DataSignalToJson(DataSignal instance) =>
    <String, dynamic>{
      'type': instance.type,
      'message': instance.message,
    };

GetChunkRequest _$GetChunkRequestFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['file_id', 'start', 'end', 'chunk_size'],
  );
  return GetChunkRequest(
    fileId: json['file_id'] as int,
    start: json['start'] as int,
    end: json['end'] as int,
    chunkSize: json['chunk_size'] as int,
  );
}

Map<String, dynamic> _$GetChunkRequestToJson(GetChunkRequest instance) =>
    <String, dynamic>{
      'file_id': instance.fileId,
      'start': instance.start,
      'end': instance.end,
      'chunk_size': instance.chunkSize,
    };

ListFilesRequest _$ListFilesRequestFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['page'],
  );
  return ListFilesRequest(
    page: json['page'] as int,
  );
}

Map<String, dynamic> _$ListFilesRequestToJson(ListFilesRequest instance) =>
    <String, dynamic>{
      'page': instance.page,
    };

ListFilesResponse _$ListFilesResponseFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['files', 'next_page'],
  );
  return ListFilesResponse(
    files: (json['files'] as List<dynamic>)
        .map((e) => FileInfo.fromJson(e as Map<String, dynamic>))
        .toList(),
    nextPage: json['next_page'] as int,
  );
}

Map<String, dynamic> _$ListFilesResponseToJson(ListFilesResponse instance) =>
    <String, dynamic>{
      'files': instance.files.map((e) => e.toJson()).toList(),
      'next_page': instance.nextPage,
    };

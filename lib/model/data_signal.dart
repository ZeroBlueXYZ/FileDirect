import 'package:json_annotation/json_annotation.dart';

import 'package:anysend/model/file.dart';

part 'data_signal.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class DataSignal {
  @JsonKey(required: true)
  final String type;

  @JsonKey(required: true)
  final String message;

  DataSignal({
    required this.type,
    required this.message,
  });

  factory DataSignal.fromJson(Map<String, dynamic> json) =>
      _$DataSignalFromJson(json);

  Map<String, dynamic> toJson() => _$DataSignalToJson(this);
}

class DataSignalTypes {
  static const String listFiles = "LIST_FILES";
  static const String getChunk = "GET_CHUNK";
}

@JsonSerializable(fieldRename: FieldRename.snake)
class GetChunkRequest {
  @JsonKey(required: true)
  final int fileId;

  @JsonKey(required: true)
  final int start;

  @JsonKey(required: true)
  final int end;

  @JsonKey(required: true)
  final int chunkSize;

  GetChunkRequest({
    required this.fileId,
    required this.start,
    required this.end,
    required this.chunkSize,
  });

  factory GetChunkRequest.fromJson(Map<String, dynamic> json) =>
      _$GetChunkRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GetChunkRequestToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class ListFilesRequest {
  @JsonKey(required: true)
  final int page;

  ListFilesRequest({
    required this.page,
  });

  factory ListFilesRequest.fromJson(Map<String, dynamic> json) =>
      _$ListFilesRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ListFilesRequestToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class ListFilesResponse {
  @JsonKey(required: true)
  final List<FileInfo> files;

  @JsonKey(required: true)
  final int nextPage;

  ListFilesResponse({
    required this.files,
    required this.nextPage,
  });

  factory ListFilesResponse.fromJson(Map<String, dynamic> json) =>
      _$ListFilesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ListFilesResponseToJson(this);
}

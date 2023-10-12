import 'package:json_annotation/json_annotation.dart';

part 'file.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class FileInfo {
  @JsonKey(required: true)
  final String name;

  @JsonKey(required: true)
  final int size;

  final String? path;

  FileInfo({
    required this.name,
    required this.size,
    this.path,
  });

  factory FileInfo.fromJson(Map<String, dynamic> json) =>
      _$FileInfoFromJson(json);

  Map<String, dynamic> toJson() => _$FileInfoToJson(this);
}

class JobFile {
  final FileInfo info;
  int offset = 0;

  JobFile({required this.info});

  double get progress => info.size == 0 ? 1.0 : offset / info.size;
}

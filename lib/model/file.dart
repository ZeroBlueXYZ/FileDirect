import 'dart:io';
import 'dart:typed_data';

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
  IOSink? ioSink;
  int _writeOffset = 0;
  int requestedOffset = 0;
  int readSizeInBytes = 0;

  JobFile({required this.info});

  int get writeOffset => _writeOffset;
  double get writeProgress => info.size == 0 ? 1.0 : _writeOffset / info.size;

  IOSink openWrite() {
    if (ioSink == null) {
      _writeOffset = 0;
      ioSink = File(info.path!).openWrite();
    }

    return ioSink!;
  }

  void write(Uint8List data) {
    ioSink!.add(data);
    _writeOffset += data.lengthInBytes;
  }

  Future<void> closeWrite() async {
    await ioSink?.close();
  }
}

class FileChunk {
  int fileId;
  int offset;
  Uint8List data;

  FileChunk({
    required this.fileId,
    required this.offset,
    required this.data,
  });
}

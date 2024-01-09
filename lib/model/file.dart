import 'dart:io';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as path;

import 'package:anysend/util/file_helper.dart';

part 'file.g.dart';

enum FileInfoType {
  message,
  image,
  video,
  other,
}

@JsonSerializable(fieldRename: FieldRename.snake)
class FileInfo {
  @JsonKey(required: true)
  final String name;

  @JsonKey(required: true)
  final int size;

  String? textData; // for text

  String? path; // for file

  FileInfoType get type {
    if (textData != null) {
      return FileInfoType.message;
    } else if (name.isImage()) {
      return FileInfoType.image;
    } else if (name.isVideo()) {
      return FileInfoType.video;
    } else {
      return FileInfoType.other;
    }
  }

  FileInfo({
    required this.name,
    required this.size,
    this.textData,
    this.path,
  });

  factory FileInfo.fromJson(Map<String, dynamic> json) =>
      _$FileInfoFromJson(json);

  Map<String, dynamic> toJson() => _$FileInfoToJson(this);
}

class JobFile {
  static const maxWriteBufferSizeInBytes = 2 * 1024 * 1024; // 2 MB
  final FileInfo info;
  IOSink? _ioSink;
  int _writeOffset = 0;
  int requestedOffset = 0;
  int readSizeInBytes = 0;

  JobFile({required this.info});

  JobFile.inDirectory({
    required Directory directory,
    required String name,
    required int size,
  }) : info = FileInfo(name: name, size: size) {
    info.path = path.join(directory.path, name);
  }

  int get writeOffset => _writeOffset;
  double get writeProgress => info.size == 0 ? 1.0 : _writeOffset / info.size;

  Future<void> openWrite() async {
    if (_ioSink == null) {
      _writeOffset = 0;
      _ioSink = File(info.path!).openWrite();
    }
  }

  Future<void> write(Uint8List data) async {
    _ioSink!.add(data);
    _writeOffset += data.lengthInBytes;
  }

  Future<void> closeWrite() async {
    await _ioSink?.flush();
    await _ioSink?.close();
    _ioSink = null;
  }

  void markReadComplete() {
    readSizeInBytes = info.size;
  }

  void markWriteComplete() {
    _writeOffset = info.size;
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

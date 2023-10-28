import 'dart:io';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as path;
import 'package:shared_storage/shared_storage.dart' as saf;

import 'package:anysend/util/file_helper.dart';

part 'file.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class FileInfo {
  @JsonKey(required: true)
  final String name;

  @JsonKey(required: true)
  final int size;

  String? path;

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
  static const maxWriteBufferSizeInBytes = 2 * 1024 * 1024; // 2 MB
  final FileInfo info;
  Uri? directoryUri;
  saf.DocumentFile? _documentFile;
  BytesBuilder? _writeBuffer;
  IOSink? _ioSink;
  int _writeOffset = 0;
  int requestedOffset = 0;
  int readSizeInBytes = 0;

  JobFile({required this.info});

  JobFile.inDirectory({
    required Uri directoryUri,
    required String name,
    required int size,
  }) : info = FileInfo(name: name, size: size) {
    try {
      final Directory directory = Directory.fromUri(directoryUri);
      info.path = path.join(directory.path, name);
    } catch (e) {
      this.directoryUri = directoryUri;
    }
  }

  int get writeOffset => _writeOffset;
  double get writeProgress => info.size == 0 ? 1.0 : _writeOffset / info.size;

  Future<void> openWrite() async {
    if (info.path != null) {
      if (_ioSink == null) {
        _writeOffset = 0;
        _ioSink = File(info.path!).openWrite();
      }
    } else if (directoryUri != null) {
      _writeBuffer ??= BytesBuilder();
      _documentFile ??= await saf.createFile(
        directoryUri!,
        mimeType: info.name.mimeType(),
        displayName: info.name,
      );
    }
  }

  Future<void> write(Uint8List data) async {
    if (info.path != null) {
      _ioSink!.add(data);
      _writeOffset += data.lengthInBytes;
    } else if (directoryUri != null) {
      _writeBuffer!.add(data.toList());
      _writeOffset += data.lengthInBytes;
      if (_writeBuffer!.length >= maxWriteBufferSizeInBytes) {
        final Uint8List bytes = _writeBuffer!.takeBytes();
        await _documentFile!.writeToFileAsBytes(
          bytes: bytes,
          mode: FileMode.writeOnlyAppend,
        );
      }
    }
  }

  Future<void> closeWrite() async {
    if (info.path != null) {
      await _ioSink?.close();
    } else if (directoryUri != null) {
      if (_writeBuffer != null) {
        final Uint8List bytes = _writeBuffer!.takeBytes();
        await _documentFile!.writeToFileAsBytes(
          bytes: bytes,
          mode: FileMode.writeOnlyAppend,
        );
      }
      _documentFile = null;
      _writeBuffer = null;
    }
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

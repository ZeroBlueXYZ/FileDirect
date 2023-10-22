import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:path/path.dart' as path;

import 'package:anysend/model/data_signal.dart';
import 'package:anysend/model/file.dart';
import 'package:anysend/model/signal.dart';
import 'package:anysend/util/peer_channel/peer_channel.dart';
import 'package:anysend/util/time_helper.dart';
import 'package:anysend/util/timeout_window.dart';

class ReceiveChannel extends PeerChannel {
  static const int maxChunkSizeInBytes = 8 * 1024;
  static const int maxBatchSizeInChunks = 16;
  static const int maxBatchSizeInBytes =
      maxChunkSizeInBytes * maxBatchSizeInChunks;
  static const int maxBufferSizeInBatches = 32;
  static const int maxBufferSizeInBytes =
      maxBatchSizeInBytes * maxBufferSizeInBatches;

  final HeapPriorityQueue<FileChunk> _buffer = HeapPriorityQueue((a, b) =>
      a.fileId == b.fileId ? a.offset - b.offset : a.fileId - b.fileId);

  final TimeoutWindow _timeoutWindow = TimeoutWindow();
  double get speedInBytes => _timeoutWindow.mean();

  final List<JobFile> _files = [];
  List<JobFile> get files => _files;

  double get totalFileSize =>
      _files.fold(0, (previousValue, file) => previousValue + file.info.size);
  int get receivedFileCount => _files.fold(
      0,
      (previousValue, file) =>
          previousValue + (file.writeOffset == file.info.size ? 1 : 0));
  double get receivedFileSize =>
      _files.fold(0, (previousValue, file) => previousValue + file.writeOffset);
  double get receiveProgress =>
      totalFileSize == 0 ? 0 : receivedFileSize / totalFileSize;
  String get remainingTime => speedInBytes == 0
      ? "∞"
      : ((totalFileSize - receivedFileSize) ~/ speedInBytes).readableDuration();

  String? outputDirectory;
  void Function(bool)? onAcceptOrDeny;

  @override
  Future<void> connect({
    String? peerId,
    Function? onSignalError,
    void Function()? onSignalDone,
    bool? cancelOnSignalError,
    void Function(bool)? onFailure,
    void Function()? onClosed,
    void Function()? onDone,
    void Function()? onCancel,
    void Function(bool)? onAcceptOrDeny,
  }) async {
    await super.connect(
      peerId: peerId,
      onSignalError: onSignalError,
      onSignalDone: onSignalDone,
      cancelOnSignalError: cancelOnSignalError,
      onFailure: onFailure,
      onClosed: onClosed,
      onDone: onDone,
      onCancel: onCancel,
    );
    this.onAcceptOrDeny = onAcceptOrDeny;
  }

  @override
  Future<void> close() async {
    onAcceptOrDeny = null;
    await super.close();
    for (JobFile file in _files) {
      await file.closeWrite();
    }
    _buffer.clear();
  }

  @override
  void handleSignal(Signal signal) {
    if (signal.sender != peerId) {
      return;
    }

    switch (signal.type) {
      case SignalTypes.iceCandidate:
      case SignalTypes.sdp:
      case SignalTypes.done:
      case SignalTypes.cancel:
        super.handleSignal(signal);
      case SignalTypes.accept:
      case SignalTypes.deny:
        onAcceptOrDeny?.call(signal.type == SignalTypes.accept);
      default:
    }
  }

  Future<void> askToReceive(
    String name, {
    void Function()? onDataChannelClosed,
  }) async {
    await createRtcPeerConnection();
    onDataChannel(
      onDataChannelOpen: _onDataChannelOpen,
      onDataChannelClosed: onDataChannelClosed,
      onDataChannelBinaryMessage: _onDataChannelBinaryMessage,
      onDataChannelTextMessage: _onDataChannelTextMessage,
    );
    sendSignal(
      type: SignalTypes.askToReceive,
      message: name,
    );
  }

  Future<void> _onDataChannelOpen() async {
    await _sendListFiles(0);
  }

  void _onDataChannelBinaryMessage(Uint8List bytes) {
    if (bytes.length <= 16) {
      return;
    }

    ByteData prefix =
        Uint8List.fromList(bytes.sublist(0, 16).toList()).buffer.asByteData();
    int fileId = prefix.getInt64(0);
    int start = prefix.getInt64(8);
    if (fileId < 0 ||
        fileId >= _files.length ||
        start < 0 ||
        start >= _files[fileId].info.size) {
      return;
    }

    Uint8List data = bytes.sublist(16);
    _timeoutWindow.add(data.lengthInBytes.toDouble());
    _write(FileChunk(fileId: fileId, offset: start, data: data));
  }

  Future<void> _write(FileChunk fileChunk) async {
    _buffer.add(fileChunk);

    while (_buffer.isNotEmpty) {
      FileChunk chunk = _buffer.first;
      JobFile file = _files[chunk.fileId];
      if (chunk.offset > file.writeOffset) {
        break;
      } else if (chunk.offset == file.writeOffset) {
        file.write(_buffer.removeFirst().data);

        if (file.requestedOffset < file.info.size &&
            file.writeOffset % maxBatchSizeInBytes == 0) {
          int start = file.requestedOffset;
          file.requestedOffset =
              min(file.info.size, file.requestedOffset + maxBatchSizeInBytes);
          await _sendGetChunk(chunk.fileId, start, file.requestedOffset);
        } else if (file.writeOffset == file.info.size) {
          await file.closeWrite();
          int nextFileId = chunk.fileId + 1;
          if (nextFileId < _files.length) {
            JobFile nextFile = _files[nextFileId];
            nextFile.openWrite();
            nextFile.requestedOffset =
                min(nextFile.info.size, maxBufferSizeInBytes);
            await _sendGetChunk(nextFileId, 0, nextFile.requestedOffset);
          } else {
            sendSignal(type: SignalTypes.done);
            onDone?.call();
          }
        }
      } else {
        _buffer.removeFirst(); // duplicate chunk
      }
    }
  }

  Future<void> _sendGetChunk(int fileId, int start, int end) async {
    GetChunkRequest req = GetChunkRequest(
      fileId: fileId,
      start: start,
      end: end,
      chunkSize: maxChunkSizeInBytes,
    );
    DataSignal dataSignal = DataSignal(
      type: DataSignalTypes.getChunk,
      message: jsonEncode(req.toJson()),
    );
    await sendTextData(jsonEncode(dataSignal.toJson()));
  }

  Future<void> _onDataChannelTextMessage(String message) async {
    DataSignal dataSignal = DataSignal.fromJson(jsonDecode(message));
    switch (dataSignal.type) {
      case DataSignalTypes.listFiles:
        ListFilesResponse resp =
            ListFilesResponse.fromJson(jsonDecode(dataSignal.message));
        await _handleFilesList(resp);
      default:
    }
  }

  Future<void> _handleFilesList(ListFilesResponse resp) async {
    for (FileInfo file in resp.files) {
      _files.add(JobFile(
        info: FileInfo(
          name: file.name,
          size: file.size,
          path: path.join(outputDirectory!, file.name),
        ),
      ));
    }

    if (resp.nextPage >= 0) {
      await _sendListFiles(resp.nextPage);
    } else {
      if (_files.isNotEmpty) {
        JobFile file = _files[0];
        file.openWrite();
        file.requestedOffset = min(file.info.size, maxBufferSizeInBytes);
        await _sendGetChunk(0, 0, file.requestedOffset);
      }
    }
  }

  Future<void> _sendListFiles(int page) async {
    ListFilesRequest req = ListFilesRequest(page: page);
    DataSignal dataSignal = DataSignal(
      type: DataSignalTypes.listFiles,
      message: jsonEncode(req.toJson()),
    );
    await sendTextData(jsonEncode(dataSignal.toJson()));
  }
}

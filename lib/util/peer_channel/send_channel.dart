import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:async/async.dart';

import 'package:anysend/model/data_signal.dart';
import 'package:anysend/model/file.dart';
import 'package:anysend/model/signal.dart';
import 'package:anysend/util/peer_channel/peer_channel.dart';

class SendChannel extends PeerChannel {
  static const int maxChunkSizeInBytes = 16 * 1024 - 16;
  static const int pageSizeInFiles = 100;

  final List<JobFile> _files = [];
  List<JobFile> get files => _files;

  double get totalFileSize =>
      _files.fold(0, (previousValue, file) => previousValue + file.info.size);
  int get sentFileCount => _files.fold(
      0,
      (previousValue, file) =>
          previousValue + (file.readSizeInBytes >= file.info.size ? 1 : 0));
  double get sentFileSize => _files.fold(
      0, (previousValue, file) => previousValue + file.readSizeInBytes);
  double get sentProgress =>
      totalFileSize == 0 ? 0 : sentFileSize / totalFileSize;

  void Function(String, String)? onAskToReceive;

  @override
  Future<void> connect({
    String? peerId,
    Function? onSignalError,
    void Function()? onSignalDone,
    bool? cancelOnSignalError,
    void Function()? onFailure,
    void Function()? onClosed,
    void Function()? onDone,
    void Function()? onCancel,
    void Function(String, String)? onAskToReceive,
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
    this.onAskToReceive = onAskToReceive;
  }

  @override
  Future<void> close() async {
    onAskToReceive = null;
    await super.close();
  }

  @override
  void handleSignal(Signal signal) {
    if (signal.sender != peerId && signal.type != SignalTypes.askToReceive) {
      return;
    }

    switch (signal.type) {
      case SignalTypes.iceCandidate:
      case SignalTypes.sdp:
      case SignalTypes.done:
      case SignalTypes.cancel:
        super.handleSignal(signal);
      case SignalTypes.askToReceive:
        onAskToReceive?.call(signal.sender, signal.message);
      default:
    }
  }

  Future<void> replyToReceive(
    String peerId,
    bool accept, {
    void Function()? onDataChannelClosed,
  }) async {
    if (accept) {
      this.peerId = peerId;
      sendSignal(
        type: SignalTypes.accept,
        peerId: peerId,
      );
      await createRtcPeerConnection();
      await createDataChannel(
        "data",
        ordered: true,
        onDataChannelClosed: onDataChannelClosed,
        onDataChannelTextMessage: _onDataChannelTextMessage,
      );
      await sendSdpOffer();
    } else {
      sendSignal(
        type: SignalTypes.deny,
        peerId: peerId,
      );
    }
  }

  Future<void> _onDataChannelTextMessage(String message) async {
    DataSignal dataSignal = DataSignal.fromJson(jsonDecode(message));
    switch (dataSignal.type) {
      case DataSignalTypes.listFiles:
        ListFilesRequest req =
            ListFilesRequest.fromJson(jsonDecode(dataSignal.message));
        await _sendFilesList(req);
      case DataSignalTypes.getChunk:
        GetChunkRequest req =
            GetChunkRequest.fromJson(jsonDecode(dataSignal.message));
        await _sendChunk(req);
      default:
    }
  }

  Future<void> _sendFilesList(ListFilesRequest req) async {
    if (req.page < 0 || req.page >= _files.length) {
      return;
    }

    int end = min(_files.length, req.page + pageSizeInFiles);
    List<FileInfo> files =
        _files.sublist(req.page, end).map((file) => file.info).toList();
    ListFilesResponse resp = ListFilesResponse(
      files: files,
      nextPage: end == _files.length ? -1 : end,
    );
    DataSignal dataSignal = DataSignal(
      type: DataSignalTypes.listFiles,
      message: jsonEncode(resp.toJson()),
    );
    await sendTextData(jsonEncode(dataSignal.toJson()));
  }

  Future<void> _sendChunk(GetChunkRequest req) async {
    if (req.fileId < 0 || req.fileId >= _files.length) {
      return;
    }

    JobFile file = _files[req.fileId];
    if (req.start < 0 ||
        req.start >= file.info.size ||
        req.end <= 0 ||
        req.end > file.info.size ||
        req.chunkSize <= 0 ||
        req.chunkSize > maxChunkSizeInBytes) {
      return;
    }

    ChunkedStreamReader<int> reader = ChunkedStreamReader(
        (File(file.info.path!).openRead(req.start, req.end)));
    try {
      int offset = req.start;
      while (true) {
        List<int> chunk = await reader.readChunk(req.chunkSize);
        if (chunk.isEmpty) {
          break;
        }

        Uint8List bytes = Uint8List(16 + chunk.length);
        ByteData prefix = bytes.buffer.asByteData(0, 16);
        prefix.setInt64(0, req.fileId);
        prefix.setInt64(8, offset);
        bytes.setRange(16, bytes.length, chunk);
        await sendBinaryData(bytes);
        offset += chunk.length;
      }
      file.readSizeInBytes += req.end - req.start;
    } finally {
      await reader.cancel();
    }
  }
}

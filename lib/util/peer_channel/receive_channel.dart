import 'dart:typed_data';

import 'package:anysend/model/signal.dart';
import 'package:anysend/util/peer_channel/peer_channel.dart';

class ReceiveChannel extends PeerChannel {
  void Function(bool)? onAcceptOrDeny;

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
    void Function()? onDataChannelOpen,
    void Function()? onDataChannelClosed,
    void Function(Uint8List)? onDataChannelBinaryMessage,
    void Function(String)? onDataChannelTextMessage,
  }) async {
    await createRtcPeerConnection();
    onDataChannel(
      onDataChannelOpen: onDataChannelOpen,
      onDataChannelClosed: onDataChannelClosed,
      onDataChannelBinaryMessage: onDataChannelBinaryMessage,
      onDataChannelTextMessage: onDataChannelTextMessage,
    );
    sendSignal(
      type: SignalTypes.askToReceive,
      message: name,
    );
  }
}

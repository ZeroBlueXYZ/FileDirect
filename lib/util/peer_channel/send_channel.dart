import 'dart:typed_data';

import 'package:anysend/model/signal.dart';
import 'package:anysend/util/peer_channel/peer_channel.dart';

class SendChannel extends PeerChannel {
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
    void Function()? onDataChannelOpen,
    void Function()? onDataChannelClosed,
    void Function(Uint8List)? onDataChannelBinaryMessage,
    void Function(String)? onDataChannelTextMessage,
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
        onDataChannelOpen: onDataChannelOpen,
        onDataChannelClosed: onDataChannelClosed,
        onDataChannelBinaryMessage: onDataChannelBinaryMessage,
        onDataChannelTextMessage: onDataChannelTextMessage,
      );
      await sendSdpOffer();
    } else {
      sendSignal(
        type: SignalTypes.deny,
        peerId: peerId,
      );
    }
  }
}

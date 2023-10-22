import "dart:async";
import "dart:convert";
import "dart:typed_data";

import "package:flutter_webrtc/flutter_webrtc.dart";

import "package:anysend/model/signal.dart";
import "package:anysend/repository/signaling.dart";

abstract class PeerChannel {
  static const String nullUuid = "00000000-0000-0000-0000-000000000000";
  static const Map<String, dynamic> configuration = {
    "iceServers": [
      {
        "url": "stun:stun.l.google.com:19302",
      },
      {
        "url": "stun:stun.ekiga.net:3478",
      },
      {
        "url": "stun:stun.ideasip.com:3478",
      },
      {
        "url": "stun:stun.iptel.org:3478",
      },
      {
        "url": "stun:stun.rixtelecom.se:3478",
      },
      {
        "url": "stun:stun.schlund.de:3478",
      },
      {
        "url": "stun:stunserver.org:3478",
      },
      {
        "url": "stun:stun.softjoys.com:3478",
      },
      {
        "url": "stun:stun.voiparound.com:3478",
      },
      {
        "url": "stun:stun.voipbuster.com:3478",
      },
      {
        "url": "stun:stun.voipstunt.com:3478",
      },
    ],
  };

  SignalingRepository? _signalingRepository;
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;

  void Function()? onFailure;
  void Function()? onClosed;
  void Function()? onDone;
  void Function()? onCancel;

  String? peerId;

  Future<void> connect({
    String? peerId,
    Function? onSignalError,
    void Function()? onSignalDone,
    bool? cancelOnSignalError,
    void Function()? onFailure,
    void Function()? onClosed,
    void Function()? onDone,
    void Function()? onCancel,
  }) async {
    if (_signalingRepository != null) {
      throw "already connected to signaling server";
    }
    this.peerId = peerId;
    _signalingRepository = SignalingRepository();
    _signalingRepository!.receive().listen(
          handleSignal,
          onError: onSignalError,
          onDone: onSignalDone,
          cancelOnError: cancelOnSignalError,
        );
    this.onFailure = onFailure;
    this.onClosed = onClosed;
    this.onDone = onDone;
    this.onCancel = onCancel;
  }

  Future<void> close() async {
    onFailure = null;
    onClosed = null;
    onDone = null;
    onCancel = null;
    await closeDataChannel();
    await closeRtcPeerConnection();
    await _signalingRepository?.closeReceive();
    _signalingRepository = null;
    peerId = null;
  }

  void sendSignal({
    required String type,
    String message = "",
    String? peerId,
  }) {
    _signalingRepository!.send(Signal(
      receiver: peerId ?? this.peerId ?? nullUuid,
      sender: nullUuid,
      type: type,
      message: message,
    ));
  }

  void handleSignal(Signal signal) {
    switch (signal.type) {
      case SignalTypes.iceCandidate:
        onIceCandidate(signal.message);
      case SignalTypes.sdp:
        onSdp(signal.message);
      case SignalTypes.done:
        onDone?.call();
      case SignalTypes.cancel:
        onCancel?.call();
      default:
    }
  }

  void sendDoneSignal() {
    sendSignal(type: SignalTypes.done);
  }

  void sendCancelSignal() {
    if (peerId == null) {
      return;
    }
    sendSignal(type: SignalTypes.cancel);
  }

  Future<void> onIceCandidate(String message) async {
    final decoded = jsonDecode(message);
    final iceCandidate = RTCIceCandidate(
      decoded["candidate"],
      decoded["sdpMid"],
      decoded["sdpMLineIndex"],
    );
    await _peerConnection?.addCandidate(iceCandidate);
  }

  Future<void> onSdp(String message) async {
    final decoded = jsonDecode(message);
    final remoteDescription =
        RTCSessionDescription(decoded["sdp"], decoded["type"]);
    await _peerConnection?.setRemoteDescription(remoteDescription);

    if (decoded["type"] == "offer") {
      final localDescription = await _peerConnection!.createAnswer();
      await _peerConnection?.setLocalDescription(localDescription);
      sendSignal(
        type: SignalTypes.sdp,
        message: jsonEncode(localDescription.toMap()),
      );
    }
  }

  Future<void> sendSdpOffer() async {
    final localDescription = await _peerConnection!.createOffer();
    await _peerConnection?.setLocalDescription(localDescription);
    sendSignal(
      type: SignalTypes.sdp,
      message: jsonEncode(localDescription.toMap()),
    );
  }

  Future<void> createRtcPeerConnection() async {
    if (_peerConnection != null) {
      throw "peer connection already exists";
    }

    _peerConnection = await createPeerConnection(configuration);

    _peerConnection!.onIceConnectionState = (state) {
      switch (state) {
        case RTCIceConnectionState.RTCIceConnectionStateFailed:
          onFailure?.call();
        case RTCIceConnectionState.RTCIceConnectionStateClosed:
          onClosed?.call();
        default:
      }
    };

    _peerConnection!.onIceCandidate = (iceCandidate) async {
      sendSignal(
        type: SignalTypes.iceCandidate,
        message: jsonEncode(iceCandidate.toMap()),
      );
    };
  }

  Future<void> closeRtcPeerConnection() async {
    _peerConnection?.close();
    _peerConnection = null;
  }

  Future<void> createDataChannel(
    String label, {
    bool ordered = true,
    void Function()? onDataChannelOpen,
    void Function()? onDataChannelClosed,
    void Function(Uint8List)? onDataChannelBinaryMessage,
    void Function(String)? onDataChannelTextMessage,
  }) async {
    if (_dataChannel != null) {
      throw "data channel already exists";
    }

    _dataChannel = await _peerConnection?.createDataChannel(
      label,
      RTCDataChannelInit()
        ..ordered = ordered
        ..binaryType = "binary",
    );
    _dataChannel!.onDataChannelState = _onDataChannelState(
      onDataChannelOpen: onDataChannelOpen,
      onDataChannelClosed: onDataChannelClosed,
    );
    _dataChannel!.onMessage = _onDataChannelMessage(
      onDataChannelBinaryMessage: onDataChannelBinaryMessage,
      onDataChannelTextMessage: onDataChannelTextMessage,
    );
  }

  Future<void> closeDataChannel() async {
    await _dataChannel?.close();
    _dataChannel = null;
  }

  void onDataChannel({
    void Function()? onDataChannelOpen,
    void Function()? onDataChannelClosed,
    void Function(Uint8List)? onDataChannelBinaryMessage,
    void Function(String)? onDataChannelTextMessage,
  }) {
    _peerConnection!.onDataChannel = (channel) {
      if (_dataChannel != null) {
        throw "data channel already exists";
      }

      _dataChannel = channel;
      _dataChannel!.onDataChannelState = _onDataChannelState(
        onDataChannelOpen: onDataChannelOpen,
        onDataChannelClosed: onDataChannelClosed,
      );
      _dataChannel!.onMessage = _onDataChannelMessage(
        onDataChannelBinaryMessage: onDataChannelBinaryMessage,
        onDataChannelTextMessage: onDataChannelTextMessage,
      );
    };
  }

  void Function(RTCDataChannelState) _onDataChannelState({
    void Function()? onDataChannelOpen,
    void Function()? onDataChannelClosed,
  }) {
    return (RTCDataChannelState state) {
      switch (state) {
        case RTCDataChannelState.RTCDataChannelOpen:
          onDataChannelOpen?.call();
        case RTCDataChannelState.RTCDataChannelClosed:
          _dataChannel = null;
          onDataChannelClosed?.call();
        default:
      }
    };
  }

  void Function(RTCDataChannelMessage) _onDataChannelMessage({
    void Function(Uint8List)? onDataChannelBinaryMessage,
    void Function(String)? onDataChannelTextMessage,
  }) {
    return (RTCDataChannelMessage message) {
      if (message.isBinary) {
        onDataChannelBinaryMessage?.call(message.binary);
      } else {
        onDataChannelTextMessage?.call(message.text);
      }
    };
  }

  Future<void> sendBinaryData(Uint8List data) async {
    await _dataChannel!.send(RTCDataChannelMessage.fromBinary(data));
  }

  Future<void> sendTextData(String data) async {
    await _dataChannel!.send(RTCDataChannelMessage(data));
  }
}

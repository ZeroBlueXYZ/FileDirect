import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:anysend/model/auth_token.dart';
import 'package:anysend/model/signal.dart';
import 'package:anysend/repository/base.dart';
import 'package:anysend/util/global_config.dart';

class SignalingRepository extends BaseRepository {
  late final WebSocketChannel _channel;

  SignalingRepository() {
    _channel = WebSocketChannel.connect(Uri.parse("$baseWsUri/signaling"));
    final wsAuthToken =
        WsAuthToken(accessToken: GlobalConfig().authToken!.accessToken);
    _channel.sink.add(jsonEncode(wsAuthToken.toJson()));
  }

  void receive(
    void Function(Signal)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    _channel.stream.listen(
      (dynamic data) {
        final signal = Signal.fromJson(jsonDecode(data));
        onData?.call(signal);
      },
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  void send(Signal signal) {
    _channel.sink.add(jsonEncode(signal.toJson()));
  }

  Future<dynamic> close() async {
    return await _channel.sink.close();
  }
}

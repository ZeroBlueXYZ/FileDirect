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

  Stream<Signal> receive() async* {
    await for (final data in _channel.stream) {
      yield Signal.fromJson(jsonDecode(data));
    }
  }

  Future<dynamic> closeReceive() async {
    return await _channel.sink.close();
  }

  void send(Signal signal) {
    _channel.sink.add(jsonEncode(signal.toJson()));
  }
}

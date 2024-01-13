import 'dart:convert';
import 'dart:io';

import 'package:http_interceptor/http_interceptor.dart';

import 'package:anysend/model/package.dart';
import 'package:anysend/model/platform_type.dart';
import 'package:anysend/repository/base.dart';
import 'package:anysend/util/global_config.dart';

class PackageRepository extends BaseRepository {
  static const String multicastAddress = "224.0.0.182";
  static const int multicastPort = 28198;

  RawDatagramSocket? _receiveSocket;
  RawDatagramSocket? _sendSocket;

  Future<Package?> get({required String code}) async {
    final resp = await client.get(
      "$baseUri/package".toUri(),
      params: {"code": code},
    );
    if (resp.statusCode == HttpStatus.ok) {
      return Package.fromJson(jsonDecode(resp.body));
    }
    return null;
  }

  Future<Package?> create() async {
    final resp = await client.post("$baseUri/package".toUri());
    if (resp.statusCode == HttpStatus.ok) {
      return Package.fromJson(jsonDecode(resp.body));
    }
    return null;
  }

  Future<void> receive(void Function(NearbyPackage)? onData) async {
    if (_receiveSocket != null) {
      throw "already listening to multicast";
    }

    _receiveSocket =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, multicastPort);
    _receiveSocket!.joinMulticast(InternetAddress(multicastAddress));
    _receiveSocket!.listen((RawSocketEvent event) {
      Datagram? datagram = _receiveSocket?.receive();
      if (datagram != null) {
        NearbyPackage package =
            NearbyPackage.fromJson(jsonDecode(utf8.decode(datagram.data)));
        if (package.ownerId != GlobalConfig().multicastId) {
          onData?.call(package);
        }
      }
    });
  }

  void closeReceive() {
    _receiveSocket?.leaveMulticast(InternetAddress(multicastAddress));
    _receiveSocket?.close();
  }

  void send({required String code, required DateTime expireTime}) async {
    _sendSocket ??= await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    NearbyPackage package = NearbyPackage(
      code: code,
      ownerId: GlobalConfig().multicastId,
      expireTime: expireTime,
      platform: PlatformType.platform,
      ownerName: GlobalConfig().deviceName,
    );
    _sendSocket?.send(
      utf8.encode(jsonEncode(package.toJson())),
      InternetAddress(multicastAddress),
      multicastPort,
    );
  }

  void closeSend() {
    _sendSocket?.close();
  }
}

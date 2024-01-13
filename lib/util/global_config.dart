import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:anysend/model/auth_token.dart';
import 'package:anysend/util/string_helper.dart';

const String _copyright = 'Copyright © 2023-2024 Zhaoming Zhang';

class GlobalConfig {
  factory GlobalConfig() => _instance;
  static final GlobalConfig _instance = GlobalConfig._internal();
  GlobalConfig._internal();

  static const AssetImage appIcon = AssetImage("assets/icon/icon.png");

  final String serverUri = "https://anysend-api.zeroblue.xyz";
  final String multicastId = randomString(36);
  final String receiverId =
      "#${Random().nextInt(999).toString().padLeft(3, "0")}";
  late final String appName;
  late final String packageName;
  late final String version;
  late final String deviceName;
  AuthToken? authToken;

  String get copyright => _copyright;

  Future<void> ensureInit() async {
    await initPackageInfo();
    await initDeviceInfo();
  }

  Future<void> initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    appName = info.appName;
    packageName = info.packageName;
    version = info.version;
  }

  Future<void> initDeviceInfo() async {
    if (Platform.isAndroid) {
      deviceName = (await DeviceInfoPlugin().androidInfo).model;
    } else if (Platform.isIOS) {
      deviceName = (await DeviceInfoPlugin().iosInfo).name;
    } else if (Platform.isMacOS) {
      deviceName = (await DeviceInfoPlugin().macOsInfo).computerName;
    } else if (Platform.isWindows) {
      deviceName = (await DeviceInfoPlugin().windowsInfo).computerName;
    } else {
      throw "Unsupported Platform";
    }
  }
}

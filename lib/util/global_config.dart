import 'package:flutter/material.dart';

import 'package:package_info_plus/package_info_plus.dart';

import 'package:anysend/model/auth_token.dart';
import 'package:anysend/util/string_helper.dart';

const String _copyright = 'Copyright © 2023 Zhaoming Zhang';

class GlobalConfig {
  factory GlobalConfig() => _instance;
  static final GlobalConfig _instance = GlobalConfig._internal();
  GlobalConfig._internal();

  static const AssetImage appIcon = AssetImage("assets/icon/icon.png");

  final String multicastId = randomString(36);
  late final String serverUri;
  late final String appName;
  late final String packageName;
  late final String version;
  AuthToken? authToken;

  String get copyright => _copyright;

  Future<void> ensureInit() async {
    initServerUri();
    await initPackageInfo();
  }

  void initServerUri() {
    if (WidgetsBinding.instance.platformDispatcher.locale.countryCode == "CN" &&
        DateTime.now().timeZoneOffset.inHours == 8) {
      serverUri = "https://anysend-api-cn.zeroblue.xyz";
    } else {
      serverUri = "https://anysend-api.zeroblue.xyz";
    }
  }

  Future<void> initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    appName = info.appName;
    packageName = info.packageName;
    version = info.version;
  }
}

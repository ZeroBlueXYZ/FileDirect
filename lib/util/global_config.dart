import 'package:flutter/material.dart';

import 'package:anysend/model/auth_token.dart';
import 'package:anysend/util/string_helper.dart';

class GlobalConfig {
  factory GlobalConfig() => _instance;
  static final GlobalConfig _instance = GlobalConfig._internal();
  GlobalConfig._internal();

  final String multicastId = randomString(36);
  late final String serverUri;
  AuthToken? authToken;

  void ensureInit() {
    serverUri = isCn()
        ? "https://anysend-api-cn.zeroblue.xyz"
        : "https://anysend-api.zeroblue.xyz";
  }

  bool isCn() {
    return WidgetsBinding.instance.platformDispatcher.locale.countryCode ==
            "CN" &&
        DateTime.now().timeZoneOffset.inHours == 8;
  }
}

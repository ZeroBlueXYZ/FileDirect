import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:package_info_plus/package_info_plus.dart';

import 'package:anysend/model/auth_token.dart';
import 'package:anysend/util/string_helper.dart';

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

  Future<void> ensureInit() async {
    initServerUri();
    await initPackageInfo();
    addLicense();
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

  void addLicense() {
    LicenseRegistry.addLicense(
      () => Stream<LicenseEntry>.value(
        LicenseEntryWithLineBreaks(
          [appName],
          _license,
        ),
      ),
    );
  }
}

const String _license = '''Copyright 2023 Zhaoming Zhang

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.''';

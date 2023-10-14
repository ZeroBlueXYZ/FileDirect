import 'dart:io';

import 'package:flutter/foundation.dart';

class PlatformType {
  static const String android = "ANDROID";
  static const String ios = "IOS";
  static const String linux = "LINUX";
  static const String macos = "MACOS";
  static const String windows = "WINDOWS";
  static const String web = "WEB";

  static String get platform {
    if (kIsWeb) {
      return web;
    } else if (Platform.isAndroid) {
      return android;
    } else if (Platform.isIOS) {
      return ios;
    } else if (Platform.isLinux) {
      return linux;
    } else if (Platform.isWindows) {
      return windows;
    } else {
      return web;
    }
  }
}

import 'package:flutter/material.dart';

import 'package:anysend/app.dart';
import 'package:anysend/util/global_config.dart';

void main() {
  GlobalConfig().ensureInit(serverUri: "https://anysend-api.zeroblue.xyz");
  runApp(const App());
}

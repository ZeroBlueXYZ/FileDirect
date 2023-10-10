import 'package:flutter/material.dart';

import 'package:anysend/app.dart';
import 'package:anysend/util/global_config.dart';

void main() {
  GlobalConfig().ensureInit(serverUri: "http://127.0.0.1:8080");
  runApp(const App());
}

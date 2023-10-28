import 'package:flutter/material.dart';

import 'package:anysend/app.dart';
import 'package:anysend/util/global_config.dart';
import 'package:anysend/util/shared_prefs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPrefs().ensureInit();
  GlobalConfig().ensureInit(serverUri: "https://anysend-api.zeroblue.xyz");

  runApp(const App());
}

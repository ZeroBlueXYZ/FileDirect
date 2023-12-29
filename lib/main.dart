import 'package:flutter/material.dart';

import 'package:anysend/app.dart';
import 'package:anysend/util/global_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfig().ensureInit();

  runApp(const App());
}

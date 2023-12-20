import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<Directory?> getOutputDirectory() async {
  Directory? directory;
  if (Platform.isAndroid) {
    directory = Directory('/storage/emulated/0/Download');
  } else if (Platform.isIOS) {
    directory = await getApplicationDocumentsDirectory();
  } else {
    directory = await getDownloadsDirectory();
  }

  if (directory != null && !directory.existsSync()) {
    try {
      directory.createSync();
    } catch (_) {
      return null;
    }
  }
  return directory;
}

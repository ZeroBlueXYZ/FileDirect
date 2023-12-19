import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_storage/shared_storage.dart' as saf;

import 'package:anysend/repository/custom_config.dart';

Future<void> requestStoragePermission({
  void Function()? onSuccess,
  void Function()? onFailure,
}) async {
  if (Platform.isAndroid) {
    Uri? savedDirectoryUri = getOutputDirectoryFromConfig();
    if (savedDirectoryUri != null) {
      final bool? canWrite = await saf.canWrite(savedDirectoryUri);
      if (canWrite != null && canWrite) {
        onSuccess?.call();
        return;
      }
    }
    final uri = await saf.openDocumentTree(
      grantWritePermission: true,
      persistablePermission: true,
    );
    if (uri != null) {
      await CustomConfigRepository().setOutputDirectory(uri.toString());
      onSuccess?.call();
    } else {
      onFailure?.call();
    }
  } else {
    onSuccess?.call();
  }
}

Uri? getOutputDirectoryFromConfig() {
  String? uriString = CustomConfigRepository().outputDirectory;
  if (uriString != null) {
    return Uri.tryParse(uriString);
  }
  return null;
}

Future<Uri?> getOutputDirectory() async {
  if (Platform.isAndroid) {
    return getOutputDirectoryFromConfig();
  } else if (Platform.isIOS) {
    return _getIosOutputDirectory();
  } else {
    final Directory? directory = await getDownloadsDirectory();
    if (directory == null) {
      return null;
    }
    return Uri.directory(directory.path, windows: Platform.isWindows);
  }
}

Future<Uri?> _getIosOutputDirectory() async {
  final Directory directory = await getApplicationDocumentsDirectory();
  if (!directory.existsSync()) {
    try {
      directory.createSync();
    } catch (_) {
      return null;
    }
  }

  return Uri.directory(directory.path);
}

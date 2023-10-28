import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_storage/shared_storage.dart' as saf;

import 'package:anysend/repository/custom_config.dart';

Future<void> needStoragePermission({
  void Function()? onYes,
  void Function()? onNo,
}) async {
  if (Platform.isAndroid) {
    Uri? savedDirectoryUri = _savedDirectory();
    if (savedDirectoryUri != null) {
      final bool? canWrite = await saf.canWrite(savedDirectoryUri);
      if (canWrite != null && canWrite) {
        onNo?.call();
        return;
      }
    }
    onYes?.call();
  } else {
    onNo?.call();
  }
}

Future<Uri?> getOutputDirectory() async {
  if (Platform.isAndroid) {
    return await _getAndroidOutputDirectory();
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

Future<Uri?> _getAndroidOutputDirectory() async {
  Uri? savedDirectoryUri = _savedDirectory();
  if (savedDirectoryUri != null) {
    final bool? canWrite = await saf.canWrite(savedDirectoryUri);
    if (canWrite != null && canWrite) {
      return savedDirectoryUri;
    }
  }

  final uri = await saf.openDocumentTree(
    grantWritePermission: true,
    persistablePermission: true,
  );
  if (uri != null) {
    await CustomConfigRepository().setOutputDirectory(uri.toString());
  }

  return uri;
}

Uri? _savedDirectory() {
  String? uriString = CustomConfigRepository().outputDirectory;
  if (uriString != null) {
    return Uri.tryParse(uriString);
  }
  return null;
}

Future<Uri?> _getIosOutputDirectory() async {
  final Directory? directory = await getDownloadsDirectory();
  if (directory == null) {
    return null;
  }

  if (!directory.existsSync()) {
    try {
      directory.createSync();
    } catch (_) {
      return null;
    }
  }

  return Uri.directory(directory.path);
}

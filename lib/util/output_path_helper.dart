import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_storage/shared_storage.dart' as saf;

const String kAppFolder = "AnySend";
const String kAndroidDocumentsDirectoryUri =
    "content://com.android.externalstorage.documents/tree/primary%3ADocuments";

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
  Uri downloadDirectoryUri = Uri.parse(kAndroidDocumentsDirectoryUri);
  final bool? canWrite = await saf.canWrite(downloadDirectoryUri);
  if (canWrite == null || !canWrite) {
    final uri = await saf.openDocumentTree(
      grantWritePermission: true,
      persistablePermission: true,
      initialUri: Uri.parse(kAndroidDocumentsDirectoryUri),
    );
    if (uri == null || uri != downloadDirectoryUri) {
      return null;
    }
  }

  saf.DocumentFile? appFolder =
      await saf.child(downloadDirectoryUri, kAppFolder);
  if (appFolder == null) {
    appFolder = await saf.createDirectory(downloadDirectoryUri, kAppFolder);
    if (appFolder == null) {
      return null;
    }
  }

  return appFolder.uri;
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

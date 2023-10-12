extension ReadableFileSize on num {
  String readableFileSize({bool base1000 = false}) {
    num divider = base1000 ? 1000 : 1024;
    if (this < divider) {
      return '${toStringAsFixed(0)} B';
    } else if (this < divider * divider) {
      return '${(this / divider).toStringAsFixed(0)} KB';
    } else if (this < divider * divider * divider) {
      return '${(this / (divider * divider)).toStringAsFixed(1)} MB';
    } else if (this < divider * divider * divider * divider) {
      return '${(this / (divider * divider * divider)).toStringAsFixed(1)} GB';
    } else {
      return '${(this / (divider * divider * divider * divider)).toStringAsFixed(1)} TB';
    }
  }
}

extension FileExtension on String? {
  static const List<String> _imageExtensions = [
    "apng",
    "bmp",
    "gif",
    "jpg",
    "jpeg",
    "png",
    "svg",
    "tif",
    "tiff",
    "webp",
  ];

  static const List<String> _videoExtensions = [
    "avi",
    "mkv",
    "mp4",
    "mov",
    "webm",
    "wmv",
  ];

  bool isImage() {
    return this != null &&
        _imageExtensions.any((name) => this!.endsWith(".$name"));
  }

  bool isVideo() {
    return this != null &&
        _videoExtensions.any((name) => this!.endsWith(".$name"));
  }
}

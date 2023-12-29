import 'dart:io';

import 'package:flutter/material.dart';

import 'package:anysend/model/file.dart';
import 'package:anysend/util/file_helper.dart';

class FileCard extends StatelessWidget {
  static const double leadingIconSize = 28;

  final FileInfo fileInfo;
  final Widget? trailing;
  final LinearProgressIndicator? linearProgressIndicator;
  final bool showPreview;

  const FileCard({
    super.key,
    required this.fileInfo,
    this.trailing,
    this.linearProgressIndicator,
    this.showPreview = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      child: Column(children: [
        ListTile(
          leading: _leading(),
          title: Text(
            fileInfo.name,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          subtitle: Text(fileInfo.size.readableFileSize()),
          trailing: trailing,
        ),
        if (linearProgressIndicator != null) linearProgressIndicator!,
      ]),
    );
  }

  Widget _leading() {
    final IconData iconData = () {
      switch (fileInfo.type) {
        case FileInfoType.message:
          return Icons.message;
        case FileInfoType.image:
          return Icons.image;
        case FileInfoType.video:
          return Icons.video_file;
        default:
          return Icons.description;
      }
    }();
    final Icon icon = Icon(iconData, size: leadingIconSize);

    if (showPreview && fileInfo.type == FileInfoType.image) {
      return Image.file(
        File(fileInfo.path!),
        errorBuilder: (context, error, stackTrace) => icon,
        width: leadingIconSize,
      );
    } else {
      return icon;
    }
  }
}

import 'dart:io';

import 'package:flutter/material.dart';

import 'package:anysend/model/file.dart';
import 'package:anysend/util/file_helper.dart';

class FileCard extends StatelessWidget {
  final FileInfo fileInfo;
  final IconData? trailingIcon;
  final void Function()? onTrailingIconPressed;
  final LinearProgressIndicator? linearProgressIndicator;

  const FileCard({
    super.key,
    required this.fileInfo,
    this.trailingIcon,
    this.onTrailingIconPressed,
    this.linearProgressIndicator,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      child: Column(children: [
        ListTile(
          leading: _leading(),
          title: Text(fileInfo.name, overflow: TextOverflow.ellipsis),
          subtitle: Text(fileInfo.size.readableFileSize()),
          trailing: trailingIcon != null
              ? IconButton(
                  icon: Icon(trailingIcon),
                  onPressed: onTrailingIconPressed,
                )
              : null,
        ),
        if (linearProgressIndicator != null) linearProgressIndicator!,
      ]),
    );
  }

  Widget _leading() {
    if (fileInfo.name.isImage()) {
      return Image.file(
        File(fileInfo.path!),
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
      );
    } else if (fileInfo.name.isVideo()) {
      return const Icon(Icons.video_file);
    } else {
      return const Icon(Icons.description);
    }
  }
}

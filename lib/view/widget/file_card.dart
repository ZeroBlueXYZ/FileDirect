import 'dart:io';

import 'package:flutter/material.dart';

import 'package:anysend/model/file.dart';
import 'package:anysend/util/file_helper.dart';
import 'package:anysend/view/screen/image.dart';

class FileCard extends StatefulWidget {
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
  State<FileCard> createState() => _FileCardState();
}

class _FileCardState extends State<FileCard> {
  static const double leadingIconSize = 28;
  bool _errorLoadingImage = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      child: Column(children: [
        ListTile(
          leading: _leading(),
          title: Text(
            widget.fileInfo.name,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          subtitle: Text(widget.fileInfo.size.readableFileSize()),
          trailing: widget.trailing,
        ),
        if (widget.linearProgressIndicator != null)
          widget.linearProgressIndicator!,
      ]),
    );
  }

  Widget _leading() {
    final IconData iconData = () {
      switch (widget.fileInfo.type) {
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
    final bool previewImage =
        widget.showPreview && widget.fileInfo.type == FileInfoType.image;
    return IconButton(
      icon: previewImage
          ? Image.file(
              File(widget.fileInfo.path!),
              width: leadingIconSize,
              errorBuilder: (context, error, stackTrace) {
                WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                  setState(() {
                    _errorLoadingImage = true;
                  });
                });
                return icon;
              },
            )
          : icon,
      onPressed: previewImage && !_errorLoadingImage
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImageScreen(path: widget.fileInfo.path),
                ),
              );
            }
          : null,
      disabledColor: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}

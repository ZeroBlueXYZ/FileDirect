import 'dart:io';

import 'package:flutter/material.dart';

class ImageScreen extends StatefulWidget {
  final String? path;

  const ImageScreen({super.key, this.path});

  @override
  State<ImageScreen> createState() => _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen> {
  static const double iconSize = 100;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Image.file(
          File(widget.path!),
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.error,
            size: iconSize,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
    );
  }
}

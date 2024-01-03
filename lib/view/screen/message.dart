import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:path/path.dart' as path;

import 'package:anysend/model/file.dart';
import 'package:anysend/util/output_path_helper.dart';
import 'package:anysend/view/widget/warning.dart';

class MessageScreen extends StatefulWidget {
  final bool readOnly;
  final String? initialText;

  const MessageScreen({
    super.key,
    required this.readOnly,
    this.initialText,
  });

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  static const int leadingNameLength = 8;

  final GlobalKey<FormState> _messageFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _saveAsFormKey = GlobalKey<FormState>();
  late final TextEditingController _messageTextEditingController;
  late final TextEditingController _saveAsFilenameTextEditingController;

  bool get _isMessageEmpty => _messageTextEditingController.text.trim().isEmpty;

  @override
  void initState() {
    super.initState();
    _messageTextEditingController =
        TextEditingController(text: widget.initialText)
          ..addListener(() {
            setState(() {});
          });
    _saveAsFilenameTextEditingController = TextEditingController()
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _messageTextEditingController.dispose();
    _saveAsFilenameTextEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: SafeArea(
        child: _textForm(),
      ),
    );
  }

  AppBar _appBar() {
    return AppBar(
      title: Text(AppLocalizations.of(context)!.textMessage),
      centerTitle: true,
      actions: widget.readOnly
          ? [
              IconButton(
                onPressed: () {
                  showDialog(
                      context: context, builder: (context) => _saveAsDialog());
                },
                icon: const Icon(Icons.save),
                tooltip: AppLocalizations.of(context)!.textSaveAs,
              ),
              IconButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(
                          text: _messageTextEditingController.text))
                      .then((_) {
                    if (!Platform.isAndroid) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(copiedToClipboardSnackBar(context));
                    }
                  });
                },
                icon: const Icon(Icons.copy),
                tooltip: AppLocalizations.of(context)!.textCopy,
              ),
            ]
          : [
              IconButton(
                onPressed: _isMessageEmpty
                    ? null
                    : () {
                        Navigator.pop<FileInfo>(
                          context,
                          FileInfo(
                            name: _messageTextEditingController.text.substring(
                                0,
                                min(leadingNameLength,
                                    _messageTextEditingController.text.length)),
                            size: _messageTextEditingController.text.length,
                            textData: _messageTextEditingController.text,
                          ),
                        );
                      },
                icon: const Icon(Icons.done),
                tooltip: AppLocalizations.of(context)!.textDone,
              ),
            ],
    );
  }

  Widget _textForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _messageFormKey,
        child: TextFormField(
          controller: _messageTextEditingController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          minLines: 10,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          readOnly: widget.readOnly,
          autofocus: true,
        ),
      ),
    );
  }

  AlertDialog _saveAsDialog() {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.textSaveAs),
      content: Form(
        key: _saveAsFormKey,
        child: TextFormField(
          controller: _saveAsFilenameTextEditingController,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: AppLocalizations.of(context)!.textEnterFilename,
            errorStyle: const TextStyle(fontSize: 0),
          ),
          validator: (value) =>
              value != null && value.trim().isNotEmpty ? null : "",
          autofocus: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            AppLocalizations.of(context)!.textCancel,
            textAlign: TextAlign.center,
          ),
        ),
        TextButton(
          onPressed: () async {
            if (_saveAsFormKey.currentState != null &&
                _saveAsFormKey.currentState!.validate()) {
              getOutputDirectory().then((directory) {
                if (directory == null) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(unknownErrorSnackBar(context));
                  Navigator.pop(context);
                } else {
                  File(path.join(directory.path,
                          _saveAsFilenameTextEditingController.text))
                      .writeAsString(_messageTextEditingController.text)
                      .then((value) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(savedToFileSnackBar(context));
                    Navigator.pop(context);
                  }).catchError((e) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(unknownErrorSnackBar(context));
                    Navigator.pop(context);
                  });
                }
              });
            }
          },
          child: Text(
            AppLocalizations.of(context)!.textSave,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

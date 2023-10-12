import 'dart:io';

import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_timer_countdown/flutter_timer_countdown.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

import 'package:anysend/model/file.dart';
import 'package:anysend/model/job_state.dart';
import 'package:anysend/model/package.dart';
import 'package:anysend/repository/package.dart';
import 'package:anysend/util/file_helper.dart';
import 'package:anysend/view/widget/action_card.dart';
import 'package:anysend/view/widget/file_card.dart';
import 'package:anysend/view/widget/warning.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final PackageRepository _packageRepo = PackageRepository();

  final List<JobFile> _files = [];

  Package? _package;

  int get _totalFileSize =>
      _files.fold(0, (previousValue, file) => previousValue + file.info.size);

  void _pickFiles({FileType type = FileType.any}) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: type,
      allowMultiple: true,
    );
    if (result != null) {
      for (final file in result.files) {
        _files.add(JobFile(
          info: FileInfo(
            name: file.name,
            size: file.size,
            path: file.path,
          ),
        ));
      }
      setState(() {});
    }
  }

  void _pickDirectory() async {
    String? dirPath = await FilePicker.platform.getDirectoryPath();
    if (dirPath != null) {
      List<FileSystemEntity> entities =
          Directory(dirPath).listSync(recursive: true, followLinks: false);
      for (final entity in entities) {
        if (entity is File && !path.basename(entity.path).startsWith(".")) {
          _files.add(JobFile(
            info: FileInfo(
                name: path.basename(entity.path),
                size: entity.lengthSync(),
                path: entity.path),
          ));
        }
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Consumer<JobStateModel>(
        builder: (context, state, child) => Column(
          children: [
            if (!state.isSend) _pickButtons(),
            if (!state.isSend && _files.isNotEmpty) _deleteAllTile(),
            Expanded(child: _fileList()),
            if (_files.isNotEmpty) _actionCard(),
          ],
        ),
      ),
    );
  }

  Widget _pickButtons() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _pickButton(
            icon: Icons.description,
            label: AppLocalizations.of(context)!.textFile,
            onPressed: () => _pickFiles(type: FileType.any),
          ),
          if (Platform.isLinux || Platform.isMacOS || Platform.isWindows)
            _pickButton(
              icon: Icons.folder,
              label: AppLocalizations.of(context)!.textFolder,
              onPressed: () => _pickDirectory(),
            ),
          if (Platform.isAndroid || Platform.isIOS)
            _pickButton(
              icon: Icons.image,
              label: AppLocalizations.of(context)!.textImage,
              onPressed: () => _pickFiles(type: FileType.image),
            ),
          if (Platform.isAndroid || Platform.isIOS)
            _pickButton(
              icon: Icons.video_file,
              label: AppLocalizations.of(context)!.textVideo,
              onPressed: () => _pickFiles(type: FileType.video),
            ),
        ],
      ),
    );
  }

  Widget _pickButton({
    required IconData icon,
    required String label,
    void Function()? onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilledButton.tonalIcon(
        style: ButtonStyle(
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
          ),
        ),
        icon: Icon(icon),
        onPressed: onPressed,
        label: Text(label),
      ),
    );
  }

  ListTile _deleteAllTile() {
    return ListTile(
      trailing: TextButton(
        onPressed: () {
          setState(() {
            _files.clear();
          });
        },
        child: Text(AppLocalizations.of(context)!.textDeleteAll),
      ),
    );
  }

  ListView _fileList() {
    return ListView.separated(
      itemBuilder: (context, index) => Consumer<JobStateModel>(
        builder: (context, state, child) {
          return FileCard(
            fileInfo: _files[index].info,
            trailingIcon: state.isSend ? null : Icons.delete,
            onTrailingIconPressed: () {
              setState(() {
                _files.removeAt(index);
              });
            },
          );
        },
      ),
      separatorBuilder: (context, index) {
        return const Divider(
          height: 2,
          color: Colors.transparent,
        );
      },
      itemCount: _files.length,
    );
  }

  Widget _actionCard() {
    return Consumer<JobStateModel>(builder: (context, state, child) {
      switch (state.value) {
        case JobState.waitingForReceiverToConnect:
          return _waitingStateActionCard(state);
        case JobState.sending:
          return _sendingStateActionCard(state);
        case JobState.sent:
          return _sentStateActionCard(state);
        default:
          return _readyStateActionCard(state);
      }
    });
  }

  Widget _readyStateActionCard(JobStateModel state) {
    final fileCountText =
        AppLocalizations.of(context)!.fileCount(_files.length);
    return ActionCard(
      subtitle: Text("$fileCountText\n${_totalFileSize.readableFileSize()}"),
      trailingIcon: Icons.send,
      onTrailingIconPressed: () async {
        if (state.isReceive) {
          ScaffoldMessenger.of(context)
              .showSnackBar(ongoingTaskSnackBar(context));
        } else {
          _package = await _packageRepo.create();
          if (_package == null) {
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(unknownErrorSnackBar(context));
            }
          } else {
            state.value = JobState.waitingForReceiverToConnect;
          }
        }
      },
    );
  }

  Widget _waitingStateActionCard(JobStateModel state) {
    return ActionCard(
      title: Text(
        _package!.code,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      subtitle: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "${AppLocalizations.of(context)!.textExpiresIn} ",
          ),
          TimerCountdown(
            endTime: _package!.expireTime,
            format: CountDownTimerFormat.minutesSeconds,
            enableDescriptions: false,
            spacerWidth: 2,
            onEnd: () {
              state.value = JobState.ready;
            },
          ),
        ],
      ),
      trailingIcon: Icons.cancel,
      onTrailingIconPressed: () {
        state.value = JobState.ready;
      },
    );
  }

  Widget _sendingStateActionCard(JobStateModel state) {
    final fileCountText =
        AppLocalizations.of(context)!.fileCount(_files.length);
    return ActionCard(
      subtitle: Text(
          "${_files.length} / $fileCountText\n${_totalFileSize.readableFileSize()} / ${_totalFileSize.readableFileSize()}"),
      trailingIcon: Icons.cancel,
      onTrailingIconPressed: () {
        state.value = JobState.ready;
      },
      linearProgressIndicator: const LinearProgressIndicator(
        value: 1.0,
      ),
    );
  }

  Widget _sentStateActionCard(JobStateModel state) {
    final fileCountText =
        AppLocalizations.of(context)!.fileCount(_files.length);
    return ActionCard(
      subtitle: Text(
          "${_files.length} / $fileCountText\n${_totalFileSize.readableFileSize()} / ${_totalFileSize.readableFileSize()}"),
      trailingIcon: state.value == JobState.sending ? Icons.cancel : Icons.done,
      onTrailingIconPressed: () {
        setState(() {
          _files.clear();
        });
        state.value = JobState.ready;
      },
      linearProgressIndicator: const LinearProgressIndicator(
        value: 1.0,
      ),
    );
  }
}
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_timer_countdown/flutter_timer_countdown.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:anysend/model/file.dart';
import 'package:anysend/model/job_state.dart';
import 'package:anysend/model/package.dart';
import 'package:anysend/repository/package.dart';
import 'package:anysend/util/file_helper.dart';
import 'package:anysend/util/peer_channel/send_channel.dart';
import 'package:anysend/view/widget/action_card.dart';
import 'package:anysend/view/widget/file_card.dart';
import 'package:anysend/view/widget/warning.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  static const Duration announcePeriod = Duration(seconds: 1);
  static const Duration progressPeriod = Duration(milliseconds: 500);

  final PackageRepository _packageRepo = PackageRepository();
  final SendChannel _sendChannel = SendChannel();

  List<JobFile> get _files => _sendChannel.files;

  Package? _package;
  Timer? _announceTimer;
  Timer? _progressTimer;

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

  Future<void> _startSend(JobStateModel state) async {
    for (JobFile file in _files) {
      file.readSizeInBytes = 0;
    }

    if (state.isReceive) {
      ScaffoldMessenger.of(context).showSnackBar(ongoingTaskSnackBar(context));
    } else {
      _package = await _packageRepo.create();
      if (_package == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(unknownErrorSnackBar(context));
        }
      } else {
        await WakelockPlus.enable();
        await _sendChannel.connect(
          onFailure: (wasConnected) async {
            ScaffoldMessenger.of(context).showSnackBar(wasConnected
                ? interruptedNetworkErrorSnackBar(context, onPressed: () {})
                : restrictedNetworkErrorSnackBar(context, onPressed: () {}));
            await _sendChannel.close();
            await WakelockPlus.disable();
            _progressTimer?.cancel();
            state.value = JobState.ready;
          },
          onDone: () async {
            await _sendChannel.close();
            await WakelockPlus.disable();
            _progressTimer?.cancel();
            state.value = JobState.sent;
          },
          onCancel: () async {
            ScaffoldMessenger.of(context).showSnackBar(canceledByPeerSnackBar(
              context,
              onPressed: () {},
            ));
            await _sendChannel.close();
            await WakelockPlus.disable();
            _progressTimer?.cancel();
            state.value = JobState.ready;
          },
          onAskToReceive: (peerId, name) async {
            if (_sendChannel.peerId != null) {
              await _sendChannel.replyToReceive(peerId, false);
            } else {
              showDialog(
                barrierDismissible: false,
                context: context,
                builder: (context) => ChangeNotifierProvider.value(
                  value: state,
                  child: _acceptOrDenyDialog(peerId, name),
                ),
              );
            }
          },
        );
        final code = _package!.code;
        final expireTime = _package!.expireTime;
        _announceTimer = Timer.periodic(announcePeriod, (timer) {
          _packageRepo.send(code: code, expireTime: expireTime);
        });
        state.value = JobState.waitingForReceiverToConnect;
      }
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _packageRepo.closeSend();
    _sendChannel.close();
    super.dispose();
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
            showPreview: true,
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
      subtitle: Text(
          "$fileCountText\n${_sendChannel.totalFileSize.readableFileSize()}"),
      trailingIcon: Icons.send,
      onTrailingIconPressed: () async {
        await _startSend(state);
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
            onEnd: () async {
              _announceTimer?.cancel();
              await _sendChannel.close();
              await WakelockPlus.disable();
              state.value = JobState.ready;
            },
          ),
        ],
      ),
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: _package!.code));
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(codeCopiedToClipboardSnackBar(context));
        }
      },
      trailingIcon: Icons.cancel,
      onTrailingIconPressed: () async {
        _announceTimer?.cancel();
        await _sendChannel.close();
        await WakelockPlus.disable();
        state.value = JobState.ready;
      },
    );
  }

  Widget _sendingStateActionCard(JobStateModel state) {
    final fileCountText =
        AppLocalizations.of(context)!.fileCount(_files.length);
    return ActionCard(
      subtitle: Text(
          "${_sendChannel.sentFileCount} / $fileCountText\n${_sendChannel.sentFileSize.readableFileSize()} / ${_sendChannel.totalFileSize.readableFileSize()}\n${_sendChannel.speedInBytes.readableFileSize()}/s (${_sendChannel.remainingTime})"),
      trailingIcon: Icons.cancel,
      onTrailingIconPressed: () => showDialog(
        context: context,
        builder: (context) =>
            confirmCancellationDialog(context, onPressed: (canceled) async {
          if (canceled) {
            _sendChannel.sendCancelSignal();
            await _sendChannel.close();
            await WakelockPlus.disable();
            _progressTimer?.cancel();
          }
          if (mounted) {
            Navigator.pop(context, canceled ? "canceled" : "not_canceled");
          }
          if (canceled) {
            state.value = JobState.ready;
          }
        }),
      ),
      linearProgressIndicator: LinearProgressIndicator(
        value: _sendChannel.sentProgress,
      ),
    );
  }

  Widget _sentStateActionCard(JobStateModel state) {
    final fileCountText =
        AppLocalizations.of(context)!.fileCount(_files.length);
    return ActionCard(
      subtitle: Text(
          "${_sendChannel.sentFileCount} / $fileCountText\n${_sendChannel.sentFileSize.readableFileSize()} / ${_sendChannel.totalFileSize.readableFileSize()}"),
      trailingIcon: state.value == JobState.sending ? Icons.cancel : Icons.done,
      onTrailingIconPressed: () async {
        await _sendChannel.close();
        await WakelockPlus.disable();
        setState(() {
          _files.clear();
        });
        state.value = JobState.ready;
      },
      linearProgressIndicator: LinearProgressIndicator(
        value: _sendChannel.sentProgress,
      ),
    );
  }

  Widget _acceptOrDenyDialog(String peerId, String name) {
    return Consumer<JobStateModel>(
      builder: (context, state, child) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.textRequestForReceive(name),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _sendChannel.replyToReceive(peerId, false);
              if (mounted) {
                Navigator.pop(context, "deny");
              }
            },
            child: Text(
              AppLocalizations.of(context)!.textDeny,
              textAlign: TextAlign.center,
            ),
          ),
          TextButton(
            onPressed: () async {
              await _sendChannel.replyToReceive(peerId, true);
              _announceTimer?.cancel();
              if (mounted) {
                Navigator.pop(context, "accept");
              }
              _progressTimer = Timer.periodic(progressPeriod, (timer) {
                setState(() {});
              });
              state.value = JobState.sending;
            },
            child: Text(
              AppLocalizations.of(context)!.textAccept,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

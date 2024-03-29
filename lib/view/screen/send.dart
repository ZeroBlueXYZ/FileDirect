import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:file_picker/file_picker.dart';
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
import 'package:anysend/view/screen/message.dart';
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
  static const Duration progressPeriod = Duration(seconds: 1);

  final PackageRepository _packageRepo = PackageRepository();
  final SendChannel _sendChannel = SendChannel();

  List<JobFile> get _files => _sendChannel.files;

  bool _toAcceptOrDeny = false;
  Package? _package;
  Timer? _announceTimer;
  Timer? _progressTimer;

  void _pickFiles({FileType type = FileType.any}) async {
    final bool showLoading = Platform.isAndroid || Platform.isIOS;
    if (showLoading) {
      showDialog(
        context: context,
        builder: (context) => _loadingDialog(),
        barrierDismissible: false,
      );
    }
    await FilePicker.platform
        .pickFiles(
      type: type,
      allowMultiple: true,
    )
        .then((result) {
      if (showLoading) {
        Navigator.pop(context);
      }
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
    }).onError((error, stackTrace) {
      if (showLoading) {
        Navigator.pop(context);
      }
    });
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

    if (state.isReceiveBusy) {
      ScaffoldMessenger.of(context)
          .showSnackBar(receiveJobRunningSnackBar(context));
    } else {
      await _packageRepo.create().then((value) async {
        _package = value;
        if (_package == null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(unknownErrorSnackBar(context));
        } else {
          await WakelockPlus.enable();
          await _sendChannel.connect(onFailure: (wasConnected) async {
            ScaffoldMessenger.of(context).showSnackBar(wasConnected
                ? interruptedNetworkErrorSnackBar(context, onPressed: () {})
                : restrictedNetworkErrorSnackBar(context, onPressed: () {}));
            await _sendChannel.close();
            await WakelockPlus.disable();
            _progressTimer?.cancel();
            state.sendState = JobState.ready;
          }, onDone: () async {
            await _sendChannel.close();
            await WakelockPlus.disable();
            _progressTimer?.cancel();
            state.sendState = JobState.done;
          }, onCancel: () async {
            ScaffoldMessenger.of(context).showSnackBar(canceledByPeerSnackBar(
              context,
              onPressed: () {},
            ));
            await _sendChannel.close();
            await WakelockPlus.disable();
            _progressTimer?.cancel();
            state.sendState = JobState.ready;
          }, onAskToReceive: (peerId, name) async {
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
          }, onCancelAskToReceive: (peerId) async {
            if (_toAcceptOrDeny) {
              Navigator.pop(context);
            }
          });
          final code = _package!.code;
          final expireTime = _package!.expireTime;
          _announceTimer = Timer.periodic(announcePeriod, (timer) {
            _packageRepo.send(code: code, expireTime: expireTime);
          });
          state.sendState = JobState.waiting;
        }
      }).onError((error, stackTrace) {
        if (error is TimeoutException) {
          ScaffoldMessenger.of(context)
              .showSnackBar(timeoutErrorSnackBar(context));
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(unknownErrorSnackBar(context));
        }
      });
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
            if (state.sendState == JobState.ready) _pickButtons(),
            if (state.sendState == JobState.ready && _files.isNotEmpty)
              _toolbar(),
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
              icon: Icons.photo,
              label: AppLocalizations.of(context)!.textPhoto,
              onPressed: () => _pickFiles(type: FileType.media),
            ),
          _pickButton(
            icon: Icons.message,
            label: AppLocalizations.of(context)!.textMessage,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MessageScreen(readOnly: false),
                ),
              ).then((fileInfo) {
                if ((fileInfo as FileInfo?) != null) {
                  _files.add(JobFile(info: fileInfo!));
                  setState(() {});
                }
              });
            },
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
        label: Text(label, maxLines: 1),
      ),
    );
  }

  ListTile _toolbar() {
    return ListTile(
      trailing: IconButton(
        onPressed: () {
          setState(() {
            _files.clear();
          });
        },
        icon: const Icon(Icons.delete_outline),
      ),
    );
  }

  ListView _fileList() {
    return ListView.separated(
      itemBuilder: (context, index) => Consumer<JobStateModel>(
        builder: (context, state, child) {
          return FileCard(
            fileInfo: _files[index].info,
            trailing: state.sendState == JobState.ready
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_files[index].info.textData != null)
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MessageScreen(
                                  readOnly: false,
                                  initialText: _files[index].info.textData,
                                ),
                              ),
                            ).then((fileInfo) {
                              if ((fileInfo as FileInfo?) != null) {
                                _files[index] = JobFile(info: fileInfo!);
                                setState(() {});
                              }
                            });
                          },
                          icon: const Icon(Icons.edit),
                        ),
                      IconButton(
                          onPressed: () {
                            setState(() {
                              _files.removeAt(index);
                            });
                          },
                          icon: const Icon(Icons.remove))
                    ],
                  )
                : null,
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
      switch (state.sendState) {
        case JobState.waiting:
          return _waitingStateActionCard(state);
        case JobState.running:
          return _sendingStateActionCard(state);
        case JobState.done:
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
              state.sendState = JobState.ready;
            },
          ),
        ],
      ),
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: _package!.code)).then((_) {
          if (!Platform.isAndroid) {
            ScaffoldMessenger.of(context)
                .showSnackBar(copiedToClipboardSnackBar(context));
          }
        });
      },
      trailingIcon: Icons.cancel,
      onTrailingIconPressed: () async {
        _announceTimer?.cancel();
        await _sendChannel.close();
        await WakelockPlus.disable();
        state.sendState = JobState.ready;
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
            await _sendChannel.close().then((_) async {
              WakelockPlus.disable();
              _progressTimer?.cancel();
              state.sendState = JobState.ready;
              Navigator.pop(context);
            });
          } else {
            Navigator.pop(context);
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
      trailingIcon:
          state.sendState == JobState.running ? Icons.cancel : Icons.done,
      onTrailingIconPressed: () async {
        await _sendChannel.close();
        await WakelockPlus.disable();
        setState(() {
          _files.clear();
        });
        state.sendState = JobState.ready;
      },
      linearProgressIndicator: LinearProgressIndicator(
        value: _sendChannel.sentProgress,
      ),
    );
  }

  Widget _acceptOrDenyDialog(String peerId, String name) {
    _toAcceptOrDeny = true;
    return Consumer<JobStateModel>(
      builder: (context, state, child) => AlertDialog(
        title: Text(
          "${AppLocalizations.of(context)!.textConnection}:\n$name",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _sendChannel.replyToReceive(peerId, false).then((value) {
                Navigator.pop(context);
              }).onError((error, stackTrace) {
                Navigator.pop(context);
              });
              _toAcceptOrDeny = false;
            },
            child: Text(
              AppLocalizations.of(context)!.textDeny,
              textAlign: TextAlign.center,
            ),
          ),
          TextButton(
            onPressed: () {
              _sendChannel.replyToReceive(peerId, true).then((_) {
                _announceTimer?.cancel();
                Navigator.pop(context);
                _progressTimer = Timer.periodic(progressPeriod, (timer) {
                  setState(() {});
                });
                state.sendState = JobState.running;
              }).onError((error, stackTrace) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(unknownErrorSnackBar(context));
                Navigator.pop(context);
              });
              _toAcceptOrDeny = false;
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

  Widget _loadingDialog() {
    return const Center(
      child: SizedBox.square(
        dimension: 60,
        child: CircularProgressIndicator(),
      ),
    );
  }
}

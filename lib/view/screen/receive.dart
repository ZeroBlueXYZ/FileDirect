import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:anysend/model/file.dart';
import 'package:anysend/model/job_state.dart';
import 'package:anysend/model/package.dart';
import 'package:anysend/repository/package.dart';
import 'package:anysend/util/file_helper.dart';
import 'package:anysend/util/global_config.dart';
import 'package:anysend/util/output_path_helper.dart';
import 'package:anysend/util/peer_channel/receive_channel.dart';
import 'package:anysend/view/screen/message.dart';
import 'package:anysend/view/widget/action_card.dart';
import 'package:anysend/view/widget/file_card.dart';
import 'package:anysend/view/widget/nearby_card.dart';
import 'package:anysend/view/widget/warning.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  static const Duration announcePeriod = Duration(seconds: 1);
  static const Duration announceTtl = Duration(seconds: 4);
  static const Duration progressPeriod = Duration(seconds: 1);

  final PackageRepository _packageRepo = PackageRepository();
  final ReceiveChannel _receiveChannel = ReceiveChannel();

  final HashMap<NearbyPackage, DateTime> _nearbyPackages = HashMap();

  final GlobalKey<FormState> _codeFormKey = GlobalKey<FormState>();

  late final TextEditingController _codeTextEditingController;

  List<JobFile> get _files => _receiveChannel.files;
  List<JobFile> get _filteredFiles => _files
      .where((file) =>
          _selectedFileType == FileInfoType.other ||
          file.info.type == _selectedFileType)
      .toList();
  FileInfoType _selectedFileType = FileInfoType.other;

  Timer? _announceTimer;
  Timer? _progressTimer;

  Future<void> _refreshAnnounce() async {
    _announceTimer ??= Timer.periodic(announcePeriod, (timer) {
      _nearbyPackages.removeWhere((package, expireTime) =>
          expireTime.isBefore(DateTime.now()) ||
          package.expireTime.isBefore(DateTime.now()));
      setState(() {});
    });
    try {
      await _packageRepo.receive((nearbyPackage) {
        _nearbyPackages[nearbyPackage] = DateTime.now().add(announceTtl);
      });
    } catch (_) {}
  }

  Future<void> _startReceive(
    BuildContext parentContext,
    JobStateModel state,
    String code,
  ) async {
    await getOutputDirectory().then((directory) async {
      if (directory == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(unknownErrorSnackBar(context));
      } else {
        _receiveChannel.outputDirectory = directory;
        _files.clear();

        await _packageRepo.get(code: code).then((package) async {
          if (package == null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(invalidCodeSnackBar(context));
          } else {
            await WakelockPlus.enable();
            await _receiveChannel.connect(
              peerId: package.ownerId,
              onFailure: (wasConnected) async {
                ScaffoldMessenger.of(parentContext).showSnackBar(wasConnected
                    ? interruptedNetworkErrorSnackBar(parentContext,
                        onPressed: () {})
                    : restrictedNetworkErrorSnackBar(parentContext,
                        onPressed: () {}));
                await _receiveChannel.close();
                await WakelockPlus.disable();
                _progressTimer?.cancel();
                state.receiveState = JobState.ready;
              },
              onDone: () async {
                await _receiveChannel.close();
                await WakelockPlus.disable();
                _progressTimer?.cancel();
                state.receiveState = JobState.done;
              },
              onCancel: () async {
                ScaffoldMessenger.of(parentContext)
                    .showSnackBar(canceledByPeerSnackBar(
                  parentContext,
                  onPressed: () {},
                ));
                await _receiveChannel.close();
                await WakelockPlus.disable();
                _progressTimer?.cancel();
                state.receiveState = JobState.ready;
              },
              onAcceptOrDeny: (accept) async {
                if (accept) {
                  _progressTimer = Timer.periodic(progressPeriod, (timer) {
                    setState(() {});
                  });
                  state.receiveState = JobState.running;
                } else {
                  ScaffoldMessenger.of(parentContext)
                      .showSnackBar(deniedBySenderSnackBar(
                    parentContext,
                    onPressed: () {},
                  ));
                  await _receiveChannel.close();
                  await WakelockPlus.disable();
                  state.receiveState = JobState.ready;
                }
              },
            );
            await _receiveChannel.askToReceive(
                "${GlobalConfig().deviceName} (${GlobalConfig().receiverId})");
            state.receiveState = JobState.waiting;
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
    });
  }

  @override
  void initState() {
    super.initState();
    _codeTextEditingController = TextEditingController();
    _refreshAnnounce();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _announceTimer?.cancel();
    _packageRepo.closeReceive();
    _receiveChannel.close();
    _codeTextEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Consumer<JobStateModel>(
        builder: (context, state, child) => state.receiveState == JobState.ready
            ? _readyStateWidget(context)
            : Column(children: [
                if (state.receiveState == JobState.running ||
                    state.receiveState == JobState.done)
                  _toolbar(),
                Expanded(child: _fileList()),
                _actionCard(),
              ]),
      ),
    );
  }

  Widget _readyStateWidget(BuildContext parentContext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _codeForm(parentContext),
        const Divider(height: 20, color: Colors.transparent),
        Expanded(child: _nearbyList(parentContext)),
      ],
    );
  }

  Widget _codeForm(BuildContext parentContext) {
    return Container(
      alignment: AlignmentDirectional.center,
      child: Consumer<JobStateModel>(
        builder: (context, state, child) => Form(
          key: _codeFormKey,
          child: ListTile(
            title: TextFormField(
              controller: _codeTextEditingController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30))),
                hintText: AppLocalizations.of(context)!
                    .textEnterReceiveCodeFromSender,
                errorStyle: const TextStyle(fontSize: 0),
              ),
              textAlign: TextAlign.center,
              validator: (value) =>
                  value != null && RegExp(r"^\d{6}$").hasMatch(value)
                      ? null
                      : "",
            ),
            trailing: IconButton.outlined(
              icon: const Icon(Icons.navigate_next, size: 30),
              onPressed: () async {
                if (_codeFormKey.currentState != null &&
                    _codeFormKey.currentState!.validate()) {
                  if (state.isSendBusy) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(sendJobRunningSnackBar(context));
                  } else {
                    await _startReceive(
                      parentContext,
                      state,
                      _codeTextEditingController.text,
                    );
                  }
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  ListView _nearbyList(BuildContext parentContext) {
    final nearbyPackages = _nearbyPackages.entries.toList();
    nearbyPackages.sort((a, b) => a.key.code.compareTo(b.key.code));
    return ListView.separated(
      itemBuilder: (context, index) => Consumer<JobStateModel>(
        builder: (context, state, child) => NearbyCard(
          package: nearbyPackages[index].key,
          onTap: () async {
            if (state.isSendBusy) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(sendJobRunningSnackBar(context));
            } else {
              await _startReceive(
                parentContext,
                state,
                nearbyPackages[index].key.code,
              );
            }
          },
        ),
      ),
      separatorBuilder: (context, index) {
        return const Divider(
          height: 2,
          color: Colors.transparent,
        );
      },
      itemCount: nearbyPackages.length,
    );
  }

  ListTile _toolbar() {
    return ListTile(
      leading: Wrap(
        spacing: 5,
        children: [
          (FileInfoType.image, AppLocalizations.of(context)!.textImage),
          (FileInfoType.video, AppLocalizations.of(context)!.textVideo),
          (FileInfoType.message, AppLocalizations.of(context)!.textMessage),
        ]
            .map((item) => ChoiceChip(
                label: Text(item.$2),
                selected: _selectedFileType == item.$1,
                onSelected: (selected) {
                  setState(() {
                    _selectedFileType = selected ? item.$1 : FileInfoType.other;
                  });
                }))
            .toList(),
      ),
    );
  }

  ListView _fileList() {
    return ListView.separated(
      itemBuilder: (context, index) => Consumer<JobStateModel>(
        builder: (context, state, child) {
          final file = _filteredFiles[index];
          return FileCard(
            fileInfo: file.info,
            linearProgressIndicator: state.receiveState == JobState.running
                ? LinearProgressIndicator(value: file.writeProgress)
                : null,
            trailing:
                file.info.type == FileInfoType.message && file.isWriteComplete()
                    ? IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MessageScreen(
                                readOnly: true,
                                initialText: file.info.textData,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.navigate_next),
                      )
                    : null,
            showPreview: file.isWriteComplete(),
          );
        },
      ),
      separatorBuilder: (context, index) {
        return const Divider(
          height: 2,
          color: Colors.transparent,
        );
      },
      itemCount: _filteredFiles.length,
    );
  }

  Widget _actionCard() {
    return Consumer<JobStateModel>(
      builder: (context, state, child) {
        switch (state.receiveState) {
          case JobState.waiting:
            return _waitingStateActionCard(state);
          case JobState.running:
            return _receivingStateActionCard(state);
          case JobState.done:
            return _receivedStateActionCard(state);
          default:
            throw AssertionError("invalid state ${state.receiveState}");
        }
      },
    );
  }

  Widget _waitingStateActionCard(JobStateModel state) {
    return ActionCard(
      title: Text(GlobalConfig().receiverId, textAlign: TextAlign.center),
      subtitle: Text(
        AppLocalizations.of(context)!.textWaitForSenderToAccept,
        textAlign: TextAlign.center,
      ),
      trailingIcon: Icons.cancel,
      onTrailingIconPressed: () async {
        await _receiveChannel.close();
        await WakelockPlus.disable();
        state.receiveState = JobState.ready;
      },
    );
  }

  Widget _receivingStateActionCard(JobStateModel state) {
    final fileCountText =
        AppLocalizations.of(context)!.fileCount(_files.length);
    return ActionCard(
      subtitle: Text(
          "${_receiveChannel.receivedFileCount} / $fileCountText\n${_receiveChannel.receivedFileSize.readableFileSize()} / ${_receiveChannel.totalFileSize.readableFileSize()}\n${_receiveChannel.speedInBytes.readableFileSize()}/s (${_receiveChannel.remainingTime})"),
      trailingIcon: Icons.cancel,
      onTrailingIconPressed: () => showDialog(
        context: context,
        builder: (context) =>
            confirmCancellationDialog(context, onPressed: (canceled) async {
          if (canceled) {
            _receiveChannel.sendCancelSignal();
            await _receiveChannel.close().then((_) {
              WakelockPlus.disable();
              _progressTimer?.cancel();
              state.receiveState = JobState.ready;
              Navigator.pop(context);
            });
          } else {
            Navigator.pop(context);
          }
        }),
      ),
      linearProgressIndicator: LinearProgressIndicator(
        value: _receiveChannel.receiveProgress,
      ),
    );
  }

  Widget _receivedStateActionCard(JobStateModel state) {
    final fileCountText =
        AppLocalizations.of(context)!.fileCount(_files.length);
    return ActionCard(
      subtitle: Text(
          "${_receiveChannel.receivedFileCount} / $fileCountText\n${_receiveChannel.receivedFileSize.readableFileSize()} / ${_receiveChannel.totalFileSize.readableFileSize()}"),
      trailingIcon: Icons.done,
      onTrailingIconPressed: () async {
        await _receiveChannel.close();
        await WakelockPlus.disable();
        setState(() {
          _files.clear();
        });
        state.receiveState = JobState.ready;
      },
      linearProgressIndicator: LinearProgressIndicator(
        value: _receiveChannel.receiveProgress,
      ),
    );
  }
}

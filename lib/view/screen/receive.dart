import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:anysend/model/file.dart';
import 'package:anysend/model/job_state.dart';
import 'package:anysend/model/package.dart';
import 'package:anysend/repository/package.dart';
import 'package:anysend/util/file_helper.dart';
import 'package:anysend/util/peer_channel/receive_channel.dart';
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
  static const String androidDownloadDirectoryPath =
      "/storage/emulated/0/Download/";
  static const Duration announcePeriod = Duration(seconds: 2);
  static const Duration announceTtl = Duration(seconds: 5);
  static const Duration progressPeriod = Duration(milliseconds: 500);

  final PackageRepository _packageRepo = PackageRepository();
  final ReceiveChannel _receiveChannel = ReceiveChannel();
  final String _name = "#${Random().nextInt(999).toString().padLeft(3, "0")}";

  final HashMap<NearbyPackage, DateTime> _nearbyPackages = HashMap();

  final GlobalKey<FormState> _codeFormKey = GlobalKey<FormState>();

  final TextEditingController _codeTextEditingController =
      TextEditingController();

  List<JobFile> get _files => _receiveChannel.files;

  Timer? _announceTimer;
  Timer? _progressTimer;

  void _refreshAnnounce() {
    _announceTimer ??= Timer.periodic(announcePeriod, (timer) {
      _nearbyPackages.removeWhere((package, expireTime) =>
          expireTime.isBefore(DateTime.now()) ||
          package.expireTime.isBefore(DateTime.now()));
      setState(() {});
    });
    _packageRepo.receive((nearbyPackage) {
      _nearbyPackages[nearbyPackage] = DateTime.now().add(announceTtl);
    });
  }

  Future<Directory?> _getOutputDirectory() async {
    if (Platform.isAndroid) {
      PermissionStatus status =
          await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        if (status.isPermanentlyDenied) {
          openAppSettings();
        }
        return null;
      }
    }

    Directory? directory;
    if (Platform.isAndroid) {
      directory = Directory(androidDownloadDirectoryPath);
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    } else {
      directory = await getDownloadsDirectory();
    }

    if (directory != null) {
      if (directory.existsSync()) {
        return directory;
      }

      try {
        directory.createSync();
        return directory;
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(unknownErrorSnackBar(context));
    }
    return null;
  }

  Future<void> _startReceive(
    BuildContext parentContext,
    JobStateModel state,
    String code,
  ) async {
    Directory? directory = await _getOutputDirectory();
    if (directory == null) {
      return;
    }
    _receiveChannel.outputDirectory = directory.path;
    _files.clear();

    final package = await _packageRepo.get(code: code);
    if (package == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(invalidCodeSnackBar(context));
      }
    } else {
      await WakelockPlus.enable();
      await _receiveChannel.connect(
        peerId: package.ownerId,
        onFailure: (wasConnected) async {
          ScaffoldMessenger.of(parentContext).showSnackBar(wasConnected
              ? interruptedNetworkErrorSnackBar(parentContext, onPressed: () {})
              : restrictedNetworkErrorSnackBar(parentContext,
                  onPressed: () {}));
          await _receiveChannel.close();
          await WakelockPlus.disable();
          _progressTimer?.cancel();
          state.value = JobState.ready;
        },
        onDone: () async {
          await _receiveChannel.close();
          await WakelockPlus.disable();
          _progressTimer?.cancel();
          state.value = JobState.received;
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
          state.value = JobState.ready;
        },
        onAcceptOrDeny: (accept) async {
          if (accept) {
            _progressTimer = Timer.periodic(progressPeriod, (timer) {
              setState(() {});
            });
            state.value = JobState.receiving;
          } else {
            ScaffoldMessenger.of(parentContext)
                .showSnackBar(deniedBySenderSnackBar(
              parentContext,
              onPressed: () {},
            ));
            await _receiveChannel.close();
            await WakelockPlus.disable();
            state.value = JobState.ready;
          }
        },
      );
      await _receiveChannel.askToReceive(_name);
      state.value = JobState.waitingForSenderToAccept;
    }
  }

  @override
  void initState() {
    _refreshAnnounce();
    super.initState();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _announceTimer?.cancel();
    _packageRepo.closeReceive();
    _receiveChannel.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Consumer<JobStateModel>(
        builder: (context, state, child) => state.isReceive
            ? Column(children: [
                Expanded(child: _fileList()),
                _actionCard(),
              ])
            : _readyStateWidget(context),
      ),
    );
  }

  Widget _readyStateWidget(BuildContext parentContext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            AppLocalizations.of(context)!.textCode,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        _codeForm(parentContext),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            AppLocalizations.of(context)!.textNearby,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
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
                    borderRadius: BorderRadius.all(Radius.circular(32))),
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
            trailing: IconButton.filledTonal(
              icon: const Icon(Icons.arrow_forward, size: 28),
              onPressed: () async {
                if (_codeFormKey.currentState != null &&
                    _codeFormKey.currentState!.validate()) {
                  if (state.isSend) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(ongoingTaskSnackBar(context));
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
            await _startReceive(
              parentContext,
              state,
              nearbyPackages[index].key.code,
            );
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

  ListView _fileList() {
    return ListView.separated(
      itemBuilder: (context, index) => Consumer<JobStateModel>(
        builder: (context, state, child) {
          return FileCard(
            fileInfo: _files[index].info,
            linearProgressIndicator: state.value == JobState.receiving
                ? LinearProgressIndicator(value: _files[index].writeProgress)
                : null,
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
    return Consumer<JobStateModel>(
      builder: (context, state, child) {
        switch (state.value) {
          case JobState.waitingForSenderToAccept:
            return _waitingStateActionCard(state);
          case JobState.receiving:
            return _receivingStateActionCard(state);
          case JobState.received:
            return _receivedStateActionCard(state);
          default:
            throw AssertionError("cannot be ${state.value} state");
        }
      },
    );
  }

  Widget _waitingStateActionCard(JobStateModel state) {
    return ActionCard(
      title: Text(_name, textAlign: TextAlign.center),
      subtitle: Text(
        AppLocalizations.of(context)!.textWaitForSenderToAccept,
        textAlign: TextAlign.center,
      ),
      trailingIcon: Icons.cancel,
      onTrailingIconPressed: () async {
        await _receiveChannel.close();
        await WakelockPlus.disable();
        state.value = JobState.ready;
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
            await _receiveChannel.close();
            await WakelockPlus.disable();
            _progressTimer?.cancel();
            state.value = JobState.ready;
          }
          if (mounted) {
            Navigator.pop(context, canceled ? "canceled" : "not_canceled");
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
        state.value = JobState.ready;
      },
      linearProgressIndicator: LinearProgressIndicator(
        value: _receiveChannel.receiveProgress,
      ),
    );
  }
}

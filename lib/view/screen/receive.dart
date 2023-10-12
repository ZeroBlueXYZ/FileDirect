import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:anysend/model/file.dart';
import 'package:anysend/model/job_state.dart';
import 'package:anysend/model/package.dart';
import 'package:anysend/repository/package.dart';
import 'package:anysend/util/file_helper.dart';
import 'package:anysend/view/widget/action_card.dart';
import 'package:anysend/view/widget/file_card.dart';
import 'package:anysend/view/widget/warning.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  final PackageRepository _packageRepo = PackageRepository();

  final List<JobFile> _files = [];

  final GlobalKey<FormState> _codeFormKey = GlobalKey<FormState>();

  final TextEditingController _codeTextEditingController =
      TextEditingController();

  Package? _package;

  int get _totalFileSize =>
      _files.fold(0, (previousValue, file) => previousValue + file.info.size);

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
            : _codeForm(context),
      ),
    );
  }

  ListView _fileList() {
    return ListView.separated(
      itemBuilder: (context, index) => Consumer<JobStateModel>(
        builder: (context, state, child) {
          return FileCard(
            fileInfo: _files[index].info,
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
                border: const OutlineInputBorder(),
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
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () async {
                if (_codeFormKey.currentState != null &&
                    _codeFormKey.currentState!.validate()) {
                  if (state.isSend) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(ongoingTaskSnackBar(context));
                  } else {
                    _package = await _packageRepo.get(
                        code: _codeTextEditingController.text);
                    if (_package == null) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(invalidCodeSnackBar(context));
                      }
                    } else {
                      state.value = JobState.waitingForSenderToAccept;
                    }
                  }
                }
              },
            ),
          ),
        ),
      ),
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
      title: const Text("#101", textAlign: TextAlign.center),
      subtitle: Text(
        AppLocalizations.of(context)!.textWaitForSenderToAccept,
        textAlign: TextAlign.center,
      ),
      trailingIcon: Icons.cancel,
      onTrailingIconPressed: () {
        state.value = JobState.ready;
      },
    );
  }

  Widget _receivingStateActionCard(JobStateModel state) {
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

  Widget _receivedStateActionCard(JobStateModel state) {
    final fileCountText =
        AppLocalizations.of(context)!.fileCount(_files.length);
    return ActionCard(
      subtitle: Text(
          "${_files.length} / $fileCountText\n${_totalFileSize.readableFileSize()} / ${_totalFileSize.readableFileSize()}"),
      trailingIcon: Icons.done,
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

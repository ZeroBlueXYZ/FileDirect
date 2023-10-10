import 'package:flutter/material.dart';

enum JobState {
  ready,
  waitingForSenderToAccept,
  receiving,
  received,
  waitingForReceiverToConnect,
  sending,
  sent,
}

class JobStateModel extends ChangeNotifier {
  JobState _state = JobState.ready;

  JobState get value => _state;

  set value(JobState state) {
    _state = state;
    notifyListeners();
  }

  bool get isReceive =>
      _state == JobState.waitingForSenderToAccept ||
      _state == JobState.receiving ||
      _state == JobState.received;

  bool get isSend =>
      _state == JobState.waitingForReceiverToConnect ||
      _state == JobState.sending ||
      _state == JobState.sent;
}

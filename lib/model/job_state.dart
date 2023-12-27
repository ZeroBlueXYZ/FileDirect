import 'package:flutter/material.dart';

enum JobState {
  ready,
  waiting,
  running,
  done,
}

class JobStateModel extends ChangeNotifier {
  JobState _receiveState = JobState.ready;
  JobState _sendState = JobState.ready;

  JobState get receiveState => _receiveState;
  JobState get sendState => _sendState;

  set receiveState(JobState state) {
    _receiveState = state;
    notifyListeners();
  }

  set sendState(JobState state) {
    _sendState = state;
    notifyListeners();
  }

  bool get isReceiveBusy =>
      _receiveState == JobState.waiting || _receiveState == JobState.running;
  bool get isSendBusy =>
      _sendState == JobState.waiting || _sendState == JobState.running;
}

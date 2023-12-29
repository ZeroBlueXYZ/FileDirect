import 'dart:collection';

class TimeoutWindow {
  final Queue<TimeoutNum> _queue = Queue();
  late final Duration _timeout;

  TimeoutWindow({int timeoutInSeconds = 3}) {
    if (timeoutInSeconds <= 0 || timeoutInSeconds > 60) {
      throw "timeout must be in the range [1, 60]";
    }
    _timeout = Duration(seconds: timeoutInSeconds);
  }

  double mean() {
    _expire();
    return _queue.isEmpty
        ? 0.0
        : _queue.fold(0.0,
                (previousValue, element) => previousValue + element.value) /
            _timeout.inSeconds;
  }

  void add(double value) {
    _queue.add(
        TimeoutNum(expireTime: DateTime.now().add(_timeout), value: value));
    _expire();
  }

  void _expire() {
    DateTime now = DateTime.now();
    while (_queue.isNotEmpty && _queue.first.expireTime.isBefore(now)) {
      _queue.removeFirst();
    }
  }
}

class TimeoutNum {
  final DateTime expireTime;
  final double value;

  TimeoutNum({
    required this.expireTime,
    required this.value,
  });
}

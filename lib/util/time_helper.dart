extension ReadableDuration on int {
  String readableDuration() {
    Duration duration = Duration(seconds: this);
    return duration.toString().split('.').first;
  }
}

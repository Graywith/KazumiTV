class TvExitConfirmation {
  DateTime? _promptAt;

  bool confirm(DateTime now) {
    final previous = _promptAt;
    if (previous != null &&
        now.difference(previous) < const Duration(seconds: 2)) {
      reset();
      return true;
    }
    _promptAt = now;
    return false;
  }

  void reset() => _promptAt = null;
}

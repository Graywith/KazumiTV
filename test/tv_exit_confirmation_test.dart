import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/pages/video/tv_exit_confirmation.dart';

void main() {
  test('Playback exit requires two Back presses within two seconds', () {
    final confirmation = TvExitConfirmation();
    final now = DateTime(2026);
    expect(confirmation.confirm(now), isFalse);
    expect(confirmation.confirm(now.add(const Duration(seconds: 1))), isTrue);
    expect(confirmation.confirm(now.add(const Duration(seconds: 2))), isFalse);
    expect(confirmation.confirm(now.add(const Duration(seconds: 5))), isFalse);
    confirmation.reset();
    expect(
      confirmation.confirm(now.add(const Duration(milliseconds: 5500))),
      isFalse,
    );
  });
}

// Multi-device local scheduling (T7.4.13, T7.4.19): all, primary only and last active device.
import 'package:everslot/features/notifications/domain/notification_settings.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 10, 2, 12);

  test('all devices schedule locally', () {
    const s = NotificationSettings();
    expect(
      s.localSchedulingAllowed('phone', lastForegroundAt: now.subtract(const Duration(days: 9)), now: now),
      isTrue,
    );
  });

  test('primary only: other devices never schedule locally', () {
    const s = NotificationSettings(multiDevicePolicy: MultiDevicePolicy.primary, primaryDeviceId: 'phone');
    expect(s.localSchedulingAllowed('phone'), isTrue);
    expect(s.localSchedulingAllowed('tablet'), isFalse);
  });

  test('last active: only devices foregrounded within 12 h schedule locally', () {
    const s = NotificationSettings(multiDevicePolicy: MultiDevicePolicy.lastActive);
    expect(
      s.localSchedulingAllowed('phone', lastForegroundAt: now.subtract(const Duration(hours: 2)), now: now),
      isTrue,
    );
    expect(
      s.localSchedulingAllowed('tablet', lastForegroundAt: now.subtract(const Duration(hours: 12)), now: now),
      isTrue,
    );
    expect(
      s.localSchedulingAllowed(
        'tablet',
        lastForegroundAt: now.subtract(const Duration(hours: 12, minutes: 1)),
        now: now,
      ),
      isFalse,
    );
    // Unknown foreground (fresh install): keep scheduling until the first foreground is recorded.
    expect(s.localSchedulingAllowed('tablet', now: now), isTrue);
  });
}

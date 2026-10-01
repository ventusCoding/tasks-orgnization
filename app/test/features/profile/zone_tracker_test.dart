import 'package:everslot/core/providers.dart';
import 'package:everslot/features/auth/presentation/session_banner_host.dart';
import 'package:everslot/features/profile/application/profile_providers.dart';
import 'package:everslot/features/profile/application/zone_tracker.dart';
import 'package:everslot/features/profile/domain/zone_change.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';
import '../auth/support/widget_helpers.dart';

Future<TestHarness> _harness({String home = 'Europe/Paris', String zone = 'Europe/Paris'}) async {
  final h = TestHarness.create(zone: zone);
  await h.read(profileRepositoryProvider).update(homeTimeZone: home);
  return h;
}

Future<void> _idle(ZoneTracker t) => t.observe('').then((_) {});

void main() {
  test('the first observation records the zone without a change event', () async {
    final h = await _harness();
    addTearDown(h.dispose);
    final tracker = h.read(zoneTrackerProvider);
    final events = <TimeZoneChanged>[];
    tracker.changes.listen(events.add);
    await _idle(tracker);
    expect(events, isEmpty);
    expect((await h.read(profileRepositoryProvider).read())!.currentTimeZone, 'Europe/Paris');
    expect(tracker.prompt.value, isNull);
  });

  test('travel emits TimeZoneChanged, records the zone and asks about home', () async {
    final h = await _harness();
    addTearDown(h.dispose);
    final tracker = h.read(zoneTrackerProvider);
    await _idle(tracker);
    final events = <TimeZoneChanged>[];
    tracker.changes.listen(events.add);

    h.clock.advance(const Duration(hours: 9)); // the flight
    h.container.read(deviceZoneProvider.notifier).debugSet('America/New_York');
    await _idle(tracker);
    expect(events, [TimeZoneChanged(from: 'Europe/Paris', to: 'America/New_York', at: h.clock.nowUtc())]);
    expect(tracker.prompt.value, 'America/New_York');
    expect(h.read(zonePromptProvider), 'America/New_York');

    // Back home within the throttle window: event, prompt cleared, write deferred then flushed.
    h.clock.advance(const Duration(minutes: 2));
    h.container.read(deviceZoneProvider.notifier).debugSet('Europe/Paris');
    await _idle(tracker);
    expect(events.last.to, 'Europe/Paris');
    expect(tracker.prompt.value, isNull);
    expect((await h.read(profileRepositoryProvider).read())!.currentTimeZone, 'America/New_York');
    await tracker.flush();
    expect((await h.read(profileRepositoryProvider).read())!.currentTimeZone, 'Europe/Paris');
  });

  test('answers: "make it home" updates the profile; "keep" is remembered for that zone', () async {
    final h = await _harness();
    addTearDown(h.dispose);
    final tracker = h.read(zoneTrackerProvider);
    await _idle(tracker);
    h.container.read(deviceZoneProvider.notifier).debugSet('Asia/Tokyo');
    await _idle(tracker);
    await tracker.answerPrompt(makeHome: false);
    expect(tracker.prompt.value, isNull);
    expect((await h.read(profileRepositoryProvider).read())!.homeTimeZone, 'Europe/Paris');

    h.container.read(deviceZoneProvider.notifier).debugSet('Europe/Paris');
    await _idle(tracker);
    h.container.read(deviceZoneProvider.notifier).debugSet('Asia/Tokyo');
    await _idle(tracker);
    expect(tracker.prompt.value, isNull, reason: 'already answered for Tokyo');

    h.container.read(deviceZoneProvider.notifier).debugSet('Africa/Tunis');
    await _idle(tracker);
    await tracker.answerPrompt(makeHome: true);
    expect((await h.read(profileRepositoryProvider).read())!.homeTimeZone, 'Africa/Tunis');
  });

  test("another device's zone in the shared profile is not a change for this device", () async {
    final h = await _harness();
    addTearDown(h.dispose);
    final tracker = h.read(zoneTrackerProvider);
    await _idle(tracker);
    final events = <TimeZoneChanged>[];
    tracker.changes.listen(events.add);
    // Another device (e.g. pulled) wrote its own zone.
    await h.read(profileRepositoryProvider).update(currentTimeZone: 'Asia/Dubai');
    h.clock.advance(const Duration(minutes: 11));
    await tracker.observe('Europe/Paris');
    expect(events, isEmpty);
    expect((await h.read(profileRepositoryProvider).read())!.currentTimeZone, 'Europe/Paris');
  });

  testWidgets('the banner offers to make the new zone home', (tester) async {
    final h = await tester.runAsync(_harness);
    await pumpInApp(
      tester,
      h!,
      SessionBannerHost(
        onOpen: (_) {},
        child: const Scaffold(body: Text('page')),
      ),
    );
    await settle(tester);
    expect(find.byKey(const ValueKey('banner-zone')), findsNothing);
    h.container.read(deviceZoneProvider.notifier).debugSet('America/New_York');
    await settle(tester);
    expect(find.byKey(const ValueKey('banner-zone')), findsOneWidget);
    expect(find.textContaining('New York'), findsWidgets);
    expect(find.text('Keep Paris'), findsOneWidget);
    await tester.tap(find.text('Make it home'));
    await settle(tester);
    expect(find.byKey(const ValueKey('banner-zone')), findsNothing);
    final p = await tester.runAsync(() => h.read(profileRepositoryProvider).read());
    expect(p!.homeTimeZone, 'America/New_York');
    expect(find.text('page'), findsOneWidget);
    await finish(tester, h);
  });
}

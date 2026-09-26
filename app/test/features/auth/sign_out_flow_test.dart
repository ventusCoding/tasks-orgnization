import 'package:everslot/core/providers.dart';
import 'package:everslot/core/session/session.dart';
import 'package:everslot/features/auth/presentation/sign_out_flow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';
import 'support/cloud_sync_harness.dart';
import 'support/widget_helpers.dart';

class _Host extends ConsumerWidget {
  const _Host();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: Center(
      child: TextButton(onPressed: () => runSignOutFlow(context, ref), child: const Text('go')),
    ),
  );
}

void main() {
  testWidgets('offline with unsynced changes: warn with the count, then sign out anyway', (tester) async {
    final d = (await tester.runAsync(CloudDevice.create))!;
    d.api.offline = true;
    await tester.runAsync(() => d.addCategory('c1', 'Work'));
    await pumpInApp(tester, d.h, const _Host());
    await settle(tester);

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await settle(tester, rounds: 10);
    expect(find.textContaining("1 change hasn't synced yet"), findsOneWidget);
    expect(d.h.read(sessionProvider), isNotNull);

    await tester.tap(find.byKey(const ValueKey('sign-out-anyway')));
    await settle(tester, rounds: 10);
    expect(d.h.read(sessionProvider), isNull);
    expect(await tester.runAsync(() => d.count('categories')), 0);
    expect(find.text('Signed out'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(d.dispose);
  });

  testWidgets('guests are warned that signing out deletes the account', (tester) async {
    final d = (await tester.runAsync(CloudDevice.create))!;
    d.h.read(sessionProvider.notifier).set(const AppSession(userId: 'u1', mode: SessionMode.cloud, isAnonymous: true));
    await pumpInApp(tester, d.h, const _Host());
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.textContaining('This guest account only exists on this device'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(d.h.read(sessionProvider), isNotNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(d.dispose);
  });
}

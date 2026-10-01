import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// T1.3.10: interactive behaviour of the core controls (buttons, search, segmented, swipe rows,
/// avatar, badge, sheet scaffold), in LTR and RTL.
void main() {
  Future<void> pump(WidgetTester tester, Widget child, {bool rtl = false}) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: Locale(rtl ? 'ar' : 'en'),
      supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
      localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
      home: Scaffold(body: child),
    ),
  );

  group('AppButton', () {
    testWidgets('every variant taps and is at least 48 dp tall', (tester) async {
      for (final v in AppButtonVariant.values) {
        var taps = 0;
        await pump(
          tester,
          Center(
            child: AppButton(label: 'Go ${v.name}', icon: Icons.add, variant: v, onPressed: () => taps++),
          ),
        );
        await tester.tap(find.text('Go ${v.name}'));
        expect(taps, 1, reason: v.name);
        expect(tester.getSize(find.byType(AppButton)).height, greaterThanOrEqualTo(48), reason: v.name);
      }
    });

    testWidgets('busy shows a spinner and ignores taps', (tester) async {
      var taps = 0;
      await pump(
        tester,
        Center(
          child: AppButton(label: 'Save', busy: true, onPressed: () => taps++),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(AppButton));
      expect(taps, 0);
      expect(find.bySemanticsLabel('Save'), findsOneWidget);
    });

    testWidgets('expand fills the width', (tester) async {
      await pump(tester, AppButton(label: 'Wide', expand: true, onPressed: () {}));
      expect(
        tester.getSize(find.byType(AppButton)).width,
        tester.view.physicalSize.width / tester.view.devicePixelRatio,
      );
    });
  });

  testWidgets('AppIconButton exposes its tooltip and caps the badge at 99+', (tester) async {
    await pump(tester, AppIconButton(icon: Icons.inbox, tooltip: 'Inbox', badge: 120, onPressed: () {}));
    expect(find.byTooltip('Inbox'), findsOneWidget);
    expect(find.text('99+'), findsOneWidget);
    await pump(tester, AppIconButton(icon: Icons.inbox, tooltip: 'Inbox', badge: 0, onPressed: () {}));
    expect(find.byType(Badge), findsNothing);
  });

  testWidgets('AppSearchField reports changes and clears', (tester) async {
    final values = <String>[];
    await pump(tester, AppSearchField(onChanged: values.add));
    expect(find.byTooltip('Clear'), findsNothing);
    await tester.enterText(find.byType(TextField), 'milk');
    await tester.pump();
    await tester.tap(find.byTooltip('Clear'));
    await tester.pump();
    expect(values, ['milk', '']);
    expect(find.text('milk'), findsNothing);
  });

  testWidgets('AppSegmented selects one value', (tester) async {
    var selected = 'day';
    await pump(
      tester,
      StatefulBuilder(
        builder: (context, setState) => AppSegmented<String>(
          segments: const [('day', 'Day', null), ('week', 'Week', Icons.view_week)],
          selected: selected,
          onChanged: (v) => setState(() => selected = v),
        ),
      ),
    );
    await tester.tap(find.text('Week'));
    await tester.pump();
    expect(selected, 'week');
  });

  group('SwipeRow', () {
    Widget row(List<String> log) => ListView(
      children: [
        SwipeRow(
          id: 'r1',
          start: RowSwipeAction(
            label: 'Done',
            icon: Icons.check,
            color: Colors.green,
            onTriggered: () {
              log.add('start');
              return false;
            },
          ),
          end: RowSwipeAction(
            label: 'Delete',
            icon: Icons.delete,
            color: Colors.red,
            onTriggered: () {
              log.add('end');
              return true;
            },
          ),
          child: const ListTile(title: Text('Row')),
        ),
      ],
    );

    for (final rtl in [false, true]) {
      testWidgets('swipe directions follow the reading direction (rtl: $rtl)', (tester) async {
        final log = <String>[];
        await pump(tester, row(log), rtl: rtl);
        // Swipe towards the reading end = the "start" action.
        await tester.drag(find.text('Row'), Offset(rtl ? -500 : 500, 0));
        await tester.pumpAndSettle();
        expect(log, ['start']);
        expect(find.text('Row'), findsOneWidget, reason: 'false snaps back');
        await tester.drag(find.text('Row'), Offset(rtl ? 500 : -500, 0));
        await tester.pumpAndSettle();
        expect(log, ['start', 'end']);
        expect(find.text('Row'), findsNothing, reason: 'true dismisses');
      });
    }

    testWidgets('actions are reachable through semantics', (tester) async {
      final handle = tester.ensureSemantics();
      final log = <String>[];
      await pump(tester, row(log));
      final node = tester.getSemantics(find.byType(SwipeRow));
      final ids = node.getSemanticsData().customSemanticsActionIds!;
      expect(ids, hasLength(2));
      for (final id in ids) {
        tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
          node.id,
          SemanticsAction.customAction,
          id,
        );
      }
      await tester.pump();
      expect(log, unorderedEquals(['start', 'end']));
      handle.dispose();
    });
  });

  test('AppAvatar initials', () {
    expect(AppAvatar.initials('Anwer Baccar'), 'AB');
    expect(AppAvatar.initials('me@example.com'), 'ME');
    expect(AppAvatar.initials('سارة علي'), 'سع');
    expect(AppAvatar.initials(null), '?');
  });

  testWidgets('AppAvatar exposes the name, CountBadge hides at zero', (tester) async {
    await pump(
      tester,
      const Row(
        children: [
          AppAvatar(name: 'Sam Lee'),
          CountBadge(0),
          CountBadge(7),
        ],
      ),
    );
    expect(find.text('SL'), findsOneWidget);
    expect(find.bySemanticsLabel('Sam Lee'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('SheetScaffold keeps actions visible above the keyboard', (tester) async {
    await pump(
      tester,
      Align(
        alignment: Alignment.bottomCenter,
        child: SheetScaffold(
          actions: [AppButton(label: 'Apply', onPressed: () {})],
          child: Column(children: [for (var i = 0; i < 40; i++) Text('Line $i')]),
        ),
      ),
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    final bottom = tester.getBottomLeft(find.text('Apply')).dy;
    final keyboardTop = (tester.view.physicalSize.height - 300) / tester.view.devicePixelRatio;
    expect(bottom, lessThanOrEqualTo(keyboardTop));
  });
}

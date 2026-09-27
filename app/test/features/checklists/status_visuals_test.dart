// Status visuals & accessibility (T4.3.04): statuses never rely on color alone, pill text keeps
// ≥ 4.5:1 contrast in both themes at every escalation level, completed rows are struck through and
// cancelled rows are struck through and muted.
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/presentation/checklist_screen.dart';
import 'package:everslot/features/checklists/presentation/markdown_lite.dart';
import 'package:everslot/features/checklists/presentation/status_visuals.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';
import 'status_gallery_support.dart';

void main() {
  test('every status has its own icon and label (never color alone)', () {
    expect({for (final s in ItemStatus.values) StatusStyle.icon(s)}, hasLength(ItemStatus.values.length));
  });

  for (final dark in [false, true]) {
    testWidgets('status pills keep text contrast ≥ 4.5:1 (${dark ? 'dark' : 'light'}, all ages)', (tester) async {
      final handle = tester.ensureSemantics();
      final now = DateTime.utc(2026, 9, 22, 9);
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.dark() : AppTheme.light(),
          supportedLocales: const [Locale('en')],
          localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
          home: Scaffold(
            body: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in ItemStatus.values)
                  for (final age in const [Duration(hours: 2), Duration(days: 4), Duration(days: 9)]) ...[
                    ItemStatusPill(status: s, since: now.subtract(age), now: now),
                    ItemStatusPill(status: s, since: now.subtract(age), now: now, dense: false),
                  ],
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  }

  testWidgets('preview rows: completed struck through, cancelled struck through and muted; labelled controls', (
    tester,
  ) async {
    final h = TestHarness.create(now: galleryNow);
    addTearDown(h.dispose);
    final id = await seedStatusGallery(tester, h);
    await pumpGallery(tester, h, ChecklistScreen(checklistId: id, preview: true));

    TextStyle styleOf(String text) =>
        tester.widget<MarkdownLite>(find.byWidgetPredicate((w) => w is MarkdownLite && w.text == text)).style!;
    final colors = Theme.of(tester.element(find.byType(ChecklistScreen))).colorScheme;
    final paid = styleOf('Pay deposit');
    expect(paid.decoration, TextDecoration.lineThrough);
    expect(paid.color, colors.onSurfaceVariant, reason: 'completed stays readable');
    final hotel = styleOf('Old hotel');
    expect(hotel.decoration, TextDecoration.lineThrough);
    expect(hotel.color!.a, lessThan(0.6), reason: 'cancelled is muted');
    expect(styleOf('Book flights').decoration, isNot(TextDecoration.lineThrough));

    // Pills carry the localized age; controls announce their status.
    expect(find.text('Waiting · 4 d'), findsOneWidget);
    expect(find.text('Blocked · 45 min'), findsOneWidget);
    expect(find.text('In progress · 2 h'), findsOneWidget);
    for (final label in ['To do', 'In progress', 'Waiting', 'Blocked', 'Completed', 'Cancelled']) {
      expect(find.bySemanticsLabel(RegExp('^$label')), findsWidgets, reason: label);
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Arabic pills localize the age and mirror', (tester) async {
    final h = TestHarness.create(now: galleryNow);
    addTearDown(h.dispose);
    final id = await seedStatusGallery(tester, h);
    await pumpGallery(tester, h, ChecklistScreen(checklistId: id, preview: true), rtl: true);
    final pill = find.byType(ItemStatusPill).first;
    expect(Directionality.of(tester.element(pill)), TextDirection.rtl);
    expect(
      find.descendant(of: find.byType(ItemStatusPill), matching: find.textContaining('·')),
      findsNWidgets(tester.widgetList(find.byType(ItemStatusPill)).length),
    );
    await tester.pumpWidget(const SizedBox());
  });
}

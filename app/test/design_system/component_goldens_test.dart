@Tags(['golden'])
library;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fonts.dart';

/// T1.3.10: goldens of the core components — buttons, icon button with badge, search field,
/// segmented control, chips, status pills, progress ring/bar, swipe row with avatar and badge,
/// empty and error states — in light/dark, LTR/RTL and at text scale 2.0.
void main() {
  setUpAll(loadAppFonts);

  const variants = [
    (dark: false, rtl: false, scale: 1.0),
    (dark: true, rtl: false, scale: 1.0),
    (dark: false, rtl: true, scale: 1.0),
    (dark: true, rtl: true, scale: 1.0),
    (dark: false, rtl: false, scale: 2.0),
  ];
  for (final v in variants) {
    final name = 'components_${v.dark ? 'dark' : 'light'}_${v.rtl ? 'rtl' : 'ltr'}_${v.scale.toInt()}x';
    testWidgets('golden $name', (tester) async {
      tester.view
        ..physicalSize = Size(420, v.scale == 1 ? 1180 : 2000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: v.dark ? ThemeMode.dark : ThemeMode.light,
          locale: Locale(v.rtl ? 'ar' : 'en'),
          supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
          localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(v.scale), disableAnimations: true),
            child: child!,
          ),
          home: const Scaffold(body: _Sheet()),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
    });
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.appColors;
    return ListView(
      padding: const EdgeInsets.all(Space.lg),
      children: [
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppButton(label: l.actionSave, icon: Icons.check, onPressed: () {}),
            AppButton(label: l.actionEdit, variant: AppButtonVariant.secondary, onPressed: () {}),
            AppButton(label: l.actionCancel, variant: AppButtonVariant.text, onPressed: () {}),
            AppButton(label: l.actionDelete, variant: AppButtonVariant.destructive, onPressed: () {}),
            AppButton(label: l.actionSave, busy: true, onPressed: () {}),
            AppIconButton(icon: Icons.inbox_outlined, tooltip: l.actionInbox, badge: 120, onPressed: () {}),
          ],
        ),
        const SizedBox(height: Space.md),
        AppSearchField(onChanged: (_) {}, initial: 'milk'),
        const SizedBox(height: Space.md),
        AppSegmented<int>(
          segments: [(0, l.actionToday, Icons.today), (1, l.tabPlan, null), (2, l.tabLists, null)],
          selected: 1,
          onChanged: (_) {},
        ),
        const SizedBox(height: Space.md),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            FilterChip(label: Text(l.tabHabits), selected: true, onSelected: (_) {}),
            ChoiceChip(label: Text(l.tabInsights), selected: false, onSelected: (_) {}),
            StatusPill(label: l.actionDone, color: c.completed, icon: Icons.check_circle),
            StatusPill(label: l.actionSkip, color: c.skipped, icon: Icons.redo),
          ],
        ),
        const SizedBox(height: Space.md),
        Row(
          children: [
            const ProgressRing(progress: 0.66, size: 48),
            const SizedBox(width: Space.md),
            Expanded(
              child: SegmentedBar(
                segments: [
                  BarSegment(3, c.completed, l.actionDone),
                  BarSegment(2, c.ongoing, l.tabPlan),
                  BarSegment(1, c.blocked, l.actionSkip),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.md),
        SwipeRow(
          id: 'r',
          end: RowSwipeAction(label: l.actionDelete, icon: Icons.delete, color: c.danger, onTriggered: () => false),
          child: ListTile(
            leading: AppAvatar(name: 'Sam Lee', colorArgb: CategoryPalette.at(0)),
            title: Text(l.gallerySampleText),
            subtitle: Text(l.gallerySwipeHint),
            trailing: const CountBadge(7),
          ),
        ),
        SizedBox(
          height: 180,
          child: EmptyState(icon: Icons.inbox_outlined, title: l.listsEmptyTitle),
        ),
      ],
    );
  }
}

import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/shared/filters/domain/entity_filter.dart';
import 'package:everslot/shared/filters/presentation/filter_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';

class _Host extends StatefulWidget {
  const _Host({required this.onValue});

  final ValueChanged<EntityFilter> onValue;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  EntityFilter _value = EntityFilter.empty;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: FilterBar(
      value: _value,
      fields: const [
        FilterField.category,
        FilterField.priority,
        FilterField.status,
        FilterField.recurring,
        FilterField.text,
      ],
      statusOptions: const [FilterOption('todo', 'To do'), FilterOption('waiting', 'Waiting')],
      onChanged: (v) {
        setState(() => _value = v);
        widget.onValue(v);
      },
    ),
  );
}

void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create());
  tearDown(() => h.dispose());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  /// Chips scroll horizontally: bring one into view before tapping it.
  Future<void> tapChip(WidgetTester tester, String label) async {
    final chip = find.widgetWithText(FilterChip, label);
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
  }

  testWidgets('select criteria, count them, remove one and clear all', (tester) async {
    await tester.runAsync(() => h.read(categoriesRepositoryProvider).create(name: 'Work', color: 0xFF3B82F6));
    var value = EntityFilter.empty;
    await pumpInApp(tester, h, _Host(onValue: (v) => value = v));
    await settle(tester);

    expect(find.bySemanticsLabel('No filters'), findsOneWidget);
    expect(find.text('Clear all'), findsNothing);

    // Priority: two values → "Priority · 2".
    await tapChip(tester, 'Priority');
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Urgent'));
    await tester.tap(find.widgetWithText(CheckboxListTile, 'High'));
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();
    expect(value.priorities, {3, 4});
    expect(find.widgetWithText(FilterChip, 'Priority · 2'), findsOneWidget);
    expect(find.bySemanticsLabel('1 filter active'), findsOneWidget);

    // Category: one value → "Category: Work".
    await tapChip(tester, 'Category');
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Work'));
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilterChip, 'Category: Work'), findsOneWidget);
    expect(find.bySemanticsLabel('2 filters active'), findsOneWidget);

    // Status options come from the host.
    await tapChip(tester, 'Status');
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Waiting'));
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();
    expect(value.statuses, {'waiting'});

    // Tri-state recurring.
    await tapChip(tester, 'Repeats');
    await tester.tap(find.text('One-off'));
    await tester.pumpAndSettle();
    expect(value.recurring, isFalse);
    expect(find.widgetWithText(FilterChip, 'One-off'), findsOneWidget);

    // Text criterion.
    await tapChip(tester, 'Text');
    await tester.enterText(find.byType(TextField), 'report');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(value.effectiveText, 'report');
    expect(value.activeCount, 5);

    // Removing one chip clears only that criterion.
    final clearCategory = find.byTooltip('Clear filter Category: Work');
    await tester.ensureVisible(clearCategory);
    await tester.pumpAndSettle();
    await tester.tap(clearCategory);
    await tester.pumpAndSettle();
    expect(value.categoryIds, isEmpty);
    expect(value.activeCount, 4);

    // "Clear all" is pinned (never scrolled away).
    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();
    expect(value, EntityFilter.empty);
    expect(find.bySemanticsLabel('No filters'), findsOneWidget);
  });

  testWidgets('works in Arabic (RTL) with localized chips', (tester) async {
    await pumpInApp(tester, h, _Host(onValue: (_) {}), locale: const Locale('ar'));
    await settle(tester);
    expect(find.widgetWithText(FilterChip, 'الفئة'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'الأولوية'), findsOneWidget);
    final first = tester.getRect(find.widgetWithText(FilterChip, 'الفئة'));
    final second = tester.getRect(find.widgetWithText(FilterChip, 'الأولوية'));
    // Chips flow from the right in RTL.
    expect(first.left, greaterThan(second.left));
  });

  testWidgets('text scale 2.0 grows the bar instead of clipping it', (tester) async {
    await pumpInApp(
      tester,
      h,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
          child: _Host(onValue: (_) {}),
        ),
      ),
    );
    await settle(tester);
    // No overflow error was reported and the chip text is fully laid out.
    expect(tester.takeException(), isNull);
    final chip = tester.getRect(find.widgetWithText(FilterChip, 'Category'));
    final bar = tester.getRect(find.byType(FilterBar));
    expect(bar.height, greaterThanOrEqualTo(chip.height));
    expect(bar.top, lessThanOrEqualTo(chip.top));
    expect(bar.bottom, greaterThanOrEqualTo(chip.bottom));
  });
}

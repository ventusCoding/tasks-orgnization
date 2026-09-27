import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';

/// Clock of the status gallery: every age below is relative to it.
final galleryNow = DateTime.utc(2026, 9, 22, 9);

/// A list with one item per status (and a nested pair), statuses set at different times so the
/// pills show ages: ongoing 2 h, waiting 4 d (escalated), blocked 45 min, completed, cancelled.
Future<String> seedStatusGallery(WidgetTester tester, TestHarness h) async {
  late String id;
  await tester.runAsync(() async {
    id =
        (await h
                .read(checklistsRepositoryProvider)
                .create(
                  title: 'Trip to Lisbon',
                  items: const [
                    NodeSpec(text: 'Book flights'),
                    NodeSpec(text: 'Renew passport'),
                    NodeSpec(text: 'Visa appointment'),
                    NodeSpec(text: 'Car rental'),
                    NodeSpec(
                      text: 'Hotel',
                      children: [
                        NodeSpec(text: 'Pay deposit'),
                        NodeSpec(text: 'Old hotel'),
                      ],
                    ),
                  ],
                ))
            .id;
    final items = await h.read(checklistItemsRepositoryProvider).items(id);
    String idOf(String text) => items.firstWhere((i) => i.text == text).id;
    final service = h.read(checklistServiceProvider);
    Future<void> at(Duration ago, String text, ItemStatus to, {String? note}) async {
      h.clock.set(galleryNow.subtract(ago));
      await service.changeStatus(id, [idOf(text)], to, note: note);
    }

    await at(const Duration(hours: 2), 'Renew passport', ItemStatus.ongoing);
    await at(const Duration(days: 4), 'Visa appointment', ItemStatus.waiting, note: 'Embassy reply');
    await at(const Duration(minutes: 45), 'Car rental', ItemStatus.blocked, note: 'Card expired');
    await at(const Duration(hours: 1), 'Pay deposit', ItemStatus.completed);
    await at(const Duration(days: 1), 'Old hotel', ItemStatus.cancelled);
    h.clock.set(galleryNow);
  });
  return id;
}

/// Pumps [child] with the app themes, [rtl] Arabic or English, the given text scale and reduced
/// motion, then lets the database streams deliver (no pumpAndSettle: nothing may tick forever).
Future<void> pumpGallery(
  WidgetTester tester,
  TestHarness h,
  Widget child, {
  bool dark = false,
  bool rtl = false,
  double scale = 1,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: h.container,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        locale: Locale(rtl ? 'ar' : 'en'),
        supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
        localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
            child: child,
          ),
        ),
      ),
    ),
  );
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

import 'dart:async';
import 'dart:io';

import 'package:everslot/core/errors/app_exception.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// T1.3.05: every error renders a localized message (EN/FR/AR), never raw exception text.
void main() {
  const locales = [Locale('en'), Locale('fr'), Locale('ar')];

  Future<void> pumpWith(WidgetTester tester, Widget child, Locale locale) =>
      tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: locales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: Scaffold(body: child),
        ),
      );

  String Function(AppLocalizations) expected(AppErrorKind kind) =>
      switch (kind) {
        AppErrorKind.network => (l) => l.errorNetwork,
        AppErrorKind.auth => (l) => l.errorAuth,
        AppErrorKind.validation => (l) => l.errorValidation,
        AppErrorKind.conflict => (l) => l.errorConflict,
        AppErrorKind.storage => (l) => l.errorStorage,
        AppErrorKind.permission => (l) => l.errorPermission,
        AppErrorKind.notFound => (l) => l.errorNotFound,
        AppErrorKind.unsupportedVersion => (l) => l.errorUnsupportedVersion,
        AppErrorKind.notConfigured => (l) => l.errorNotConfigured,
        AppErrorKind.unknown => (l) => l.stateErrorBody,
      };

  const byKind = <AppErrorKind, AppException>{
    AppErrorKind.network: NetworkException('offline'),
    AppErrorKind.auth: AuthException('expired'),
    AppErrorKind.validation: ValidationException('bad title', field: 'title'),
    AppErrorKind.conflict: ConflictException('edited elsewhere'),
    AppErrorKind.storage: StorageException('disk full'),
    AppErrorKind.permission: PermissionException('denied'),
    AppErrorKind.notFound: NotFoundException('gone'),
    AppErrorKind.unsupportedVersion: UnsupportedVersionException('too old'),
    AppErrorKind.notConfigured: NotConfiguredException('no backend'),
    AppErrorKind.unknown: UnknownAppException('who knows'),
  };

  for (final locale in locales) {
    testWidgets(
      '${locale.languageCode}: every AppException kind shows its localized message',
      (tester) async {
        expect(
          byKind.keys.toSet(),
          AppErrorKind.values.toSet(),
          reason: 'a new kind needs a message and a case here',
        );
        for (final e in byKind.entries) {
          await pumpWith(tester, ErrorState(error: e.value), locale);
          final l = lookupAppLocalizations(locale);
          final message = expected(e.key)(l);
          expect(message, isNotEmpty);
          expect(
            find.text(message),
            findsOneWidget,
            reason: '${e.key} in ${locale.languageCode}',
          );
          expect(find.text(l.stateErrorTitle), findsOneWidget);
          expect(find.textContaining('Exception'), findsNothing);
        }
      },
    );
  }

  testWidgets(
    'foreign exceptions are mapped: no raw exception text reaches the user',
    (tester) async {
      for (final e in <Object>[
        const SocketException('Failed host lookup: x.supabase.co'),
        TimeoutException('slow'),
        StateError('secret detail'),
      ]) {
        await pumpWith(tester, ErrorState(error: e), const Locale('en'));
        expect(find.textContaining('supabase.co'), findsNothing);
        expect(find.textContaining('secret detail'), findsNothing);
        expect(find.textContaining('StateError'), findsNothing);
      }
      await pumpWith(
        tester,
        const ErrorState(error: SocketException('x')),
        const Locale('en'),
      );
      expect(
        find.text("Can't reach the server. Check your connection."),
        findsOneWidget,
      );
      await pumpWith(
        tester,
        ErrorState(error: StateError('x')),
        const Locale('en'),
      );
      expect(find.text('Please try again.'), findsOneWidget);
    },
  );

  testWidgets('a null error and the retry action', (tester) async {
    var retries = 0;
    await pumpWith(
      tester,
      ErrorState(onRetry: () => retries++),
      const Locale('fr'),
    );
    expect(find.text('Réessayer'), findsOneWidget);
    await tester.tap(find.text('Réessayer'));
    expect(retries, 1);
  });

  group('FriendlyErrorWidget (release-mode ErrorWidget.builder)', () {
    // The test binding verifies `ErrorWidget.builder` right after the test body (before tearDown
    // callbacks run), so every test restores it in a `finally` inside its own body.
    testWidgets(
      'a widget that fails to build is replaced by a localized placeholder; siblings keep working',
      (tester) async {
        final old = ErrorWidget.builder;
        try {
          FriendlyErrorWidget.install(force: true);
          await pumpWith(
            tester,
            Column(
              children: [
                const Text('still here'),
                Builder(builder: (_) => throw StateError('build failed')),
              ],
            ),
            const Locale('ar'),
          );
          expect(tester.takeException(), isA<StateError>());
          expect(
            find.text(
              lookupAppLocalizations(const Locale('ar')).errorWidgetFallback,
            ),
            findsOneWidget,
          );
          expect(find.text('still here'), findsOneWidget);
          expect(find.byType(FriendlyErrorWidget), findsOneWidget);
        } finally {
          ErrorWidget.builder = old;
        }
      },
    );

    testWidgets('without localizations above it falls back to English', (
      tester,
    ) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: FriendlyErrorWidget(),
        ),
      );
      expect(find.text("This part couldn't be shown."), findsOneWidget);
    });

    testWidgets('install() is a no-op outside release builds unless forced', (
      tester,
    ) async {
      final old = ErrorWidget.builder;
      try {
        FriendlyErrorWidget.install();
        expect(identical(ErrorWidget.builder, old), isTrue);
        FriendlyErrorWidget.install(force: true);
        expect(identical(ErrorWidget.builder, old), isFalse);
        expect(
          ErrorWidget.builder(FlutterErrorDetails(exception: StateError('x'))),
          isA<FriendlyErrorWidget>(),
        );
      } finally {
        ErrorWidget.builder = old;
      }
    });
  });
}

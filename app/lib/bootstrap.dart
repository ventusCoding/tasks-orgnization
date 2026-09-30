import 'dart:async';

import 'package:everslot/app/app.dart';
import 'package:everslot/core/env/env.dart';
import 'package:everslot/core/errors/global_error_handlers.dart';
import 'package:everslot/startup/bootstrap_error_app.dart';
import 'package:everslot/startup/bootstrap_platform.dart';
import 'package:everslot/startup/bootstrap_runner.dart';
import 'package:everslot/startup/bootstrap_steps.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App startup (T1.3.02). The ordered steps live in [defaultBootstrapSteps] (logging → env → time
/// zones → Firebase → Supabase → database → session → providers → startup tasks); everything runs
/// inside a guarded zone whose errors, like `FlutterError.onError` and `PlatformDispatcher.onError`,
/// go to one [GlobalErrorHandlers] (T1.3.05). A failing required step shows a recoverable error
/// screen instead of a blank app.
///
/// The native launch screen stays up until `runApp` is called with the first real UI, which only
/// happens once every step succeeded, so no half-initialised frame is ever drawn.
Future<void> bootstrap(
  Flavor flavor, {
  BootstrapPlatform platform = const RealBootstrapPlatform(),
  List<BootstrapStep>? steps,
  GlobalErrorHandlers? handlers,
}) {
  final errorHandlers = handlers ?? GlobalErrorHandlers();
  final done = Completer<void>();
  runZonedGuarded(
    () async {
      // Same zone as `runApp` (Flutter warns about zone mismatches).
      WidgetsFlutterBinding.ensureInitialized();
      errorHandlers.install();
      final context = BootstrapContext(
        flavor: flavor,
        platform: platform,
        handlers: errorHandlers,
      );
      await BootstrapLauncher(
        context,
        steps ?? defaultBootstrapSteps(),
      ).start();
      if (!done.isCompleted) done.complete();
    },
    (error, stack) {
      errorHandlers.handleZoneError(error, stack);
      if (!done.isCompleted) done.complete();
    },
  );
  return done.future;
}

/// Runs the steps, then launches the app — or the recoverable error screen.
class BootstrapLauncher {
  BootstrapLauncher(this.context, List<BootstrapStep> steps)
    : runner = BootstrapRunner(steps, context);

  final BootstrapContext context;
  final BootstrapRunner runner;

  /// Runs the sequence from step [from]; on failure shows [BootstrapErrorApp] whose retry runs it
  /// again from the failed step.
  Future<void> start({int from = 0}) async {
    final failure = await runner.run(from: from);
    if (failure == null) {
      context.platform.launch(
        UncontrolledProviderScope(
          container: context.container!,
          child: const EverslotApp(),
        ),
      );
      return;
    }
    context.platform.launch(
      BootstrapErrorApp(
        failure: failure,
        // Developers see what failed; prod users get the friendly message only.
        showDetails: context.flavor == Flavor.dev || kDebugMode,
        onRetry: () => start(from: failure.index),
      ),
    );
  }
}

import 'dart:async';

import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/env/env.dart';
import 'package:everslot/core/errors/global_error_handlers.dart';
import 'package:everslot/startup/bootstrap_platform.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

/// Mutable state the startup steps build up (T1.3.02). Reading a value before the step that
/// produces it ran is a programming error and throws with the missing step's name.
class BootstrapContext {
  BootstrapContext({
    required this.flavor,
    required this.platform,
    required this.handlers,
    Logger? log,
  }) : log = log ?? Logger('bootstrap');

  final Flavor flavor;
  final BootstrapPlatform platform;
  final GlobalErrorHandlers handlers;
  final Logger log;

  Env? _env;
  Env get env => _env ?? _missing('env');
  set env(Env value) => _env = value;

  /// Firebase initialised (push + Crashlytics available).
  bool firebaseReady = false;

  /// Supabase client, or null in local-only mode (not configured, or its init failed).
  SupabaseClient? supabase;

  AppDatabase? _db;
  AppDatabase get db => _db ?? _missing('database');
  set db(AppDatabase value) => _db = value;

  String? _deviceId;
  String get deviceId => _deviceId ?? _missing('database');
  set deviceId(String value) => _deviceId = value;

  int build = 1;

  ProviderContainer? container;

  Never _missing(String step) =>
      throw StateError('bootstrap step "$step" has not run yet');
}

typedef BootstrapAction = FutureOr<void> Function(BootstrapContext ctx);

/// One named unit of startup work.
class BootstrapStep {
  const BootstrapStep(this.name, this.run, {this.optional = false});

  final String name;
  final BootstrapAction run;

  /// A failing optional step is logged and skipped: the app starts without that capability
  /// (Firebase → no push/Crashlytics, Supabase → local-only mode).
  final bool optional;
}

/// The step that stopped startup.
class BootstrapFailure {
  const BootstrapFailure({
    required this.step,
    required this.index,
    required this.error,
    required this.stack,
  });

  final String step;

  /// Index into the step list: a retry resumes here.
  final int index;
  final Object error;
  final StackTrace stack;
}

/// Runs the startup steps in order (T1.3.02): a required step that throws stops the sequence and
/// is returned as a [BootstrapFailure] (the app then shows a recoverable error screen and
/// [run]s again from that step); an optional step that throws is logged and skipped.
class BootstrapRunner {
  BootstrapRunner(this.steps, this.context);

  final List<BootstrapStep> steps;
  final BootstrapContext context;

  /// Wall-clock time per finished step (cold-start budget: < 1.5 s on a mid-range phone).
  final timings = <String, Duration>{};

  /// Optional steps that failed.
  final skipped = <String>[];

  Future<BootstrapFailure?> run({int from = 0}) async {
    final log = context.log;
    final total = Stopwatch()..start();
    for (var i = from; i < steps.length; i++) {
      final step = steps[i];
      final watch = Stopwatch()..start();
      try {
        await step.run(context);
        timings[step.name] = watch.elapsed;
        skipped.remove(step.name);
      } on Object catch (e, st) {
        if (step.optional) {
          log.warning(
            'bootstrap step "${step.name}" failed (${e.runtimeType}) — continuing without it',
            e,
            st,
          );
          if (!skipped.contains(step.name)) skipped.add(step.name);
          continue;
        }
        log.severe('bootstrap step "${step.name}" failed', e, st);
        return BootstrapFailure(step: step.name, index: i, error: e, stack: st);
      }
    }
    log.info(
      'bootstrap finished in ${total.elapsedMilliseconds} ms '
      '(${timings.entries.map((e) => '${e.key} ${e.value.inMilliseconds}').join(', ')})',
    );
    return null;
  }
}

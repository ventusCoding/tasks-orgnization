import 'package:everslot/bootstrap.dart';
import 'package:everslot/core/env/env.dart';

/// Default entrypoint (dev flavor). Prefer `main_dev.dart` / `main_prod.dart` with flavors.
Future<void> main() => bootstrap(Flavor.dev);

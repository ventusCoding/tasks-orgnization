import 'package:local_auth/local_auth.dart';

/// Device authentication for the app lock (T8.3.09); faked in tests.
abstract interface class Authenticator {
  /// Biometrics or a device credential (PIN / pattern / password) are set up.
  Future<bool> isSupported();

  /// Shows the system prompt; true when the user authenticated.
  Future<bool> authenticate(String reason);
}

class LocalAuthAuthenticator implements Authenticator {
  final _auth = LocalAuthentication();

  @override
  Future<bool> isSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      // Biometrics or the device credential: accessible to people who can't use biometrics.
      return await _auth.authenticate(localizedReason: reason, persistAcrossBackgrounding: true);
    } on Object {
      return false;
    }
  }
}

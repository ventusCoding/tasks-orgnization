package app.everslot

import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity is required by local_auth (biometric app lock, T8.3.09).
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Alarm profile (T7.2.24): full-screen permission state and lock-screen display while an
        // alarm rings. The app is shown above the lock screen only between showOnLockScreen(true)
        // and showOnLockScreen(false) — never otherwise.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.everslot/alarm").setMethodCallHandler { call, result ->
            when (call.method) {
                "canUseFullScreenIntent" -> {
                    val allowed = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                        (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).canUseFullScreenIntent()
                    } else {
                        true
                    }
                    result.success(allowed)
                }
                "showOnLockScreen" -> {
                    val on = call.arguments as? Boolean ?: false
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                        setShowWhenLocked(on)
                        setTurnScreenOn(on)
                    } else {
                        @Suppress("DEPRECATION")
                        val flags = WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                        if (on) window.addFlags(flags) else window.clearFlags(flags)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        // App lock / app-switcher privacy (T8.3.09): FLAG_SECURE blanks the recents snapshot and
        // blocks screenshots while the setting is on.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.everslot/privacy").setMethodCallHandler { call, result ->
            when (call.method) {
                "setSecure" -> {
                    if (call.arguments == true) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}

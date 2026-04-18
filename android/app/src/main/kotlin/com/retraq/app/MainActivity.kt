package com.retraq.app

import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.retraq.app/flag_secure"

    private var onDeviceAiChannel: OnDeviceAiChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "addFlagSecure" -> {
                    window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(null)
                }
                "clearFlagSecure" -> {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Opt-in on-device AI (Gemini Nano) bridge for the weekly recap.
        onDeviceAiChannel = OnDeviceAiChannel(flutterEngine)
    }

    override fun onDestroy() {
        onDeviceAiChannel?.dispose()
        onDeviceAiChannel = null
        super.onDestroy()
    }
}

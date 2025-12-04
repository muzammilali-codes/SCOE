package com.example.scoe

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.content.pm.PackageManager

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "open.app.channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openApp") {
                val packageName = call.argument<String>("packageName")
                try {
                    val intent = packageManager.getLaunchIntentForPackage(packageName!!)
                    if (intent != null) {
                        startActivity(intent)
                        result.success(true)
                    } else {
                        result.error("UNAVAILABLE", "App not found", null)
                    }
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }
        }
    }
}

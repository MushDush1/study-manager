package com.example.study_manager

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "study_manager/app_jumper"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "openPackage") {
                    val packageName = call.argument<String>("package")
                    if (packageName.isNullOrBlank()) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    result.success(openPackage(packageName))
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun openPackage(packageName: String): Boolean {
        val launch = packageManager.getLaunchIntentForPackage(packageName)
        if (launch != null) {
            launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(launch)
            return true
        }
        return try {
            val market = Intent(
                Intent.ACTION_VIEW,
                Uri.parse("market://details?id=$packageName"),
            )
            market.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(market)
            true
        } catch (_: ActivityNotFoundException) {
            false
        }
    }
}

package com.singula.app

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "singula/launcher"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "launch") {
                    val url = call.argument<String>("url") ?: ""
                    val success = launchUrl(url)
                    result.success(success)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun launchUrl(url: String): Boolean {
        return try {
            val uri = Uri.parse(url)

            // Пробуем запустить как приложение
            if (url.startsWith("android-app://")) {
                val packageName = url.removePrefix("android-app://")
                val intent = packageManager.getLaunchIntentForPackage(packageName)
                if (intent != null) {
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    return true
                }
                // Приложение не установлено — открываем в Play Market
                val marketIntent = Intent(Intent.ACTION_VIEW,
                    Uri.parse("market://details?id=$packageName"))
                marketIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(marketIntent)
                return true
            }

            // YouTube deep link
            if (url.startsWith("vnd.youtube://")) {
                val ytIntent = Intent(Intent.ACTION_VIEW, uri)
                ytIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(ytIntent)
                return true
            }

            // Телефон
            if (url.startsWith("tel:")) {
                val intent = Intent(Intent.ACTION_DIAL, uri)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                return true
            }

            // СМС
            if (url.startsWith("sms:")) {
                val intent = Intent(Intent.ACTION_VIEW, uri)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                return true
            }

            // Обычный URL — в браузере
            val intent = Intent(Intent.ACTION_VIEW, uri)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }
}

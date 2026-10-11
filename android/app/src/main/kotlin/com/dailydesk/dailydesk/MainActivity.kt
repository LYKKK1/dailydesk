package com.dailydesk.dailydesk

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingNotificationPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestNotificationPermission" -> {
                    requestNotificationPermission(result)
                }

                "start" -> {
                    val startedAtMillis =
                        call.argument<Number>("startedAtMillis")?.toLong()
                    if (startedAtMillis == null) {
                        result.error(
                            "invalid_arguments",
                            "startedAtMillis is required",
                            null,
                        )
                        return@setMethodCallHandler
                    }
                    PomodoroForegroundService.start(
                        context = this,
                        title = call.argument<String>("title") ?: "DailyDesk",
                        body = call.argument<String>("body") ?: "Pomodoro in progress",
                        startedAtMillis = startedAtMillis,
                        endAtMillis = call.argument<Number>("endAtMillis")?.toLong(),
                        countDown = call.argument<Boolean>("countDown") ?: false,
                    )
                    result.success(null)
                }

                "stop" -> {
                    PomodoroForegroundService.stop(this)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != NOTIFICATION_PERMISSION_REQUEST_CODE) {
            return
        }

        val granted = grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
        pendingNotificationPermissionResult?.success(granted)
        pendingNotificationPermissionResult = null
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }

        if (pendingNotificationPermissionResult != null) {
            result.error(
                "permission_request_in_progress",
                "Notification permission request is already in progress",
                null,
            )
            return
        }

        pendingNotificationPermissionResult = result
        requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            NOTIFICATION_PERMISSION_REQUEST_CODE,
        )
    }

    companion object {
        const val CHANNEL_NAME = "dailydesk/pomodoro_service"
        private const val NOTIFICATION_PERMISSION_REQUEST_CODE = 4102
    }
}

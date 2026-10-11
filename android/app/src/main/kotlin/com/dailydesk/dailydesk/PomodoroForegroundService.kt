package com.dailydesk.dailydesk

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder

class PomodoroForegroundService : Service() {
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_START) {
            val title = intent.getStringExtra(EXTRA_TITLE) ?: "DailyDesk"
            val body =
                intent.getStringExtra(EXTRA_BODY) ?: "Pomodoro in progress"
            val startedAtMillis =
                intent.getLongExtra(EXTRA_STARTED_AT_MILLIS, System.currentTimeMillis())
            val endAtMillis =
                if (intent.hasExtra(EXTRA_END_AT_MILLIS)) {
                    intent.getLongExtra(EXTRA_END_AT_MILLIS, 0L)
                } else {
                    null
                }
            val countDown = intent.getBooleanExtra(EXTRA_COUNT_DOWN, false)
            startForegroundNotification(
                buildNotification(
                    title = title,
                    body = body,
                    startedAtMillis = startedAtMillis,
                    endAtMillis = endAtMillis,
                    countDown = countDown,
                ),
            )
        }
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        val manager = getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Pomodoro timer",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Keeps a running Pomodoro timer alive"
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
    }

    private fun buildNotification(
        title: String,
        body: String,
        startedAtMillis: Long,
        endAtMillis: Long?,
        countDown: Boolean,
    ): Notification {
        val pendingIntentFlags =
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        val launchIntent =
            packageManager.getLaunchIntentForPackage(packageName)
                ?: Intent(this, MainActivity::class.java)
        val contentIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            pendingIntentFlags,
        )
        val chronometerCountDown = countDown && endAtMillis != null
        val notificationWhen = if (chronometerCountDown) {
            endAtMillis!!
        } else {
            startedAtMillis
        }

        return Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_pomodoro)
            .setContentTitle(title)
            .setContentText(body)
            .setContentIntent(contentIntent)
            .setCategory(Notification.CATEGORY_STOPWATCH)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setWhen(notificationWhen)
            .setUsesChronometer(true)
            .setChronometerCountDown(chronometerCountDown)
            .build()
    }

    private fun startForegroundNotification(notification: Notification) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    companion object {
        private const val CHANNEL_ID = "dailydesk_pomodoro"
        private const val NOTIFICATION_ID = 4101
        private const val ACTION_START =
            "com.dailydesk.dailydesk.action.START_POMODORO"
        private const val EXTRA_TITLE = "title"
        private const val EXTRA_BODY = "body"
        private const val EXTRA_STARTED_AT_MILLIS = "startedAtMillis"
        private const val EXTRA_END_AT_MILLIS = "endAtMillis"
        private const val EXTRA_COUNT_DOWN = "countDown"

        fun start(
            context: Context,
            title: String,
            body: String,
            startedAtMillis: Long,
            endAtMillis: Long?,
            countDown: Boolean,
        ) {
            val intent = Intent(context, PomodoroForegroundService::class.java)
                .setAction(ACTION_START)
                .putExtra(EXTRA_TITLE, title)
                .putExtra(EXTRA_BODY, body)
                .putExtra(EXTRA_STARTED_AT_MILLIS, startedAtMillis)
                .putExtra(EXTRA_COUNT_DOWN, countDown)
            if (endAtMillis != null) {
                intent.putExtra(EXTRA_END_AT_MILLIS, endAtMillis)
            }
            context.startForegroundService(intent)
        }

        fun stop(context: Context) {
            context.stopService(
                Intent(context, PomodoroForegroundService::class.java),
            )
        }
    }
}

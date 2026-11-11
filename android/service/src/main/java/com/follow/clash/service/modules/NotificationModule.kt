package com.follow.clash.service.modules

import android.app.Notification.FOREGROUND_SERVICE_IMMEDIATE
import android.app.Service
import android.app.Service.STOP_FOREGROUND_REMOVE
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import androidx.core.content.getSystemService
import com.follow.clash.common.Components
import com.follow.clash.common.GlobalState
import com.follow.clash.common.QuickAction
import com.follow.clash.common.ensureNotificationChannel
import com.follow.clash.common.quickIntent
import com.follow.clash.common.receiveBroadcastFlow
import com.follow.clash.common.startForeground
import com.follow.clash.common.toPendingIntent
import com.follow.clash.core.Core
import com.follow.clash.service.R
import com.follow.clash.service.ServiceConfig
import com.follow.clash.service.models.NotificationParams
import com.follow.clash.service.models.getSpeedTrafficText
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onStart
import kotlinx.coroutines.launch

private data class ExtendedNotificationParams(
    val title: String,
    val stopText: String,
    val showStopAction: Boolean,
    val contentText: String,
    val hidden: Boolean,
)

private val NotificationParams.extended: ExtendedNotificationParams
    get() = ExtendedNotificationParams(
        title,
        stopText,
        showStopAction,
        // A hidden notification is never read, and the speed costs a core call
        // to produce: skip it rather than compute a string nobody sees.
        if (hideNotification) "" else Core.getSpeedTrafficText(onlyStatisticsProxy),
        hideNotification,
    )

internal class NotificationModule(
    private val service: Service,
    private val scope: CoroutineScope,
) : ServiceModule {
    override fun start() {
        service.ensureNotificationChannel()
        update(ServiceConfig.notificationParams.value.extended)
        scope.launch {
            // Some ROMs, vivo's among them, drop updates posted behind the
            // keyguard, so unlocking restarts the loop to post once more.
            // SystemUI, an app, sends USER_PRESENT, which a receiver that is
            // not exported never gets; all three actions are protected.
            service.receiveBroadcastFlow(exported = true) {
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(Intent.ACTION_SCREEN_OFF)
                addAction(Intent.ACTION_USER_PRESENT)
            }.map { intent ->
                intent.action != Intent.ACTION_SCREEN_OFF
            }.onStart {
                emit(isScreenOn())
            }.collectLatest { screenOn ->
                if (!screenOn) return@collectLatest
                combine(
                    flow {
                        while (true) {
                            // A hidden notification shows no speed, so there is
                            // nothing to refresh. Parking the tick also matters
                            // on ROMs that let the user swipe a foreground
                            // notification away: re-posting it every second
                            // would bring it straight back. Parameter changes
                            // still arrive through the second flow below.
                            val hidden =
                                ServiceConfig.notificationParams.value.hideNotification
                            delay(if (hidden) 60_000 else 1_000)
                            if (hidden) continue
                            emit(Unit)
                        }
                    },
                    ServiceConfig.notificationParams,
                ) { _, params ->
                    params.extended
                }.distinctUntilChanged()
                    .collect(::update)
            }
        }
    }

    private fun isScreenOn() =
        service.getSystemService<PowerManager>()?.isInteractive ?: true

    private val notificationBuilder: NotificationCompat.Builder by lazy {
        builder(hidden = false)
    }

    // A separate builder, not a flag on the one above: the channel is fixed
    // when a builder is created, and moving a posted notification to another
    // channel means building it again.
    private val hiddenNotificationBuilder: NotificationCompat.Builder by lazy {
        builder(hidden = true)
    }

    private fun builder(hidden: Boolean): NotificationCompat.Builder {
        val intent = Intent().setComponent(Components.mainActivity)

        return NotificationCompat.Builder(
            service,
            if (hidden) {
                GlobalState.NOTIFICATION_CHANNEL_SILENT
            } else {
                GlobalState.NOTIFICATION_CHANNEL
            },
        ).apply {
            setSmallIcon(R.drawable.ic_service)
            setContentTitle("Skyward")
            setContentIntent(intent.toPendingIntent)
            setCategory(NotificationCompat.CATEGORY_SERVICE)
            setOngoing(true)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                foregroundServiceBehavior = FOREGROUND_SERVICE_IMMEDIATE
            }
            setOnlyAlertOnce(true)
            if (hidden) {
                // The channel is already IMPORTANCE_MIN; these cover what a
                // channel does not: no timestamp in the corner, nothing on the
                // lock screen, and the lowest priority for pre-Oreo devices,
                // which have no channels at all.
                setPriority(NotificationCompat.PRIORITY_MIN)
                setSilent(true)
                setShowWhen(false)
                setVisibility(NotificationCompat.VISIBILITY_SECRET)
            } else {
                setPriority(NotificationCompat.PRIORITY_LOW)
                setShowWhen(true)
            }
        }
    }

    private val stopIntent by lazy { QuickAction.STOP.quickIntent.toPendingIntent }

    private fun update(params: ExtendedNotificationParams) {
        val builder =
            if (params.hidden) hiddenNotificationBuilder else notificationBuilder
        service.startForeground(
      with(builder) {
        setContentTitle(params.title)
        setContentText(params.contentText.takeIf { it.isNotEmpty() })
        clearActions()
        if (params.showStopAction) {
          addAction(0, params.stopText, stopIntent)
        }
        build()
      },
    )
  }

    @Suppress("DEPRECATION")
    override fun stop() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            service.stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            service.stopForeground(true)
        }
    }
}

package com.follow.clash.service.models

data class NotificationParams(
    val title: String = "Skyward",
    val stopText: String = "STOP",
    val onlyStatisticsProxy: Boolean = false,
    val showStopAction: Boolean = true,
    // Keep the front-end notification out of sight. Android still demands one
    // from a foreground service, so this lowers it to a silent channel instead
    // of removing it; the service itself is untouched.
    val hideNotification: Boolean = false,
)

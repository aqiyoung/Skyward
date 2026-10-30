package com.follow.clash

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.os.Process
import androidx.core.content.pm.ShortcutManagerCompat
import com.follow.clash.common.GlobalState
import com.follow.clash.common.QuickAction
import com.follow.clash.common.action
import com.follow.clash.common.shortcutId
import kotlinx.coroutines.launch

class QuickActionActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handle(intent)
        finish()
    }

    // A caller that repeats an action before this instance is gone reaches it here, not onCreate.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handle(intent)
    }

    private fun handle(intent: Intent) {
        val action = QuickAction.entries.firstOrNull { it.action == intent.action } ?: return
        // Reject third-party apps: without this, any app on the device could
        // silently start/stop the VPN through the exported intent-filters.
        if (!isTrustedCaller()) return
        ShortcutManagerCompat.reportShortcutUsed(this, action.shortcutId)
        GlobalState.launch {
            when (action) {
                QuickAction.START -> ServiceState.handleStartAction()
                QuickAction.STOP -> ServiceState.handleStopAction()
                QuickAction.TOGGLE -> ServiceState.handleToggleAction()
            }
        }
    }

    /**
     * The only legitimate callers are the app itself (quick-settings tile,
     * notification/widget PendingIntents, in-app shortcuts) and the default
     * launcher (launcher shortcuts published via ShortcutManager).
     */
    private fun isTrustedCaller(): Boolean {
        // getLaunchedFromUid needs API 22+; minSdk is 23+, always available.
        val callerUid = launchedFromUid
        if (callerUid == Process.myUid()) return true
        return callerUid == defaultLauncherUid
    }

    private val defaultLauncherUid: Int
        get() {
            val homeIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
            val packageName = packageManager
                .resolveActivity(homeIntent, PackageManager.MATCH_DEFAULT_ONLY)
                ?.activityInfo?.packageName ?: return -1
            return try {
                packageManager.getApplicationInfo(packageName, 0).uid
            } catch (_: PackageManager.NameNotFoundException) {
                -1
            }
        }
}

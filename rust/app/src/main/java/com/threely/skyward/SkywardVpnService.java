package com.threely.skyward;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Intent;
import android.content.pm.ServiceInfo;
import android.net.VpnService;
import android.os.Build;
import android.os.ParcelFileDescriptor;
import java.io.IOException;

/**
 * 系统流量接管入口：建立 TUN，把 fd 交给 Rust 内核。
 *
 * 正式版相对 PoC 补了两件事：
 * 1. 前台服务 + 常驻通知——不带通知的 VPN 在 Android 12+ 会被系统随时回收，
 *    表现为「用几分钟自己断」；
 * 2. onRevoke 回调——用户在系统设置里撤销授权时主动收摊，避免留下半开的 TUN。
 */
public class SkywardVpnService extends VpnService {
    private static final String CH_ID = "skyward_vpn";
    private static final int NOTI_ID = 1001;

    private ParcelFileDescriptor mFd;

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (mFd != null) {
            // 重复启动：沿用已建立的 TUN，只刷新通知。
            startForegroundCompat();
            return START_STICKY;
        }

        try {
            Builder b = new Builder();
            b.setSession("Skyward");
            // 给 TUN 接口一个私有地址，避免与真实网卡冲突。
            b.addAddress("10.10.10.2", 24);
            // 接管全部 IPv4 流量（0.0.0.0/0）。
            b.addRoute("0.0.0.0", 0);
            b.addDnsServer("8.8.8.8");
            b.addDnsServer("1.1.1.1");
            // 自身流量不走隧道，否则内核出站会绕回自己形成环路。
            b.addDisallowedApplication(getPackageName());
            mFd = b.establish();
        } catch (Exception e) {
            stopSelf();
            return START_NOT_STICKY;
        }
        if (mFd == null) {
            stopSelf();
            return START_NOT_STICKY;
        }

        startForegroundCompat();

        // 把 fd 交给内核：内核从 fd 读原始 IP 帧，按 TCP / UDP / DNS 分流后经出站协议转发。
        AppState st = AppState.get();
        RustCore.nativeOpenTun(mFd.getFd(), st.ssServer, st.ssPort, st.ssPassword,
                st.outProtocol, st.outTls, st.outSni);
        return START_STICKY;
    }

    /** 前台服务 + 常驻通知；Android 14 起必须显式声明服务类型。 */
    private void startForegroundCompat() {
        NotificationManager nm = getSystemService(NotificationManager.class);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel ch = new NotificationChannel(
                    CH_ID, "连接状态", NotificationManager.IMPORTANCE_LOW);
            ch.setShowBadge(false);
            ch.setSound(null, null);
            nm.createNotificationChannel(ch);
        }

        AppState st = AppState.get();
        Intent open = new Intent(this, MainActivity.class);
        open.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
        PendingIntent pi = PendingIntent.getActivity(this, 0, open,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

        Notification.Builder nb = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
                ? new Notification.Builder(this, CH_ID)
                : new Notification.Builder(this);
        Notification n = nb
                .setContentTitle("Skyward 已连接")
                .setContentText(st.ssServer + ":" + st.ssPort + " · " + protoLabel(st.outProtocol))
                .setSmallIcon(R.drawable.ic_logo)
                .setContentIntent(pi)
                .setOngoing(true)
                .setShowWhen(false)
                .build();

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(NOTI_ID, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE);
        } else {
            startForeground(NOTI_ID, n);
        }
    }

    private static String protoLabel(String p) {
        if ("trojan".equals(p)) return "Trojan";
        if ("vless".equals(p)) return "VLESS";
        return "Shadowsocks";
    }

    /** 用户在系统设置里撤销 VPN 授权 / 其它 App 抢占 VPN 时回调。 */
    @Override
    public void onRevoke() {
        stopSelf();
    }

    @Override
    public void onDestroy() {
        RustCore.nativeCloseTun();
        if (mFd != null) {
            try {
                mFd.close();
            } catch (IOException ignored) {
            }
            mFd = null;
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE);
        } else {
            stopForeground(true);
        }
        super.onDestroy();
    }
}

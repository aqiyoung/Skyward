package com.threely.skyward.poc;

import android.net.VpnService;
import android.os.ParcelFileDescriptor;

/**
 * 无法用 Rust 省掉的几十行平台壳：Android 要求 VpnService 必须是
 * android.net.VpnService 的 Java 子类，并在 Manifest 声明。
 *
 * PoC-1 只保留最小可用骨架，不建立真实 VPN 会话、不接管流量，
 * 避免装机后误触导致断网。真实 tun2socks + tun fd 交给 Rust 是 PoC-2。
 */
public class SkywardVpnService extends VpnService {

    private ParcelFileDescriptor tun;

    /** 权限已由调用方通过 VpnService.prepare() 取得后才可调。 */
    public boolean establishTun() {
        Builder b = new Builder()
                .setSession("Skyward Rust PoC")
                .addAddress("10.233.233.2", 32)
                .addRoute("10.233.233.0", 24)
                .addDnsServer("1.1.1.1");
        tun = b.establish();
        return tun != null;
    }

    public int tunFd() {
        return tun == null ? -1 : tun.getFd();
    }

    @Override
    public void onDestroy() {
        if (tun != null) {
            try { tun.close(); } catch (Exception ignored) {}
            tun = null;
        }
        super.onDestroy();
    }
}

package com.threely.skyward.poc;

import android.content.Context;
import android.net.ConnectivityManager;
import android.net.LinkProperties;
import android.net.Network;
import android.net.RouteInfo;

import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * 服务连通性探测：只做 TCP 握手计时，不发 HTTP 请求。
 *
 * 原版仪表盘每个服务格显示的是延迟，不是「可达 / 不可达」的布尔值，
 * 所以这里量的是建连毫秒数。握手成功即认为可达，超时/拒绝都算失败。
 */
public final class NetProbe {

    public interface Cb {
        void onResult(int ms, boolean ok);
    }

    private NetProbe() {}

    private static final ExecutorService POOL = Executors.newFixedThreadPool(4);

    /** 后台线程探测，回调也在后台线程；调用方自行 post 回主线程。 */
    public static void probe(final String host, final int port, final int timeoutMs, final Cb cb) {
        if (host == null || host.isEmpty()) {
            if (cb != null) cb.onResult(0, false);
            return;
        }
        POOL.execute(new Runnable() {
            @Override public void run() {
                final long t0 = System.nanoTime();
                final boolean[] ok = {false};
                // DNS 解析发生在 InetSocketAddress 构造里，不受 connect 超时约束，
                // 一个坏的域名能把探测拖到十几秒。所以真正建连放到独立线程，
                // 这里只等它到点为止，保证格子里的读数按时出现。
                Thread worker = new Thread(new Runnable() {
                    @Override public void run() {
                        Socket s = new Socket();
                        try {
                            s.connect(new InetSocketAddress(host, port), timeoutMs);
                            ok[0] = true;
                        } catch (Throwable ignored) {
                            // 超时、拒绝、DNS 失败都归为不可达
                        } finally {
                            try { s.close(); } catch (Throwable ignored) {}
                        }
                    }
                }, "probe-" + host);
                worker.setDaemon(true);
                worker.start();
                try {
                    worker.join(timeoutMs + 300L);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
                int ms = (int) ((System.nanoTime() - t0) / 1000000L);
                if (cb != null) cb.onResult(ms, ok[0]);
            }
        });
    }

    /** 当前默认路由的网关地址；没有网络或拿不到时返回 null。 */
    public static String gateway(Context c) {
        try {
            ConnectivityManager cm =
                    (ConnectivityManager) c.getSystemService(Context.CONNECTIVITY_SERVICE);
            if (cm == null) return null;
            Network n = cm.getActiveNetwork();
            if (n == null) return null;
            LinkProperties lp = cm.getLinkProperties(n);
            if (lp == null) return null;
            for (RouteInfo r : lp.getRoutes()) {
                if (r.isDefaultRoute() && r.getGateway() != null) {
                    InetAddress g = r.getGateway();
                    if (!g.isAnyLocalAddress()) return g.getHostAddress();
                }
            }
        } catch (Throwable ignored) {
            // 权限或系统差异：交给调用方按「未连接」显示
        }
        return null;
    }
}

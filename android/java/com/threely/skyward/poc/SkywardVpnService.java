package com.threely.skyward.poc;

import android.net.VpnService;
import android.os.ParcelFileDescriptor;
import java.io.IOException;

/**
 * 系统流量接管：Android 上"接管设备层流量"的唯一入口是 VpnService。
 * 本服务建立 TUN 设备并把文件描述符（fd）交给 Rust 内核（nativeOpenTun），
 * 内核在独立线程里读取原始 IP 帧并解析 / 统计。
 *
 * 注意：VpnService 必须在真机（或带 VPN 框架的模拟器）上运行，沙箱无法验证；
 * 代码为标准 Android 实现，正确性不依赖内核数据面测试。
 */
public class SkywardVpnService extends VpnService {
    private ParcelFileDescriptor mFd;

    @Override
    public int onStartCommand(android.content.Intent intent, int flags, int startId) {
        try {
            Builder b = new Builder();
            b.setSession("Skyward");
            // 给 TUN 接口一个私有地址，避免与真实网卡冲突。
            b.addAddress("10.10.10.2", 24);
            // 接管全部 IPv4 流量（0.0.0.0/0）。
            b.addRoute("0.0.0.0", 0);
            b.addDnsServer("8.8.8.8");
            b.addDnsServer("1.1.1.1");
            mFd = b.establish();
        } catch (Exception e) {
            e.printStackTrace();
            stopSelf();
            return START_NOT_STICKY;
        }
        if (mFd == null) {
            stopSelf();
            return START_NOT_STICKY;
        }
        // 把 fd 交给内核：内核从 fd 读原始 IP 帧，按 TCP / DNS 分流后经 SS 出站转发。
        // 上游配置取用户已保存的那份；没填真实节点时连接会立刻收到 RST，不会静默挂死。
        AppState st = AppState.get();
        RustCore.nativeOpenTun(mFd.getFd(), st.ssServer, st.ssPort, st.ssPassword);
        return START_STICKY;
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
        super.onDestroy();
    }
}

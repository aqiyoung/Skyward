package com.threely.skyward.poc;

import java.util.Locale;

/**
 * UI 状态层。
 *
 * 数据分两类，界面上明确区分，避免把 PoC 演示成"能用的客户端"：
 *  - 内核真值：全部经 JNI 取自 Rust core（版本 / 规则数 / 内存 / 连接表 / 冷启动）。
 *  - 演示数据：产品结构占位（节点 / 配置 / 流量 / 开关），PoC 阶段未接入真实协议栈，
 *    仅用于把界面骨架与交互跑通。所有展示它的地方都标注"演示"。
 */
public final class AppState {

    private static final AppState I = new AppState();
    public static AppState get() { return I; }
    private AppState() {}

    // ---- 可交互的产品状态（演示） ----
    public boolean connected = false;
    public boolean systemProxy = true;
    public boolean tunMode = false;
    public boolean ipv6 = false;
    public boolean autoUpdate = true;
    public boolean liquidGlass = false;   // 明确不默认开启
    public boolean pureBlack = false;
    public int themeMode = 0;             // 0 跟随系统 / 1 浅色 / 2 深色
    public int ruleMode = 0;              // 0 规则 / 1 全局 / 2 直连
    public int selectedNode = 0;
    public int selectedGroup = 0;
    public long connectSinceMs = 0L;

    public static final String[] NODE_NAMES = {
            "HK-01 · 自动选择", "Tokyo-02", "Singapore-03", "US-West-04",
            "HK-05 备用", "Taiwan-06", "London-07", "DIRECT 直连"
    };
    public static final int[] NODE_LATENCY = { 38, 62, 89, 156, 47, 118, 231, -1 };
    public static final String[] NODE_REGION = {
            "中国香港 · BGP", "日本 · 东京", "新加坡", "美国 · 洛杉矶",
            "中国香港 · CN2", "中国台湾", "英国 · 伦敦", "绕过代理"
    };
    public static final String[] GROUPS = { "节点选择", "自动选择", "流媒体", "广告拦截" };

    public static String latencyLabel(int ms) {
        return ms < 0 ? "直连" : ms + " ms";
    }

    public static int latencyColor(int ms) {
        if (ms < 0) return Ui.TEXT3;
        if (ms < 80) return Ui.GREEN;
        if (ms < 150) return Ui.ORANGE;
        return Ui.RED;
    }

    public String themeLabel() {
        return new String[]{"跟随系统", "浅色", "深色"}[themeMode];
    }
    public String ruleModeLabel() {
        return new String[]{"规则模式", "全局代理", "直连模式"}[ruleMode];
    }

    // ---- 内核真值（JNI） ----
    public String coreInfo() {
        try {
            int ver = RustCore.nativeVersion();
            long initUs = RustCore.nativeInitNs() / 1000;
            long rss = RustCore.nativeRssBytes();
            long logical = RustCore.nativeLogicalBytes();
            int rules = RustCore.nativeRuleCount();
            int conns = RustCore.nativeConnCount();
            long bytes = RustCore.nativeLoopbackBytes();
            return String.format(Locale.getDefault(),
                    "core version   : %d%n" +
                    "首次 JNI 冷启动 : %,d us%n" +
                    "规则条数       : %d%n" +
                    "连接表         : %d 条%n" +
                    "逻辑状态       : %,d B%n" +
                    "进程 RSS       : %.2f MB%n" +
                    "模拟数据面字节 : %,d B%n%n" +
                    "no GC / no runtime / no VM%n" +
                    "以上读数来自 Rust core（JNI 实时）",
                    ver, initUs, rules, conns, logical, rss / 1048576.0, bytes);
        } catch (Throwable t) {
            return "内核读数不可用：" + t;
        }
    }

    /** 轻量冷启动探测：只触发 OnceLock 初始化，不做重基准。 */
    public void warmUp() {
        try { RustCore.nativeVersion(); } catch (Throwable ignored) {}
    }
}

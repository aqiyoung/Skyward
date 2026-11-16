package com.threely.skyward;

import android.app.AlertDialog;
import android.content.Context;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.view.View;
import android.widget.EditText;
import android.widget.LinearLayout;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import static com.threely.skyward.Widgets.*;

public final class PageProfiles {
    private static final Handler MAIN = new Handler(Looper.getMainLooper());
    private static final ExecutorService CONFIG = Executors.newSingleThreadExecutor(task -> {
        Thread thread = new Thread(task, "skyward-profile-config");
        thread.setDaemon(true);
        return thread;
    });

    private PageProfiles() {}

    public static View profiles(Context c, Runnable refresh) {
        AppState state = AppState.get();
        AppState.Profile active = state.activeProfile();
        LinearLayout body = Ui.pageBody(c);
        body.addView(Ui.pageHeader(c, "配置", "订阅管理 · Rust 解析与持久化"));

        body.addView(Ui.groupTitle(c, "当前配置"));
        LinearLayout current = Ui.newCard(c);
        String activeName = active == null ? "未配置" : active.name;
        current.addView(Ui.row(c, IconView.Glyph.PROFILE, Ui.BLUE, activeName,
                active == null ? "导入订阅或配置文本后显示节点" : "已启用 · " + nodeCount() + " 个节点",
                Ui.valueText(c, "当前"), null));
        if (active != null) {
            current.addView(Ui.separator(c));
            String updated = new SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.getDefault())
                    .format(new Date(active.updatedAt));
            current.addView(Ui.row(c, IconView.Glyph.CLOCK, Ui.TEXT2, "最近更新",
                    updated, null, null));
        }
        current.addView(Ui.separator(c));
        current.addView(Ui.row(c, IconView.Glyph.LIST, Ui.TEXT2, "规则条数",
                "来自 Rust 内核", Ui.valueText(c, RustCore.nativeRuleCount() + " 条"), null));
        current.addView(Ui.separator(c));
        current.addView(Ui.row(c, IconView.Glyph.LAYERS, Ui.TEAL, "规则引擎",
                "索引 trie / 关键词分桶 / CIDR",
                Ui.valueText(c, RustCore.nativeIndexNodes() + " 节点"), null));
        body.addView(current);

        body.addView(Ui.groupTitle(c, "配置列表 · " + state.profiles.size()));
        LinearLayout profiles = Ui.newCard(c);
        if (state.profiles.isEmpty()) {
            profiles.addView(Ui.row(c, IconView.Glyph.INFO, Ui.TEXT2, "暂无已保存配置",
                    "添加订阅链接或导入本地配置文本", null, null));
        }
        for (int i = 0; i < state.profiles.size(); i++) {
            AppState.Profile profile = state.profiles.get(i);
            profiles.addView(Ui.separator(c));
            boolean selected = profile.id.equals(state.activeProfileId);
            String host = Uri.parse(profile.url).getHost();
            String subtitle = profile.url.isEmpty() ? "本地配置 · 已保存"
                    : (host == null ? "订阅链接" : host) + " · 已保存";
            profiles.addView(Ui.row(c, IconView.Glyph.GLOBE, Ui.GREEN, profile.name,
                    subtitle, Ui.valueText(c, selected ? "当前" : "切换"), v ->
                            activateProfile(c, state, profile, refresh)));
        }
        body.addView(profiles);

        if (active != null && !active.url.isEmpty()) {
            body.addView(Ui.groupTitle(c, "订阅更新"));
            LinearLayout update = Ui.newCard(c);
            update.addView(Ui.row(c, IconView.Glyph.ARROW_DOWN, Ui.BLUE, "立即更新当前订阅",
                    "更新后自动切换到此配置", null,
                    v -> fetchSubscription(c, state, active.url, active.name, refresh)));
            body.addView(update);
        }

        body.addView(Ui.groupTitle(c, "添加配置"));
        LinearLayout add = Ui.newCard(c);
        add.addView(Ui.row(c, IconView.Glyph.PLUS, Ui.BLUE, "添加订阅链接",
                "HTTP(S) · Clash YAML 或 SS / Trojan / VLESS / VMess URI", null,
                v -> showSubscriptionDialog(c, state, refresh)));
        add.addView(Ui.separator(c));
        add.addView(Ui.row(c, IconView.Glyph.PROFILE, Ui.ORANGE, "导入配置文本",
                "粘贴 Clash YAML 或代理 URI 列表", null,
                v -> showTextDialog(c, state, refresh)));
        body.addView(add);

        body.addView(note(c, "配置和节点选择保存在应用私有存储。当前可转发协议：Shadowsocks ChaCha20-Poly1305、Trojan TLS、VLESS TCP/TLS；Clash YAML 和已支持的 URI 格式也会保留其它节点供查看，但它们不能选作出站。"));
        return page(c, body);
    }

    private static void activateProfile(Context c, AppState state, AppState.Profile profile,
                                        Runnable refresh) {
        if (!beginConfigChange(c, state)) return;
        Ui.toast(c, "正在切换配置…");
        submitConfig(state, c, refresh, () -> {
            int count = RustCore.nativeParseConfig(profile.content);
            String error = count > 0 ? "" : lastError();
            runOnMainAndWait(c, state, () -> {
                if (state.connected || state.proxyRunning || state.tunMode) {
                    Ui.toast(c, "请先断开当前代理或 VPN 后再切换配置");
                    refresh.run();
                    return;
                }
                if (state.activateParsedProfile(profile.id, count)) {
                    Ui.toast(c, "已切换配置：" + profile.name);
                    refresh.run();
                } else {
                    Ui.toast(c, "配置无法解析：" + (error.isEmpty() ? lastError() : error));
                    refresh.run();
                }
            });
        });
    }

    private static void showSubscriptionDialog(Context c, AppState state, Runnable refresh) {
        EditText input = new EditText(c);
        input.setSingleLine(true);
        input.setHint("https://example.com/subscribe?token=...");
        input.setInputType(android.text.InputType.TYPE_CLASS_TEXT
                | android.text.InputType.TYPE_TEXT_VARIATION_URI);
        new AlertDialog.Builder(c)
                .setTitle("添加订阅链接")
                .setView(input)
                .setNegativeButton("取消", null)
                .setPositiveButton("导入", (dialog, which) -> {
                    String url = input.getText().toString().trim();
                    if (url.isEmpty()) {
                        Ui.toast(c, "请输入订阅链接");
                        return;
                    }
                    fetchSubscription(c, state, url, Uri.parse(url).getHost(), refresh);
                })
                .show();
    }

    private static void fetchSubscription(Context c, AppState state, String url, String name,
                                          Runnable refresh) {
        if (!beginConfigChange(c, state)) return;
        Ui.toast(c, "正在下载订阅…");
        submitConfig(state, c, refresh, () -> {
            String content = RustCore.nativeFetchSubscription(url);
            if (content == null || content.isEmpty()) {
                String error = lastError();
                runOnMainAndWait(c, state, () -> {
                    Ui.toast(c, "下载失败：" + error);
                    refresh.run();
                });
                return;
            }
            parseAndImport(c, state, url, content,
                    name == null || name.isEmpty() ? "订阅配置" : name, refresh);
        });
    }

    private static void parseAndImport(Context c, AppState state, String url, String content,
                                       String name, Runnable refresh) {
        int count = RustCore.nativeParseConfig(content);
        if (count <= 0) {
            String error = lastError();
            runOnMainAndWait(c, state, () -> {
                Ui.toast(c, "解析失败：" + error);
                refresh.run();
            });
            return;
        }
        runOnMainAndWait(c, state, () -> finishImport(c, state, url, content, name, count, refresh));
    }

    private static void showTextDialog(Context c, AppState state, Runnable refresh) {
        EditText input = new EditText(c);
        input.setHint("粘贴 Clash YAML，或每行一个 ss://、trojan://、vless://、vmess:// 链接");
        input.setGravity(Gravity.TOP | Gravity.START);
        input.setMinLines(8);
        input.setMaxLines(16);
        input.setInputType(android.text.InputType.TYPE_CLASS_TEXT
                | android.text.InputType.TYPE_TEXT_FLAG_MULTI_LINE
                | android.text.InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS);
        new AlertDialog.Builder(c)
                .setTitle("导入配置文本")
                .setView(input)
                .setNegativeButton("取消", null)
                .setPositiveButton("解析并保存", (dialog, which) -> {
                    String text = input.getText().toString().trim();
                    if (text.isEmpty()) {
                        Ui.toast(c, "配置内容为空");
                        return;
                    }
                    if (!beginConfigChange(c, state)) return;
                    String name = "本地配置 " + (state.profiles.size() + 1);
                    submitConfig(state, c, refresh,
                            () -> parseAndImport(c, state, "", text, name, refresh));
                })
                .show();
    }

    private static boolean beginConfigChange(Context c, AppState state) {
        if (state.configBusy) {
            Ui.toast(c, "配置操作正在进行，请稍候");
            return false;
        }
        if (state.connected || state.proxyRunning || state.tunMode) {
            Ui.toast(c, "请先断开当前代理或 VPN 后再修改配置");
            return false;
        }
        state.configBusy = true;
        return true;
    }

    private static void submitConfig(AppState state, Context c, Runnable refresh, Runnable work) {
        CONFIG.execute(() -> {
            try {
                work.run();
            } catch (Throwable error) {
                String message = error.getMessage();
                runOnMainAndWait(c, state, () -> {
                    Ui.toast(c, "配置操作失败：" + (message == null
                            ? error.getClass().getSimpleName() : message));
                    refresh.run();
                });
            }
        });
    }

    private static void runOnMainAndWait(Context c, AppState state, Runnable action) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            state.configBusy = false;
            try {
                action.run();
            } finally {
                state.configBusy = false;
            }
            return;
        }
        CountDownLatch completed = new CountDownLatch(1);
        if (!MAIN.post(() -> {
            state.configBusy = false;
            try {
                action.run();
            } catch (Throwable error) {
                String message = error.getMessage();
                Ui.toast(c, "配置操作失败：" + (message == null
                        ? error.getClass().getSimpleName() : message));
            } finally {
                state.configBusy = false;
                completed.countDown();
            }
        })) {
            state.configBusy = false;
            return;
        }
        boolean interrupted = false;
        while (true) {
            try {
                completed.await();
                break;
            } catch (InterruptedException ignored) {
                interrupted = true;
            }
        }
        if (interrupted) Thread.currentThread().interrupt();
    }

    private static String lastError() {
        try {
            String error = RustCore.nativeLastError();
            return error == null || error.isEmpty() ? "未知错误" : error;
        } catch (Throwable ignored) {
            return "未知错误";
        }
    }

    private static void finishImport(Context c, AppState state, String url, String content,
                                     String name, int count, Runnable refresh) {
        if (state.connected || state.proxyRunning || state.tunMode) {
            Ui.toast(c, "配置已解析；请先断开代理或 VPN 后再保存并启用");
            refresh.run();
            return;
        }
        if (!state.importProfileParsed(url, content, name, count)) {
            Ui.toast(c, "保存失败");
            refresh.run();
            return;
        }
        Ui.toast(c, "已导入 " + count + " 个节点；已保存并启用配置");
        refresh.run();
    }
}

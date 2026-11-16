package com.threely.skyward;

import android.content.Context;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.Switch;
import android.widget.TextView;

import java.util.Locale;

import static com.threely.skyward.Widgets.*;

/** 配置页：订阅与配置文件列表。 */
public final class PageProfiles {
    private PageProfiles() {}

    public static View profiles(Context c, Runnable refresh) {
        LinearLayout body = Ui.pageBody(c);
        body.addView(Ui.pageHeader(c, "配置", "当前配置 · 订阅管理"));

        body.addView(Ui.groupTitle(c, "当前配置"));
        LinearLayout cur = Ui.newCard(c);
        cur.addView(Ui.row(c, IconView.Glyph.PROFILE, Ui.BLUE, "本地配置",
                "已启用 · 演示", Ui.valueText(c, "默认"), null));
        cur.addView(Ui.separator(c));
        cur.addView(Ui.row(c, IconView.Glyph.CLOCK, Ui.TEXT2, "最近更新",
                "演示：刚刚更新", null, null));
        cur.addView(Ui.separator(c));
        cur.addView(Ui.row(c, IconView.Glyph.LIST, Ui.TEXT2, "规则条数",
                "来自 Rust 内核", Ui.valueText(c, RustCore.nativeRuleCount() + " 条"), null));
        cur.addView(Ui.separator(c));
        cur.addView(Ui.row(c, IconView.Glyph.LAYERS, Ui.TEAL, "规则引擎",
                "索引 trie / 关键词分桶 / CIDR",
                Ui.valueText(c, RustCore.nativeIndexNodes() + " 节点"), null));
        body.addView(cur);

        body.addView(Ui.groupTitle(c, "订阅"));
        int nc = nodeCount();
        LinearLayout subs = Ui.newCard(c);
        if (nc > 0) {
            subs.addView(Ui.row(c, IconView.Glyph.GLOBE, Ui.GREEN, "示例订阅 · 已载入",
                    nc + " 个节点 · Rust 内核解析", Ui.valueText(c, "已解析"), null));
        } else {
            subs.addView(Ui.row(c, IconView.Glyph.GLOBE, Ui.TEAL, "示例订阅（未载入）",
                    "点击载入真实节点", null,
                    v -> { int k = RustCore.nativeLoadSampleConfig();
                           Ui.toast(c, "已解析 " + k + " 个节点"); refresh.run(); }));
        }
        subs.addView(Ui.separator(c));
        subs.addView(Ui.row(c, IconView.Glyph.PLUS, Ui.BLUE, "添加订阅",
                "从链接导入 · 演示入口", null,
                v -> Ui.toast(c, "订阅导入未接入，本版为界面占位")));
        body.addView(subs);

        body.addView(Ui.groupTitle(c, "添加"));
        LinearLayout add = Ui.newCard(c);
        add.addView(Ui.row(c, IconView.Glyph.PROFILE, Ui.ORANGE, "新建配置",
                "本地空白配置 · 演示入口", null,
                v -> Ui.toast(c, "配置编辑未接入，本版为界面占位")));
        body.addView(add);

        body.addView(note(c, "示例订阅由 Rust 内核按 Clash 风格解析（真实节点，非占位）；"
                + "订阅链接导入、落盘与切换属后续阶段。"));
        return page(c, body);
    }
}

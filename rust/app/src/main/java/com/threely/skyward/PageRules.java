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

/** 规则页：规则集命中率真值、决策查询、基准测试。 */
public final class PageRules {
    private PageRules() {}

    public static View rules(Context c, Runnable refresh) {
        final AppState s = AppState.get();
        LinearLayout body = Ui.pageBody(c);
        body.addView(Ui.pageHeader(c, "规则", "路由规则总览 · 来自 Rust 内核"));

        int n = 0;
        try { n = RustCore.nativeRuleCount(); } catch (Throwable t) { }
        body.addView(Ui.groupTitle(c,
                "规则集（" + n + " 条）· 命中优先级按列表顺序"));

        LinearLayout list = Ui.newCard(c);
        if (n == 0) {
            list.addView(Ui.row(c, IconView.Glyph.INFO, Ui.TEXT3, "暂无规则",
                    "内核未载入规则集", null, null));
        }
        for (int i = 0; i < n; i++) {
            final int idx = i;
            String pattern, kindLabel;
            int action;
            try {
                pattern = RustCore.nativeRulePattern(i);
                int kind = RustCore.nativeRuleKind(i);
                action = RustCore.nativeRuleAction(i);
                kindLabel = new String[]{"DOMAIN-SUFFIX", "DOMAIN-KEYWORD", "IP-CIDR", "DOMAIN"}[kind];
            } catch (Throwable t) {
                pattern = "—"; kindLabel = "—"; action = 0;
            }
            String[] actName = {"直连 DIRECT", "代理 PROXY", "拒绝 REJECT"};
            int[] actTint = {Ui.TEXT2, Ui.BLUE, Ui.RED};
            // 标题行：规则序号 + 动作（着色）
            TextView title = new TextView(c);
            title.setText("#" + (idx + 1) + "  " + pattern);
            title.setTextSize(14);
            title.setTextColor(Ui.TEXT);
            title.setTypeface(Typeface.DEFAULT_BOLD);
            title.setPadding(Ui.dp(c, 14), Ui.dp(c, 12), Ui.dp(c, 14), 0);
            // 副信息行：类型 + 动作徽标
            TextView sub = new TextView(c);
            sub.setTextSize(12);
            sub.setTextColor(actTint[action]);
            sub.setPadding(Ui.dp(c, 14), Ui.dp(c, 2), Ui.dp(c, 14), Ui.dp(c, 12));
            sub.setText(kindLabel + " → " + actName[action]);
            list.addView(title);
            list.addView(sub);
            if (i != n - 1) list.addView(Ui.separator(c));
        }
        body.addView(list);

        body.addView(Ui.groupTitle(c, "数据面分流计数（真实决策）"));
        LinearLayout counts = Ui.newCard(c);
        String routeCsv = "0,0,0";
        try { routeCsv = RustCore.nativeRouteStats(); } catch (Throwable t) { }
        String[] rc = routeCsv.split(",");
        counts.addView(Ui.row(c, IconView.Glyph.ROUTE, Ui.BLUE, "直连 / 代理 / 拒绝",
                "SOCKS5 与 TUN 每个连接的路由裁决累计", Ui.valueText(c,
                        rc[0] + " / " + (rc.length > 1 ? rc[1] : "0")
                                + " / " + (rc.length > 2 ? rc[2] : "0")), null));
        body.addView(counts);

        body.addView(note(c, "以上规则由 Rust 内核索引引擎真实持有（反转域名 trie / 关键词分桶 / "
                + "CIDR 最长前缀）。「代理」页的路由测试、首页的流量分配均与这里同源；"
                + "命中优先级按列表自上而下，首条命中生效。"));
        return page(c, body);
    }
}

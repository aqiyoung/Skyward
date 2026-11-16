package com.threely.skyward;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;
import android.view.View;
import android.widget.FrameLayout;

/**
 * 仪表盘自绘视图：
 *  - WaveCard：状态卡容器。波形是卡片自身的背景，在 dispatchDraw 里按卡片实际
 *    高度绘制并裁到圆角内。不能用「铺满的子 View」——FrameLayout 在
 *    ScrollView（高度不定）里会给 MATCH_PARENT 子项整屏高度，卡片被撑爆。
 *  - GlobeView：路由卡的线框地球 + 蓝色航线弧（本机→节点）。
 * 纯 Canvas 绘制，零图片资源。
 */
public final class Dash {

    private Dash() {}

    private static float dp(Context c, float v) { return Ui.dp(c, v); }

    /** 34 圆角白卡，波形铺在卡片背景层。 */
    public static final class WaveCard extends FrameLayout {
        private final Paint p = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Path clip = new Path();
        private final Path wave = new Path();
        private final float radius;
        private boolean showWave = true;

        public WaveCard(Context c, float radiusDp) {
            super(c);
            radius = dp(c, radiusDp);
            p.setStyle(Paint.Style.STROKE);
            p.setStrokeCap(Paint.Cap.ROUND);
            android.graphics.drawable.GradientDrawable bg =
                    new android.graphics.drawable.GradientDrawable();
            bg.setColor(Color.WHITE);
            bg.setCornerRadius(radius);
            setBackground(bg);
            setElevation(dp(c, 1));
            setWillNotDraw(false);
        }

        public void setWaveVisible(boolean v) { showWave = v; invalidate(); }

        @Override
        protected void dispatchDraw(Canvas cv) {
            int w = getWidth(), h = getHeight();
            if (showWave && w > 0 && h > 0) {
                clip.reset();
                clip.addRoundRect(0, 0, w, h, radius, radius, Path.Direction.CW);
                int save = cv.save();
                cv.clipPath(clip);
                wave(cv, w, h, 0.92f, 0.07f, 2.2f, 1.6f, Color.parseColor("#33007AFF"));
                wave(cv, w, h, 0.96f, 0.05f, 3.1f, 0.9f, Color.parseColor("#2600A94F"));
                cv.restoreToCount(save);
            }
            super.dispatchDraw(cv);
        }

        private void wave(Canvas cv, int w, int h, float base, float amp,
                          float freq, float phase, int color) {
            p.setColor(color);
            p.setStrokeWidth(dp(getContext(), 1.4f));
            wave.reset();
            float pad = dp(getContext(), 4);
            int steps = 72;
            for (int i = 0; i <= steps; i++) {
                float t = (float) i / steps;
                float x = pad + (w - 2 * pad) * t;
                float y = h * base
                        - (float) Math.sin(t * Math.PI * freq + phase) * h * amp
                        * (0.72f + 0.28f * (float) Math.sin(t * 9.0f + phase));
                if (i == 0) wave.moveTo(x, y);
                else wave.lineTo(x, y);
            }
            cv.drawPath(wave, p);
        }
    }

    /** 线框地球：球体 + 经纬线 + 一条蓝色航线弧与两端端点。 */
    public static final class GlobeView extends View {
        private final Paint stroke = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Paint fill = new Paint(Paint.ANTI_ALIAS_FLAG);

        public GlobeView(Context c) {
            super(c);
            stroke.setStyle(Paint.Style.STROKE);
            stroke.setStrokeCap(Paint.Cap.ROUND);
            fill.setStyle(Paint.Style.FILL);
        }

        @Override
        protected void onDraw(Canvas cv) {
            int w = getWidth(), h = getHeight();
            if (w == 0 || h == 0) return;
            float cx = w / 2f, cy = h / 2f;
            float r = Math.min(w, h) / 2f * 0.80f;

            // 球体底色 + 外圈
            fill.setColor(Color.parseColor("#F7F9FC"));
            cv.drawCircle(cx, cy, r, fill);
            stroke.setColor(Color.parseColor("#DDE3EC"));
            stroke.setStrokeWidth(dp(getContext(), 1.0f));
            cv.drawCircle(cx, cy, r, stroke);

            // 经线（椭圆，按比例收窄）
            stroke.setColor(Color.parseColor("#E6EBF2"));
            float[] sx = {0.34f, 0.68f, 1.0f};
            for (float s : sx) {
                cv.drawOval(cx - r * s, cy - r, cx + r * s, cy + r, stroke);
            }
            // 纬线（横向弦）
            float[] lat = {-0.60f, -0.30f, 0f, 0.30f, 0.60f};
            for (float o : lat) {
                float y = cy + r * o;
                float hw = (float) Math.sqrt(Math.max(0, 1 - o * o)) * r;
                cv.drawLine(cx - hw, y, cx + hw, y, stroke);
            }

            // 航线弧：左侧本机 → 右侧节点
            float ax = cx - r * 0.58f, ay = cy + r * 0.14f;
            float bx = cx + r * 0.54f, by = cy - r * 0.08f;
            Path arc = new Path();
            arc.moveTo(ax, ay);
            arc.quadTo(cx, cy - r * 0.72f, bx, by);
            stroke.setColor(Ui.BLUE);
            stroke.setStrokeWidth(dp(getContext(), 1.8f));
            cv.drawPath(arc, stroke);

            // 端点
            drawDot(cv, ax, ay);
            drawDot(cv, bx, by);
        }

        private void drawDot(Canvas cv, float x, float y) {
            fill.setColor(Color.WHITE);
            cv.drawCircle(x, y, dp(getContext(), 4.4f), fill);
            fill.setColor(Ui.BLUE);
            cv.drawCircle(x, y, dp(getContext(), 3.0f), fill);
        }
    }
}

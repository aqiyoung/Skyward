package com.threely.skyward.poc;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;
import android.view.View;

/**
 * 零资源图标：纯 Canvas 线条绘制，不引入图片 / 字体 / 矢量资源。
 * 保持包体积极小，同时让原生 View 界面具备可读的图标语言。
 */
public class IconView extends View {

    public enum Glyph {
        HOME, GLOBE, LAYERS, PERSON, BOLT, SHIELD, GEAR, CHEVRON,
        POWER, ARROW_UP, ARROW_DOWN, CHART, LIST, INFO, PLUS, SWITCH,
        ROUTE, DNS, CLOCK, MEMORY, CHECK, PALETTE, TUN, PROFILE, RULES
    }

    private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private Glyph glyph = Glyph.INFO;
    private int color = Ui.TEXT;

    public IconView(Context ctx, Glyph g, int color) {
        super(ctx);
        this.glyph = g;
        this.color = color;
        paint.setStyle(Paint.Style.STROKE);
        paint.setStrokeCap(Paint.Cap.ROUND);
        paint.setStrokeJoin(Paint.Join.ROUND);
        paint.setColor(color);
    }

    public void setGlyph(Glyph g) { glyph = g; invalidate(); }
    public void setTint(int c) { color = c; paint.setColor(c); invalidate(); }

    @Override
    protected void onMeasure(int w, int h) {
        int d = Ui.dp(getContext(), 24);
        setMeasuredDimension(resolveSize(d, w), resolveSize(d, h));
    }

    @Override
    protected void onDraw(Canvas c) {
        super.onDraw(c);
        float w = getWidth(), h = getHeight();
        float s = Math.min(w, h);
        paint.setColor(color);

        // 统一坐标域 0..24，按实际尺寸缩放。线宽必须在 scale 之后按坐标域设置：
        // 若先按像素设 s*0.075，canvas 缩放会把它一并放大成近实心块。
        float k = s / 24f;
        c.save();
        c.scale(k, k);
        paint.setStrokeWidth(1.7f);
        float cx = 12f, cy = 12f;
        Path p = new Path();

        switch (glyph) {
            case HOME:
                p.moveTo(3, 11); p.lineTo(12, 3.5f); p.lineTo(21, 11);
                p.moveTo(5.5f, 9.5f); p.lineTo(5.5f, 20); p.lineTo(18.5f, 20); p.lineTo(18.5f, 9.5f);
                p.moveTo(10, 20); p.lineTo(10, 14); p.lineTo(14, 14); p.lineTo(14, 20);
                c.drawPath(p, paint); break;
            case GLOBE:
                c.drawCircle(cx, cy, 8.5f, paint);
                c.drawOval(7.5f, 3.5f, 16.5f, 20.5f, paint);
                c.drawLine(3.5f, 12, 20.5f, 12, paint);
                c.drawLine(12, 3.5f, 12, 20.5f, paint); break;
            case LAYERS:
                p.moveTo(12, 3); p.lineTo(21, 8); p.lineTo(12, 13); p.lineTo(3, 8); p.close();
                c.drawPath(p, paint);
                p.reset(); p.moveTo(3, 12.5f); p.lineTo(12, 17.5f); p.lineTo(21, 12.5f);
                c.drawPath(p, paint);
                p.reset(); p.moveTo(3, 17); p.lineTo(12, 22); p.lineTo(21, 17);
                c.drawPath(p, paint); break;
            case PERSON:
                c.drawCircle(cx, 8f, 3.6f, paint);
                p.moveTo(4.5f, 21); p.lineTo(4.5f, 18.5f);
                p.quadTo(4.5f, 13.5f, 12, 13.5f);
                p.quadTo(19.5f, 13.5f, 19.5f, 18.5f); p.lineTo(19.5f, 21);
                c.drawPath(p, paint); break;
            case BOLT:
                p.moveTo(13.5f, 2.5f); p.lineTo(6, 13); p.lineTo(11, 13);
                p.lineTo(10, 21.5f); p.lineTo(18, 10.5f); p.lineTo(13, 10.5f); p.close();
                c.drawPath(p, paint); break;
            case SHIELD:
                p.moveTo(12, 2.8f); p.lineTo(20, 6); p.lineTo(20, 12);
                p.quadTo(20, 18, 12, 21.5f);
                p.quadTo(4, 18, 4, 12); p.lineTo(4, 6); p.close();
                c.drawPath(p, paint);
                p.reset(); p.moveTo(8.5f, 12); p.lineTo(11, 14.5f); p.lineTo(16, 9.5f);
                c.drawPath(p, paint); break;
            case GEAR:
                c.drawCircle(cx, cy, 3.2f, paint);
                for (int i = 0; i < 8; i++) {
                    double a = i * Math.PI / 4;
                    float x1 = (float) (cx + Math.cos(a) * 6.2f), y1 = (float) (cy + Math.sin(a) * 6.2f);
                    float x2 = (float) (cx + Math.cos(a) * 9.2f), y2 = (float) (cy + Math.sin(a) * 9.2f);
                    c.drawLine(x1, y1, x2, y2, paint);
                }
                c.drawCircle(cx, cy, 8.2f, paint); break;
            case CHEVRON:
                p.moveTo(9, 5); p.lineTo(16, 12); p.lineTo(9, 19);
                c.drawPath(p, paint); break;
            case POWER:
                c.drawArc(4.5f, 4.5f, 19.5f, 19.5f, 130, 280, false, paint);
                c.drawLine(12, 2.5f, 12, 11, paint); break;
            case ARROW_UP:
                c.drawLine(12, 20, 12, 4, paint);
                p.moveTo(6.5f, 9.5f); p.lineTo(12, 4); p.lineTo(17.5f, 9.5f);
                c.drawPath(p, paint); break;
            case ARROW_DOWN:
                c.drawLine(12, 4, 12, 20, paint);
                p.moveTo(6.5f, 14.5f); p.lineTo(12, 20); p.lineTo(17.5f, 14.5f);
                c.drawPath(p, paint); break;
            case CHART:
                c.drawLine(3.5f, 20, 20.5f, 20, paint);
                c.drawLine(3.5f, 20, 3.5f, 3.5f, paint);
                p.moveTo(6, 16); p.lineTo(10, 11); p.lineTo(13.5f, 14); p.lineTo(19, 6.5f);
                c.drawPath(p, paint); break;
            case LIST:
                c.drawCircle(5.5f, 6.5f, 1.3f, paint);
                c.drawCircle(5.5f, 12, 1.3f, paint);
                c.drawCircle(5.5f, 17.5f, 1.3f, paint);
                c.drawLine(9.5f, 6.5f, 20, 6.5f, paint);
                c.drawLine(9.5f, 12, 20, 12, paint);
                c.drawLine(9.5f, 17.5f, 20, 17.5f, paint); break;
            case INFO:
                c.drawCircle(cx, cy, 8.7f, paint);
                c.drawLine(12, 11, 12, 17, paint);
                c.drawCircle(12, 7.6f, 0.9f, paint); break;
            case PLUS:
                c.drawLine(12, 4, 12, 20, paint);
                c.drawLine(4, 12, 20, 12, paint); break;
            case SWITCH:
                c.drawRoundRect(3, 7, 21, 17, 5, 5, paint);
                c.drawCircle(16, 12, 3.1f, paint); break;
            case ROUTE:
                c.drawCircle(5.5f, 5.5f, 2.4f, paint);
                c.drawCircle(18.5f, 18.5f, 2.4f, paint);
                p.moveTo(5.5f, 8); p.lineTo(5.5f, 14);
                p.quadTo(5.5f, 18.5f, 9.5f, 18.5f); p.lineTo(16, 18.5f);
                c.drawPath(p, paint);
                c.drawLine(9, 5.5f, 18.5f, 5.5f, paint); break;
            case DNS:
                c.drawRect(3.5f, 4, 20.5f, 9, paint);
                c.drawRect(3.5f, 13, 20.5f, 18, paint);
                c.drawCircle(7, 6.5f, 1, paint);
                c.drawCircle(7, 15.5f, 1, paint); break;
            case CLOCK:
                c.drawCircle(cx, cy, 8.7f, paint);
                c.drawLine(12, 12, 12, 7, paint);
                c.drawLine(12, 12, 16, 14, paint); break;
            case MEMORY:
                c.drawRect(4, 6, 20, 18, paint);
                c.drawLine(8, 6, 8, 3, paint);
                c.drawLine(12, 6, 12, 3, paint);
                c.drawLine(16, 6, 16, 3, paint);
                c.drawLine(8, 18, 8, 21, paint);
                c.drawLine(12, 18, 12, 21, paint);
                c.drawLine(16, 18, 16, 21, paint);
                c.drawLine(8, 10, 16, 10, paint);
                c.drawLine(8, 14, 16, 14, paint); break;
            case CHECK:
                p.moveTo(4.5f, 12.5f); p.lineTo(9.5f, 17.5f); p.lineTo(19.5f, 6.5f);
                c.drawPath(p, paint); break;
            case PALETTE:
                c.drawCircle(cx, cy, 8.7f, paint);
                c.drawCircle(8, 9, 1.2f, paint);
                c.drawCircle(12, 6.8f, 1.2f, paint);
                c.drawCircle(16, 9, 1.2f, paint);
                c.drawCircle(16.5f, 14, 1.2f, paint); break;
            case TUN:
                c.drawOval(3.5f, 4, 20.5f, 10, paint);
                c.drawLine(3.5f, 7, 20.5f, 7, paint);
                c.drawLine(4.5f, 10, 4.5f, 20, paint);
                c.drawLine(19.5f, 10, 19.5f, 20, paint);
                c.drawLine(4.5f, 20, 19.5f, 20, paint); break;
            case PROFILE:
                c.drawRect(4, 3.5f, 20, 20.5f, paint);
                c.drawLine(7.5f, 8, 16.5f, 8, paint);
                c.drawLine(7.5f, 12, 16.5f, 12, paint);
                c.drawLine(7.5f, 16, 13, 16, paint); break;
            case RULES:
                // 漏斗 / 筛选：上宽下窄，中部收口，下方引出两道分支
                p.moveTo(4.5f, 4); p.lineTo(19.5f, 4); p.lineTo(14, 12); p.lineTo(14, 17);
                p.lineTo(10, 17); p.lineTo(10, 12); p.close();
                c.drawPath(p, paint);
                c.drawLine(10, 17, 6, 21, paint); c.drawLine(14, 17, 18, 21, paint); break;
            default:
                c.drawCircle(cx, cy, 8, paint);
        }
        c.restore();
    }
}

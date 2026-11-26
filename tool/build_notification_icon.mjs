// Turns the site mark into the flat white silhouette Android needs for a
// notification small icon: the alpha mask is traced into contours (marching
// squares), simplified, and emitted as a vector drawable path.
//
// Usage: node tool/build_notification_icon.mjs [site/mark.png] [output.xml]
import { readFileSync, writeFileSync } from 'node:fs';
import { chromium } from 'playwright-core';

const markPath = process.argv[2] || 'site/mark.png';
const outPath = process.argv[3] || 'android/service/src/main/res/drawable/ic_service.xml';
const GRID = 256; // working width in cells
const VIEW = 96; // drawable viewport

const browser = await chromium.launch({ executablePath: '/usr/bin/chromium', args: ['--no-sandbox'] });
const page = await browser.newPage();
await page.setContent('<!doctype html><html><body></body></html>');
const mask = await page.evaluate(
  async ({ mark, grid }) => {
    const img = new Image();
    await new Promise((resolve, reject) => {
      img.onload = resolve;
      img.onerror = reject;
      img.src = `data:image/png;base64,${mark}`;
    });
    const h = Math.round((grid * img.naturalHeight) / img.naturalWidth);
    const canvas = document.createElement('canvas');
    canvas.width = grid;
    canvas.height = h;
    const ctx = canvas.getContext('2d', { willReadFrequently: true });
    ctx.drawImage(img, 0, 0, grid, h);
    const { data } = ctx.getImageData(0, 0, grid, h);
    const rows = [];
    for (let y = 0; y < h; y++) {
      const row = [];
      for (let x = 0; x < grid; x++) row.push(data[(y * grid + x) * 4 + 3] >= 128 ? 1 : 0);
      rows.push(row);
    }
    return { rows, w: grid, h };
  },
  { mark: readFileSync(markPath).toString('base64'), grid: GRID },
);
await browser.close();

// Pad with a border of zeros so no contour touches the grid edge.
const w = mask.w + 2;
const h = mask.h + 2;
const at = (x, y) => (x < 0 || y < 0 || x > w - 1 || y > h - 1 ? 0 : y === 0 || y === h - 1 || x === 0 || x === w - 1 ? 0 : mask.rows[y - 1][x - 1]);
const cell = (x, y) => at(x, y - 1) + 2 * at(x + 1, y - 1) + 4 * at(x + 1, y) + 8 * at(x, y);

// Marching squares: edge midpoints relative to a cell, in doubled integers.
const L = [0, 1];
const R = [2, 1];
const T = [1, 0];
const B = [1, 2];
const TABLE = {
  1: [[L, T]], 2: [[T, R]], 3: [[L, R]], 4: [[R, B]],
  5: [[L, T], [R, B]], 6: [[T, B]], 7: [[L, B]], 8: [[B, L]],
  9: [[T, B]], 10: [[T, R], [B, L]], 11: [[R, B]], 12: [[L, R]],
  13: [[T, R]], 14: [[L, T]],
};

const segments = [];
for (let y = 0; y < h - 1; y++) {
  for (let x = 0; x < w - 1; x++) {
    const c = cell(x, y);
    if (!TABLE[c]) continue;
    for (const [a, b] of TABLE[c]) {
      segments.push([
        [2 * x + a[0], 2 * y + a[1]],
        [2 * x + b[0], 2 * y + b[1]],
      ]);
    }
  }
}

const key = (p) => `${p[0]},${p[1]}`;
const byPoint = new Map();
for (const seg of segments) {
  for (const end of [0, 1]) {
    const k = key(seg[end]);
    if (!byPoint.has(k)) byPoint.set(k, []);
    byPoint.get(k).push(seg);
  }
}

const used = new Set();
const loops = [];
for (const seg of segments) {
  if (used.has(seg)) continue;
  used.add(seg);
  const loop = [seg[0], seg[1]];
  let end = seg[1];
  while (key(end) !== key(loop[0])) {
    const next = byPoint.get(key(end)).find((s) => !used.has(s));
    if (!next) break;
    used.add(next);
    end = key(next[0]) === key(end) ? next[1] : next[0];
    loop.push(end);
  }
  if (loop.length > 8) loops.push(loop);
}

const area = (loop) => {
  let sum = 0;
  for (let i = 0; i < loop.length - 1; i++) {
    sum += loop[i][0] * loop[i + 1][1] - loop[i + 1][0] * loop[i][1];
  }
  return sum / 2;
};
const inside = (p, loop) => {
  let hit = false;
  for (let i = 0, j = loop.length - 2; i < loop.length - 1; j = i++) {
    const [xi, yi] = loop[i];
    const [xj, yj] = loop[j];
    if (yi > p[1] !== yj > p[1] && p[0] < ((xj - xi) * (p[1] - yi)) / (yj - yi) + xi) hit = !hit;
  }
  return hit;
};

// Douglas-Peucker, keeping the shape within roughly a cell.
function simplify(loop, tolerance) {
  // A closed loop repeats its first point; dropping that duplicate keeps the
  // first segment from degenerating to zero length.
  const closed = key(loop[0]) === key(loop[loop.length - 1]);
  const pts = closed ? loop.slice(0, -1) : loop.slice();
  const keep = new Array(pts.length).fill(false);
  keep[0] = keep[pts.length - 1] = true;
  const stack = [[0, pts.length - 1]];
  while (stack.length) {
    const [a, b] = stack.pop();
    let max = 0;
    let at = -1;
    const [x1, y1] = pts[a];
    const [x2, y2] = pts[b];
    const len = Math.hypot(x2 - x1, y2 - y1) || 1;
    for (let i = a + 1; i < b; i++) {
      const d = Math.abs((y2 - y1) * pts[i][0] - (x2 - x1) * pts[i][1] + x2 * y1 - y2 * x1) / len;
      if (d > max) {
        max = d;
        at = i;
      }
    }
    if (max > tolerance && at > 0) {
      keep[at] = true;
      stack.push([a, at], [at, b]);
    }
  }
  const out = pts.filter((_, i) => keep[i]);
  return closed ? [...out, out[0]] : out;
}

const shapes = loops.map((loop) => {
  const depth = loops.reduce((n, other) => (other === loop ? n : n + (inside(loop[0], other) ? 1 : 0)), 0);
  return { loop: simplify(loop, 1.6), hole: depth % 2 === 1 };
});

// Fit the union of the contours into the viewport with a margin.
const xs = shapes.flatMap((s) => s.loop.map((p) => p[0]));
const ys = shapes.flatMap((s) => s.loop.map((p) => p[1]));
const minX = Math.min(...xs);
const maxX = Math.max(...xs);
const minY = Math.min(...ys);
const maxY = Math.max(...ys);
const margin = VIEW * 0.1;
const scale = Math.min((VIEW - margin * 2) / (maxX - minX), (VIEW - margin * 2) / (maxY - minY));
const ox = (VIEW - (maxX - minX) * scale) / 2;
const oy = (VIEW - (maxY - minY) * scale) / 2;
const px = (p) => [((p[0] - minX) * scale + ox).toFixed(2), ((p[1] - minY) * scale + oy).toFixed(2)];

const path = shapes
  .map((shape) => {
    const pts = shape.loop.map(px);
    return `M${pts[0][0]} ${pts[0][1]}` + pts.slice(1).map((p) => `L${p[0]} ${p[1]}`).join('') + 'Z';
  })
  .join('');

const xml = `<?xml version="1.0" encoding="utf-8"?>
<!-- The Skyward mark as a flat silhouette: Android tints the notification
     small icon, so it has to be a single-colour shape with no interior. -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="${VIEW}"
    android:viewportHeight="${VIEW}">
  <path
      android:fillColor="#FFFFFF"
      android:fillType="evenOdd"
      android:pathData="${path}" />
</vector>
`;
writeFileSync(outPath, xml);
console.log(`${outPath}: ${shapes.length} contours (${shapes.filter((s) => s.hole).length} holes), ${xml.length} bytes`);

// Turns the logo artwork (a photo/export on a white background) into a
// transparent PNG: un-premultiplies against white, then trims to the artwork.
// Usage: node tool/prepare_logo.mjs <source.jpg> [out.png] [long-edge px]
import { chromium } from 'playwright-core';
import { readFileSync, writeFileSync } from 'node:fs';

const source = process.argv[2];
const out = process.argv[3] || 'site/mark.png';
const size = Number(process.argv[4] || 512);
if (!source) {
  console.error('usage: node tool/prepare_logo.mjs <source.jpg> [out.png] [px]');
  process.exit(64);
}
const dataUrl = `data:image/jpeg;base64,${readFileSync(source).toString('base64')}`;

const browser = await chromium.launch({ executablePath: '/usr/bin/chromium', args: ['--no-sandbox'] });
const page = await browser.newPage();
await page.setContent('<!doctype html><html><body></body></html>');

const result = await page.evaluate(
  async ({ dataUrl, size }) => {
    const img = new Image();
    await new Promise((resolve, reject) => {
      img.onload = resolve;
      img.onerror = reject;
      img.src = dataUrl;
    });
    const canvas = document.createElement('canvas');
    canvas.width = img.naturalWidth;
    canvas.height = img.naturalHeight;
    const ctx = canvas.getContext('2d', { willReadFrequently: true });
    ctx.drawImage(img, 0, 0);
    const { data } = ctx.getImageData(0, 0, canvas.width, canvas.height);

    let minX = canvas.width;
    let minY = canvas.height;
    let maxX = 0;
    let maxY = 0;
    for (let y = 0; y < canvas.height; y++) {
      for (let x = 0; x < canvas.width; x++) {
        const i = (y * canvas.width + x) * 4;
        const r = data[i];
        const g = data[i + 1];
        const b = data[i + 2];
        const min = Math.min(r, g, b);
        const a = (255 - min) / 255;
        if (a < 0.02) {
          data[i + 3] = 0;
          continue;
        }
        // observed = a*colour + (1-a)*255  ->  recover colour
        const inv = 1 / Math.max(a, 0.004);
        data[i] = Math.min(255, Math.max(0, (r - (1 - a) * 255) * inv));
        data[i + 1] = Math.min(255, Math.max(0, (g - (1 - a) * 255) * inv));
        data[i + 2] = Math.min(255, Math.max(0, (b - (1 - a) * 255) * inv));
        data[i + 3] = Math.round(a * 255);
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }

    const pad = Math.round((maxX - minX) * 0.06);
    minX = Math.max(0, minX - pad);
    minY = Math.max(0, minY - pad);
    maxX = Math.min(canvas.width - 1, maxX + pad);
    maxY = Math.min(canvas.height - 1, maxY + pad);
    const w = maxX - minX + 1;
    const h = maxY - minY + 1;

    ctx.putImageData(new ImageData(data, canvas.width, canvas.height), 0, 0);
    const trim = ctx.getImageData(minX, minY, w, h);

    const scale = size / Math.max(w, h);
    const outCanvas = document.createElement('canvas');
    outCanvas.width = Math.round(w * scale);
    outCanvas.height = Math.round(h * scale);
    const tmp = document.createElement('canvas');
    tmp.width = w;
    tmp.height = h;
    tmp.getContext('2d').putImageData(trim, 0, 0);
    outCanvas.getContext('2d').drawImage(tmp, 0, 0, outCanvas.width, outCanvas.height);
    return { url: outCanvas.toDataURL('image/png'), w: outCanvas.width, h: outCanvas.height };
  },
  { dataUrl, size },
);

writeFileSync(out, Buffer.from(result.url.split(',')[1], 'base64'));
console.log(`${out} ${result.w}x${result.h}`);
await browser.close();

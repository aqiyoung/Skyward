// Builds every launcher icon from the site mark (site/mark.png).
//
// One composition — a warm gradient tile with the flame centred — is rendered
// at each size the platforms expect: the Android adaptive layers (background,
// foreground, monochrome), the legacy and TV mipmaps, the macOS app icon set,
// the Windows .ico and the in-app icon.
//
// Usage: node tool/build_app_icon.mjs
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname } from 'node:path';
import { chromium } from 'playwright-core';

const root = process.cwd();
const markPath = `${root}/site/mark.png`;
const mark = readFileSync(markPath).toString('base64');

const TILE = ['#2e1608', '#150a05']; // matches the site's dark theme
const MONO = '#ffffff';

const browser = await chromium.launch({ executablePath: '/usr/bin/chromium', args: ['--no-sandbox'] });
const page = await browser.newPage();
await page.setContent('<!doctype html><html><body></body></html>');

async function render({ size, flame = true, background = true, mono = false, glow = true }) {
  const dataUrl = await page.evaluate(
    async ({ mark, size, flame, background, mono, glow, tile, monoColor }) => {
      const img = new Image();
      await new Promise((resolve, reject) => {
        img.onload = resolve;
        img.onerror = reject;
        img.src = `data:image/png;base64,${mark}`;
      });
      const canvas = document.createElement('canvas');
      canvas.width = size;
      canvas.height = size;
      const ctx = canvas.getContext('2d');
      if (background) {
        const g = ctx.createLinearGradient(0, 0, size, size);
        g.addColorStop(0, tile[0]);
        g.addColorStop(1, tile[1]);
        ctx.fillStyle = g;
        ctx.fillRect(0, 0, size, size);
        if (glow) {
          const r = ctx.createRadialGradient(size / 2, size / 2, 0, size / 2, size / 2, size * 0.62);
          r.addColorStop(0, 'rgba(255,120,50,0.22)');
          r.addColorStop(1, 'rgba(255,120,50,0)');
          ctx.fillStyle = r;
          ctx.fillRect(0, 0, size, size);
        }
      }
      if (flame) {
        const ratio = img.naturalWidth / img.naturalHeight;
        const dw = size * 0.66;
        const dh = dw / ratio;
        if (mono) {
          ctx.drawImage(img, (size - dw) / 2, (size - dh) / 2, dw, dh);
          // Keep only the flame's shape and colour it in one flat tone.
          ctx.globalCompositeOperation = 'source-in';
          ctx.fillStyle = monoColor;
          ctx.fillRect(0, 0, size, size);
          ctx.globalCompositeOperation = 'source-over';
        } else {
          ctx.drawImage(img, (size - dw) / 2, (size - dh) / 2, dw, dh);
        }
      }
      return canvas.toDataURL('image/png').split(',')[1];
    },
    { mark, size, flame, background, mono, glow, tile: TILE, monoColor: MONO },
  );
  return Buffer.from(dataUrl, 'base64');
}

async function renderWebp(size) {
  return page.evaluate(
    async (size) => {
      const canvas = document.createElement('canvas');
      canvas.width = size;
      canvas.height = size;
      const ctx = canvas.getContext('2d');
      const img = new Image();
      await new Promise((resolve, reject) => {
        img.onload = resolve;
        img.onerror = reject;
        img.src = window.__iconFull;
      });
      ctx.drawImage(img, 0, 0, size, size);
      return canvas.toDataURL('image/webp', 0.92).split(',')[1];
    },
    size,
  );
}

const out = (file) => {
  mkdirSync(dirname(file), { recursive: true });
  return file;
};

function write(file, buf) {
  writeFileSync(out(file), buf);
  console.log(`${file} ${buf.length}`);
}

// --- in-app icon and the macOS set -------------------------------------------------
const full = {};
for (const size of [1024, 512, 256, 128, 64, 32, 16]) full[size] = await render({ size });
write(`${root}/assets/images/icon.png`, full[1024]);
for (const size of [1024, 512, 256, 128, 64, 32, 16]) {
  write(`${root}/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_${size}.png`, full[size]);
}

// --- Windows .ico (PNG entries, which Vista and later accept) ----------------------
const icoSizes = [16, 24, 32, 48, 64, 128, 256];
const images = [];
for (const size of icoSizes) images.push({ size, png: size <= 256 ? full[size] ?? (await render({ size })) : null });
function buildIco(list) {
  const header = Buffer.alloc(6 + 16 * list.length);
  header.writeUInt16LE(0, 0);
  header.writeUInt16LE(1, 2);
  header.writeUInt16LE(list.length, 4);
  let offset = header.length;
  list.forEach((item, i) => {
    const e = 6 + i * 16;
    header.writeUInt8(item.size >= 256 ? 0 : item.size, e);
    header.writeUInt8(item.size >= 256 ? 0 : item.size, e + 1);
    header.writeUInt8(0, e + 2);
    header.writeUInt8(0, e + 3);
    header.writeUInt16LE(1, e + 4);
    header.writeUInt16LE(32, e + 6);
    header.writeUInt32LE(item.png.length, e + 8);
    header.writeUInt32LE(offset, e + 12);
    offset += item.png.length;
  });
  return Buffer.concat([header, ...list.map((item) => item.png)]);
}
const ico = buildIco(images);
write(`${root}/assets/images/icon.ico`, ico);
write(`${root}/windows/runner/resources/app_icon.ico`, ico);

// --- Android -----------------------------------------------------------------------
const bg432 = await render({ size: 432, flame: false });
write(`${root}/android/app/src/main/res/drawable-xxxhdpi/ic_launcher_background.png`, bg432);
const fg432 = await render({ size: 432, background: false });
write(`${root}/android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png`, fg432);
write(`${root}/android/app/src/main/res/drawable-nodpi/splash_icon.png`, fg432);
const mono432 = await render({ size: 432, background: false, mono: true });
write(`${root}/android/app/src/main/res/drawable-xxxhdpi/ic_launcher_monochrome.png`, mono432);

// Legacy and TV mipmaps: full composition, and the TV banner.
await page.evaluate(async (b64) => {
  window.__iconFull = `data:image/png;base64,${b64}`;
}, full[1024].toString('base64'));
for (const [dir, size] of [
  ['mdpi', 48], ['hdpi', 72], ['xhdpi', 96], ['xxhdpi', 144], ['xxxhdpi', 192],
]) {
  const webp = Buffer.from(await renderWebp(size), 'base64');
  write(`${root}/android/app/src/main/res/mipmap-${dir}/ic_launcher.webp`, webp);
  write(`${root}/android/app/src/main/res/mipmap-${dir}/ic_launcher_round.webp`, webp);
}
for (const [dir, size] of [
  ['television-mdpi', 80], ['television-hdpi', 120], ['television-xhdpi', 160],
  ['television-xxhdpi', 240], ['television-xxxhdpi', 320],
]) {
  write(`${root}/android/app/src/main/res/mipmap-${dir}/ic_launcher.webp`, Buffer.from(await renderWebp(size), 'base64'));
}
{
  const banner = await page.evaluate(async ({ mark, tile }) => {
    const img = new Image();
    await new Promise((resolve, reject) => { img.onload = resolve; img.onerror = reject; img.src = `data:image/png;base64,${mark}`; });
    const canvas = document.createElement('canvas');
    canvas.width = 320;
    canvas.height = 180;
    const ctx = canvas.getContext('2d');
    const g = ctx.createLinearGradient(0, 0, 320, 180);
    g.addColorStop(0, tile[0]);
    g.addColorStop(1, tile[1]);
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, 320, 180);
    const ratio = img.naturalWidth / img.naturalHeight;
    const dh = 180 * 0.66;
    const dw = dh * ratio;
    ctx.drawImage(img, (320 - dw) / 2, (180 - dh) / 2, dw, dh);
    return canvas.toDataURL('image/png').split(',')[1];
  }, { mark, tile: TILE });
  write(`${root}/android/app/src/main/res/mipmap-xhdpi/ic_banner.png`, Buffer.from(banner, 'base64'));
}

await browser.close();

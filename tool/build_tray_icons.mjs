// Regenerates the tray/status icons and the remaining launcher art from the
// site mark. The old sources were the blue globe; every runtime icon now uses
// the flame.
//
// Usage: node tool/build_tray_icons.mjs
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright-core';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const mark = readFileSync(join(root, 'site/mark.png')).toString('base64');
const TILE = ['#2e1608', '#150a05'];

function ico(list) {
  const header = Buffer.alloc(6 + 16 * list.length);
  header.writeUInt16LE(0, 0);
  header.writeUInt16LE(1, 2);
  header.writeUInt16LE(list.length, 4);
  let offset = header.length;
  list.forEach((item, i) => {
    const e = 6 + i * 16;
    header.writeUInt8(item.size >= 256 ? 0 : item.size, e);
    header.writeUInt8(item.size >= 256 ? 0 : item.size, e + 1);
    header.writeUInt16LE(1, e + 4);
    header.writeUInt16LE(32, e + 6);
    header.writeUInt32LE(item.png.length, e + 8);
    header.writeUInt32LE(offset, e + 12);
    offset += item.png.length;
  });
  return Buffer.concat([header, ...list.map((item) => item.png)]);
}

const browser = await chromium.launch({ executablePath: '/usr/bin/chromium', args: ['--no-sandbox'] });
const page = await browser.newPage();
await page.setContent('<!doctype html><html><body></body></html>');

async function draw({ size, opacity = 1, dot = null, plate = true, silhouette = false }) {
  const dataUrl = await page.evaluate(
    async ({ mark, size, opacity, dot, plate, tile, silhouette }) => {
      const img = new Image();
      await new Promise((resolve, reject) => {
        img.onload = resolve;
        img.onerror = reject;
        img.src = `data:image/png;base64,${mark}`;
      });
      const canvas = document.createElement('canvas');
      canvas.width = canvas.height = size;
      const ctx = canvas.getContext('2d');
      ctx.globalAlpha = opacity;
      if (plate) {
        const g = ctx.createLinearGradient(0, 0, size, size);
        g.addColorStop(0, tile[0]);
        g.addColorStop(1, tile[1]);
        ctx.fillStyle = g;
        ctx.fillRect(0, 0, size, size);
      }
      const ratio = img.naturalWidth / img.naturalHeight;
      const dw = size * (plate ? 0.68 : 0.86);
      const dh = dw / ratio;
      ctx.drawImage(img, (size - dw) / 2, (size - dh) / 2 - (plate ? size * 0.04 : 0), dw, dh);
      if (silhouette) {
        const data = ctx.getImageData(0, 0, size, size);
        for (let i = 0; i < data.data.length; i += 4) {
          if (data.data[i + 3] > 0) {
            data.data[i] = 255;
            data.data[i + 1] = 255;
            data.data[i + 2] = 255;
          }
        }
        ctx.putImageData(data, 0, 0);
      }
      ctx.globalAlpha = 1;
      if (dot) {
        const cx = size * 201 / 256;
        const cy = size * 201 / 256;
        ctx.fillStyle = '#E9F6FE';
        ctx.beginPath();
        ctx.arc(cx, cy, size * 31 / 256, 0, Math.PI * 2);
        ctx.fill();
        ctx.fillStyle = dot;
        ctx.beginPath();
        ctx.arc(cx, cy, size * 22 / 256, 0, Math.PI * 2);
        ctx.fill();
      }
      return canvas.toDataURL('image/png').split(',')[1];
    },
    { mark, size, opacity, dot, plate, tile: TILE, silhouette },
  );
  return Buffer.from(dataUrl, 'base64');
}

const out = (file) => {
  mkdirSync(dirname(file), { recursive: true });
  return file;
};
const write = (file, buf) => writeFileSync(out(file), buf);

// Source tile and silhouette used by the status SVGs and the macOS templates.
write(`${root}/assets_source/images/icon/status_tile.png`, await draw({ size: 256 }));
write(`${root}/assets_source/images/icon/mark.png`, await draw({ size: 256, plate: false, silhouette: true }));

// The Play Store listing needs a square, opaque 512px PNG.
write(
  `${root}/android/app/src/main/ic_launcher-playstore.png`,
  await draw({ size: 512 }),
);

// Tray icons: status_1 is dimmed with a grey dot, 2 blue, 3 teal.
const statuses = [
  ['status_1', 0.55, '#8A94A6'],
  ['status_2', 1, '#2F80FF'],
  ['status_3', 1, '#14B8A6'],
];
for (const [name, opacity, dot] of statuses) {
  for (const scale of [1, 2, 3, 4]) {
    const size = 18 * scale;
    const dir = scale === 1 ? '' : `${scale}.0x/`;
    write(
      `${root}/assets/images/tray/unix/${dir}${name}.png`,
      await draw({ size, opacity, dot }),
    );
  }
  write(
    `${root}/assets/images/tray/windows/${name}.ico`,
    ico(
      await Promise.all(
        [16, 20, 24, 32, 40, 48, 64].map(async (size) => ({
          size,
          png: await draw({ size, opacity, dot }),
        })),
      ),
    ),
  );
}

// macOS template: a monochrome flame for the disconnected state.
for (const scale of [1, 2, 3, 4]) {
  const size = 18 * scale;
  const dir = scale === 1 ? '' : `${scale}.0x/`;
  write(
    `${root}/assets/images/tray/macos/${dir}status_1.png`,
    await draw({ size, plate: false, silhouette: true }),
  );
}

await browser.close();
console.log('tray icons and remaining launcher art regenerated');

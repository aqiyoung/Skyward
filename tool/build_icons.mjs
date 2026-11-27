// Renders the transparent mark (site/mark.png) into the icons the page cites:
// a square favicon, an Apple touch icon on a dark tile, and a social card.
// Usage: node tool/build_icons.mjs [mark.png] [output dir]
import { chromium } from 'playwright-core';
import { readFileSync, writeFileSync } from 'node:fs';

const markPath = process.argv[2] || 'site/mark.png';
const outDir = process.argv[3] || 'site';
const TILE = '#1a120d';
const mark = readFileSync(markPath).toString('base64');

const browser = await chromium.launch({ executablePath: '/usr/bin/chromium', args: ['--no-sandbox'] });
const page = await browser.newPage();
await page.setContent('<!doctype html><html><body></body></html>');

async function render(file, width, height, mode) {
  const png = await page.evaluate(
    async ({ mark, width, height, tile, mode }) => {
      const img = new Image();
      await new Promise((resolve, reject) => {
        img.onload = resolve;
        img.onerror = reject;
        img.src = `data:image/png;base64,${mark}`;
      });
      const canvas = document.createElement('canvas');
      canvas.width = width;
      canvas.height = height;
      const ctx = canvas.getContext('2d');
      const ratio = img.naturalWidth / img.naturalHeight;
      const fit = (pad) => {
        let dw = width * (1 - pad);
        let dh = dw / ratio;
        if (dh > height * (1 - pad)) {
          dh = height * (1 - pad);
          dw = dh * ratio;
        }
        ctx.drawImage(img, (width - dw) / 2, (height - dh) / 2, dw, dh);
      };
      if (mode === 'icon') {
        ctx.fillStyle = tile;
        ctx.fillRect(0, 0, width, height);
        fit(0.2);
      } else if (mode === 'og') {
        const g = ctx.createLinearGradient(0, 0, width, height);
        g.addColorStop(0, '#241610');
        g.addColorStop(1, tile);
        ctx.fillStyle = g;
        ctx.fillRect(0, 0, width, height);
        ctx.save();
        ctx.fillStyle = 'rgba(255,140,60,0.16)';
        ctx.filter = 'blur(60px)';
        ctx.beginPath();
        ctx.ellipse(width * 0.5, height * 0.5, 330, 260, 0, 0, Math.PI * 2);
        ctx.fill();
        ctx.restore();
        fit(0.32);
      } else {
        fit(0.12);
      }
      return canvas.toDataURL('image/png').split(',')[1];
    },
    { mark, width, height, tile: TILE, mode },
  );
  writeFileSync(`${outDir}/${file}`, Buffer.from(png, 'base64'));
  console.log(`${outDir}/${file} ${width}x${height}`);
}

await render('favicon.png', 64, 64, 'plain');
await render('apple-touch-icon.png', 180, 180, 'icon');
await render('og.png', 1200, 630, 'og');
await browser.close();

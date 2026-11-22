// Renders site/mark.svg to the PNG icons the page references.
// Usage: node tool/render_mark.mjs   (Chromium is required)
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright-core';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const svg = readFileSync(join(root, 'site/mark.svg'), 'utf8');
const SIZES = [
  { file: 'logo.png', size: 128 },
  { file: 'apple-touch-icon.png', size: 180 },
];

const browser = await chromium.launch({ args: ['--no-sandbox'] });
for (const { file, size } of SIZES) {
  const full = await browser.newPage({ viewport: { width: 480, height: 480 } });
  await full.setContent(`<!doctype html><html><body style="margin:0">${svg}</body></html>`);
  const mark = await full.$('svg');
  const png = await mark.screenshot({ type: 'png', omitBackground: true });
  await full.close();

  // Downscale through an <img> so the edges are resampled, not cropped.
  const small = await browser.newPage({ viewport: { width: size, height: size } });
  await small.setContent(
    `<!doctype html><html><body style="margin:0"><img src="data:image/png;base64,${png.toString('base64')}" width="${size}" height="${size}"></body></html>`,
  );
  const img = await small.$('img');
  writeFileSync(join(root, 'site', file), await img.screenshot({ type: 'png', omitBackground: true }));
  await small.close();
  console.log(`site/${file} (${size}px)`);
}
await browser.close();

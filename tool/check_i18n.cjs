const fs = require('fs');
const html = fs.readFileSync('site/index.html', 'utf8');
const src = fs.readFileSync('site/assets/shared.js', 'utf8');
const attrs = ['data-i18n', 'data-i18n-alt', 'data-i18n-placeholder'];
const used = new Set();
for (const attr of attrs) {
  const re = new RegExp(attr + '="([A-Za-z0-9_]+)"', 'g');
  for (const m of html.matchAll(re)) used.add(m[1]);
}
const js = fs.readFileSync('site/assets/site.js', 'utf8');
for (const m of js.matchAll(/\bt\(\s*'([A-Za-z0-9_]+)'/g)) used.add(m[1]);
for (const m of js.matchAll(/\bt\(\s*"([A-Za-z0-9_]+)"/g)) used.add(m[1]);
const blocks = {};
for (const marker of ['    en: {', '    zh: {']) {
  const s = src.indexOf(marker);
  const e = src.indexOf('\n    },', s);
  blocks[marker.slice(4, 6)] = new Set([...src.slice(s, e).matchAll(/^      ([A-Za-z0-9_]+):/gm)].map((m) => m[1]));
}
let failed = false;
for (const [lang, keys] of Object.entries(blocks)) {
  const missing = [...used].filter((k) => !keys.has(k));
  if (missing.length) {
    failed = true;
    console.error(`${lang} is missing i18n keys: ${missing.join(', ')}`);
  }
}
if (failed) process.exit(1);
console.log(`i18n keys present in both languages (${used.size} used)`);

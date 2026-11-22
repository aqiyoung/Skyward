import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { runInNewContext } from 'node:vm';

const [out, siteArg] = process.argv.slice(2);
if (!out || !siteArg) {
  console.error('usage: render_site.mjs <site dir> <site url>');
  process.exit(64);
}
const siteUrl = new URL(siteArg.replace(/\/*$/, '/')).href;

const PAGES = [
  { lang: 'en', locale: 'en', ogLocale: 'en_US', path: '', toggle: '?lang=en' },
  { lang: 'zh', locale: 'zh-CN', ogLocale: 'zh_CN', path: 'zh/', toggle: 'zh/' },
];

const sandbox = {};
runInNewContext(readFileSync(join(out, 'assets/shared.js'), 'utf8'), sandbox);
const { STRINGS, escapeHtml: escape } = sandbox.SkywardSite;

const template = readFileSync(join(out, 'index.html'), 'utf8');

function structuredData(t, page) {
  return {
    '@context': 'https://schema.org',
    '@type': 'SoftwareApplication',
    name: 'Skyward',
    url: siteUrl + page.path,
    applicationCategory: 'UtilitiesApplication',
    operatingSystem: 'Android, Windows, macOS, Linux',
    description: t.heroLede,
    license: 'https://github.com/aqiyoung/Skyward/blob/main/LICENSE',
    isAccessibleForFree: true,
  };
}

function render(page) {
  const t = STRINGS[page.lang];
  const text = (key) => escape(t[key] ?? key);
  const up = '../'.repeat(page.path.split('/').length - 1);
  const other = PAGES.find((item) => item !== page);

  let html = template;
  html = html.replace(/<html lang="[^"]*">/, `<html lang="${page.locale}" data-page-lang="${page.lang}" data-base="${up}">`);
  html = html.replace(/<title>[^<]*<\/title>/, `<title>${text('pageTitle')}</title>`);
  html = html.replace(/(<meta name="description" content=")[^"]*/, `$1${text('pageDescription')}`);
  html = html.replace(/(<meta property="og:description" content=")[^"]*/, `$1${text('heroLede')}`);
  html = html.replace(/(<meta property="og:image" content=")[^"]*/, `$1${siteUrl}og.png`);

  const head = [
    `  <link rel="canonical" href="${siteUrl}${page.path}">`,
    ...PAGES.map((item) => `  <link rel="alternate" hreflang="${item.locale}" href="${siteUrl}${item.path}">`),
    `  <link rel="alternate" hreflang="x-default" href="${siteUrl}">`,
    `  <meta property="og:url" content="${siteUrl}${page.path}">`,
    `  <meta property="og:locale" content="${page.ogLocale}">`,
    `  <script type="application/ld+json">${JSON.stringify(structuredData(t, page)).replace(/</g, '\\u003c')}</script>`,
  ];
  html = html.replace(/(<meta name="twitter:card"[^>]*>\n)/, `$1${head.join('\n')}\n`);

  // Static strings. Everything else is rendered client-side from release.json
  // and CHANGELOG.md, so the template carries no second copy of the content.
  html = html.replace(
    /(<(\w+)\b[^>]*\bdata-i18n="(\w+)"[^>]*>)[^<]*(<\/\2>)/g,
    (_match, open, _tag, key, close) => open + text(key) + close,
  );
  html = html.replace(
    /(\balt=")[^"]*("[^>]*data-i18n-alt="(\w+)")/g,
    (_match, prefix, rest, key) => `${prefix}${text(key)}${rest}`,
  );
  html = html.replace(
    /(\bplaceholder=")[^"]*("[^>]*data-i18n-placeholder="(\w+)")/g,
    (_match, prefix, rest, key) => `${prefix}${text(key)}${rest}`,
  );

  // The language switch is a plain link between the two built pages.
  html = html.replace(
    /<button class="tool" id="lang-toggle"[^>]*>[^<]*<\/button>/,
    `<a class="tool" id="lang-toggle" href="${up}${other.toggle}" hreflang="${other.locale}" lang="${other.locale}" ` +
      `aria-label="${escape(t.langLabel)}">${escape(t.langToggle)}</a>`,
  );

  // Relative asset URLs must survive the zh/ subdirectory.
  html = html.replace(/\b(href|src|srcset)="(?![a-z]+:|#|\/|\.)/g, `$1="${up}`);
  return html;
}

for (const page of PAGES) {
  const dir = join(out, page.path);
  mkdirSync(dir, { recursive: true });
  writeFileSync(join(dir, 'index.html'), render(page));
}

const alternates = (page) =>
  PAGES.map(
    (item) =>
      `    <xhtml:link rel="alternate" hreflang="${item.locale}" href="${siteUrl}${item.path}"/>`,
  ).join('\n');

writeFileSync(
  join(out, 'sitemap.xml'),
  '<?xml version="1.0" encoding="UTF-8"?>\n' +
    '<urlset xmlns="http://www.s3.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">\n' +
    PAGES.map((p) => `  <url><loc>${siteUrl}${p.path}</loc>\n${alternates(p)}\n  </url>\n`).join('') +
    '</urlset>\n',
);

/* Skyward site — data, rendering and interaction.
   Static copy comes from assets/shared.js (STRINGS); everything that depends on
   the release is fetched at runtime from release.json, CHANGELOG.md and — for the
   check — the release's own SHA256SUMS. */

const { REPO, STRINGS, parseChangelog, translate } = globalThis.SkywardSite;

const SITE = new URL('.', document.baseURI).href;
const PLATFORMS = ['windows', 'macos', 'linux', 'android'];
const OS_NAMES = { windows: 'Windows', macos: 'macOS', linux: 'Linux', android: 'Android' };
const OS_SHORT = { windows: 'W', macos: 'M', linux: 'L', android: 'A' };

const state = { lang: 'en', platform: 'windows', arch: 'x64' };

const $ = (id) => document.getElementById(id);
const t = (key, ...args) => translate(state.lang, key, ...args);

function applyStaticText() {
  document.documentElement.lang = state.lang === 'zh' ? 'zh-CN' : 'en';
  for (const node of document.querySelectorAll('[data-i18n]')) node.textContent = t(node.dataset.i18n);
  for (const node of document.querySelectorAll('[data-i18n-alt]')) node.alt = t(node.dataset.i18nAlt);
  for (const node of document.querySelectorAll('[data-i18n-placeholder]')) node.placeholder = t(node.dataset.i18nPlaceholder);
}

function el(tag, props = {}, ...children) {
  const node = document.createElement(tag);
  for (const [key, value] of Object.entries(props)) {
    if (value == null) continue;
    if (key === 'class') node.className = value;
    else if (key === 'text') node.textContent = value;
    else if (key === 'html') node.innerHTML = value;
    else if (key.startsWith('on')) node.addEventListener(key.slice(2), value);
    else node.setAttribute(key, value);
  }
  for (const child of children.flat()) {
    if (child == null) continue;
    node.append(child.nodeType ? child : document.createTextNode(String(child)));
  }
  return node;
}

const goArch = (arch) => (arch === 'arm64' ? 'arm64' : 'amd64');

function buildsFor(platform, arch) {
  switch (platform) {
    case 'android':
      return [
        { id: 'android-arm64-v8a.apk', kind: 'APK', title: 'arm64-v8a', note: 'noteAndroidArm64', rec: true },
        { id: 'android-armeabi-v7a.apk', kind: 'APK', title: 'armeabi-v7a', note: 'noteAndroidArm32' },
        { id: 'android-x86_64.apk', kind: 'APK', title: 'x86_64', note: 'noteAndroidX64' },
      ];
    case 'windows':
      return [
        { id: `windows-${goArch(arch)}-setup.exe`, kind: 'Installer', titleKey: 'winSetup', note: 'noteWinSetup', rec: true },
        { id: `windows-${goArch(arch)}.zip`, kind: 'Portable ZIP', titleKey: 'winPortable', note: 'noteWinPortable' },
      ];
    case 'macos':
      return [
        { id: 'macos-arm64.dmg', kind: 'DMG', title: 'Apple Silicon', note: 'noteMacArm', rec: arch === 'arm64' },
        { id: 'macos-amd64.dmg', kind: 'DMG', title: 'Intel', note: 'noteMacIntel', rec: arch !== 'arm64' },
      ];
    case 'linux':
      return [
        { id: `linux-${goArch(arch)}.deb`, kind: 'DEB', title: 'Debian / Ubuntu', arch: '.deb', note: 'noteDeb', rec: true },
        { id: `linux-${goArch(arch)}.rpm`, kind: 'RPM', title: 'Fedora / openSUSE', arch: '.rpm', note: 'noteRpm' },
        { id: `linux-${goArch(arch)}.AppImage`, kind: 'AppImage', title: 'AppImage', note: 'noteAppImage' },
      ];
    default:
      return [];
  }
}

function formatSize(bytes) {
  if (!bytes && bytes !== 0) return '';
  return bytes > 1048576 ? `${(bytes / 1048576).toFixed(1)} MB` : `${Math.round(bytes / 1024)} KB`;
}

function formatDate(value, lang) {
  if (!value) return '';
  return new Intl.DateTimeFormat(lang === 'zh' ? 'zh-CN' : 'en', {
    year: 'numeric',
    month: lang === 'zh' ? 'long' : 'short',
    day: 'numeric',
    timeZone: 'UTC',
  }).format(new Date(`${value}T00:00:00Z`));
}

async function copyText(text, button) {
  let ok = false;
  try {
    await navigator.clipboard.writeText(text);
    ok = true;
  } catch {
    const area = el('textarea', { readonly: true, style: 'position:fixed;opacity:0' });
    area.value = text;
    document.body.append(area);
    area.select();
    try {
      ok = document.execCommand('copy');
    } catch {}
    area.remove();
  }
  if (!button) return ok;
  const label = button.querySelector('.btn-label') || button;
  const previous = label.textContent;
  label.textContent = t('copied');
  button.classList.add('done');
  setTimeout(() => {
    label.textContent = previous;
    button.classList.remove('done');
  }, 1600);
  return ok;
}

function renderRelease(feed) {
  const host = $('release');
  const { status, current, failure, detected } = feed;
  const loaded = status !== 'loading' && !!detected;
  host.dataset.state = status === 'loading' ? 'loading' : failure ? 'error' : 'ready';
  host.setAttribute('aria-busy', String(status === 'loading'));

  const heading =
    status === 'loading'
      ? ''
      : failure === 'none'
        ? t('relEmpty')
        : failure
          ? t('relError')
          : current?.tag || current?.name || '';
  $('rel-ver').textContent = heading;

  let meta = t('relAsking');
  if (loaded) {
    if (failure === 'rate') meta = t('relRate');
    else if (failure === 'none') meta = t('relNone');
    else if (failure) meta = t('relOffline');
    else meta = `${current.prerelease ? t('relPre') : ''}${formatDate(current.published, state.lang)}`;
  }
  $('rel-meta').textContent = meta;

  const best = loaded && !failure && current ? current.best : undefined;
  const pick = $('pick');
  pick.hidden = !best;
  if (best) {
    pick.querySelector('.os').textContent = OS_SHORT[best.os];
    $('pick-name').textContent = `${OS_NAMES[best.os]} · ${best.kind}${best.arch ? ` · ${best.arch}` : ''}`;
    $('pick-meta').textContent = `${best.name} · ${formatSize(best.size)}`;
    $('pick-link').href = best.url;
  }

  $('rel-empty').hidden = !(loaded && (!current || (!current.assets?.length && detected.os !== 'ios')));
  $('rel-empty').textContent = !current || !current.assets?.length
    ? t('relNoAssets')
    : t('relIos');

  const seg = $('platform-seg');
  seg.hidden = !(loaded && !failure);
  seg.replaceChildren(
    ...feed.oses.map((os) =>
      el('button', {
        type: 'button',
        text: OS_NAMES[os],
        'data-os': os,
        'aria-pressed': String(state.platform === os),
        onclick: () => {
          state.platform = os;
          renderRelease(feed);
        },
      }),
    ),
  );

  renderAssets(feed);
}

function renderAssets(feed) {
  const list = $('files');
  const { status, current, failure } = feed;
  const assets = status === 'ready' && current ? (current.groups[state.platform] || []) : [];
  list.replaceChildren(
    ...assets.map((asset, index) =>
      el(
        'li',
        {},
        el(
          'a',
          { class: 'asset', href: asset.url, style: `--i:${index}` },
          el('span', { class: 'n', text: asset.name }),
          el('span', { class: 'k', text: `${asset.kind}${asset.arch ? ` · ${asset.arch}` : ''}` }),
          el('span', { class: 's', text: formatSize(asset.size) }),
          el('svg', {
            class: 'dl',
            viewBox: '0 0 24 24',
            'aria-hidden': 'true',
            html: '<path d="M12 4v11m0 0-4.5-4.5M12 15l4.5-4.5M5 19.5h14" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>',
          }),
        ),
      ),
    ),
  );
  list.hidden = status === 'ready' && !!failure;
  $('extras').replaceChildren(...extrasFor(state.platform));
}

function extrasFor(platform) {
  if (platform === 'android') {
    return [
      el(
        'div',
        { class: 'tip' },
        el('h3', { text: t('tipIntentTitle') }),
        el('p', { text: t('tipIntent') }),
        el('pre', {}, el('code', { text: ['com.threely.skyward.action.START', 'com.threely.skyward.action.STOP', 'com.threely.skyward.action.TOGGLE'].join('\n') })),
      ),
    ];
  }
  if (platform === 'linux') {
    return [
      el('div', { class: 'tip' }, el('h3', { text: t('tipTrayTitle') }), el('p', { text: t('noteLinuxTray') })),
    ];
  }
  return [];
}

function renderChangelog(versions) {
  const host = $('changelog');
  if (!versions.length) {
    host.replaceChildren(el('p', { class: 'cl-empty', text: t('clEmpty') }));
    $('cl-meta').textContent = '';
    return;
  }
  const [first, ...rest] = versions;
  const groups = (version) =>
    version.groups
      .map((group) => el('ul', { class: 'md-list' }, ...group.entries.map((entry) => el('li', { text: entry.text }))))
      .filter((list) => list.childNodes.length);
  host.replaceChildren(
    el(
      'section',
      { class: 'cl-card' },
      el(
        'div',
        { class: 'cl-head' },
        el('span', { class: 'cl-ver', text: first.tag }),
        el('span', { class: 'badge', text: t('clLatest') }),
        el('span', { class: 'cl-date', text: first.date || '' }),
        el('a', { class: 'btn btn-ghost btn-s cl-gh', href: `${REPO}/releases/tag/${first.tag}`, text: t('clOnGithub') }),
      ),
      el('div', { class: 'cl-body md' }, groups(first)),
    ),
    ...rest.map((version) =>
      el(
        'details',
        { class: 'cl-item' },
        el(
          'summary',
          {},
          el('span', { class: 'cl-v', text: version.tag }),
          el('span', { class: 'cl-date', text: version.date || '' }),
        ),
        el('div', { class: 'cl-body md' }, groups(version)),
      ),
    ),
  );
  const oldest = versions.filter((version) => version.date).slice(-1)[0];
  $('cl-meta').textContent = t('clMeta', versions.length, oldest ? formatDate(oldest.date, state.lang) : '');
}

function renderCards() {
  const cards = [
    { os: 'windows', body: 'cardWindows' },
    { os: 'macos', body: 'cardMacos' },
    { os: 'linux', body: 'cardLinux' },
    { os: 'android', body: 'cardAndroid' },
  ];
  $('cards').replaceChildren(
    ...cards.map((card, index) => {
      const builds = buildsFor(card.os, 'arm64');
      return el(
        'li',
        { class: 'pcard', style: `--i:${index}` },
        el('h3', { text: OS_NAMES[card.os] }),
        el('span', { class: 'fmt', text: builds.map((build) => build.kind).join(' · ') }),
        el('div', { class: 'arch' }, ...builds.map((build) => el('span', { text: build.arch || build.title }))),
        el('p', { text: t(card.body) }),
      );
    }),
  );
}

function renderPrereq() {
  const items = t('prereq');
  $('prereq').replaceChildren(...items.map((item) => el('li', { text: item })));
}

/* ---- SHA-256 check, following ReClash's flow: hash the file, then compare it
      with whatever the reader pasted from SHA256SUMS. ---- */
function verdict(host, status, title, detail = '') {
  host.className = `verdict pop ${status}`;
  host.innerHTML =
    '<span class="vi"><svg viewBox="0 0 24 24"><path d="' +
    (status === 'ok' ? 'M5 12.5l4.5 4.5L19 7.5' : status === 'bad' ? 'M7 7l10 10M17 7 7 17' : 'M12 7v6m0 4v.1') +
    '" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg></span>' +
    `<div><b>${title}</b>${detail ? `<code>${detail}</code>` : ''}</div>`;
}

async function verify(file) {
  const host = $('verdict');
  const nameNode = $('verify-name');
  nameNode.textContent = t('vfNamed', file.name);
  const done = async (hash) => {
    const text = $('sums').value.trim();
    if (!text) {
      verdict(host, 'info', t('vfHashed'), hash);
      return;
    }
    const lines = text.split(/\r?\n/).map((line) => line.trim()).filter(Boolean);
    let expected;
    for (const line of lines) {
      const pair = line.match(/^([a-f0-9]{64})\s+\*?(.+)$/i);
      if (pair && pair[2].split(/[\\/]/).pop() === file.name) {
        expected = pair[1].toLowerCase();
        break;
      }
    }
    if (!expected) {
      const all = text.match(/\b[a-f0-9]{64}\b/gi) || [];
      if (all.length === 1) expected = all[0].toLowerCase();
      else if (all.length) {
        verdict(host, 'bad', t('vfNoLine', file.name), hash);
        return;
      } else {
        verdict(host, 'bad', t('vfNoHash'));
        return;
      }
    }
    if (expected === hash) verdict(host, 'ok', t('vfMatch'), hash);
    else verdict(host, 'bad', t('vfMiss'), t('vfDiff', hash, expected));
  };
  verdict(host, 'info', t('vfHashing', file.name));
  try {
    const bytes = await file.arrayBuffer();
    const digest = await crypto.subtle.digest('SHA-256', bytes);
    await done([...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, '0')).join(''));
  } catch {
    verdict(host, 'bad', t('vfUnreadable'));
  }
}

function wire() {
  const input = $('verify-file');
  const drop = $('drop');
  let over = false;
  input.addEventListener('change', (event) => {
    const file = event.target.files && event.target.files[0];
    if (file) verify(file);
    input.value = '';
  });
  for (const type of ['dragenter', 'dragover']) {
    drop.addEventListener(type, (event) => {
      event.preventDefault();
      over = true;
      drop.classList.add('is-over');
    });
  }
  for (const type of ['dragleave', 'drop']) {
    drop.addEventListener(type, (event) => {
      event.preventDefault();
      over = false;
      drop.classList.remove('is-over');
    });
  }
  drop.addEventListener('drop', (event) => {
    const file = event.dataTransfer && event.dataTransfer.files && event.dataTransfer.files[0];
    if (file) verify(file);
  });

  $('sums').addEventListener('input', () => {
    const file = input.files && input.files[0];
    if (file) verify(file);
  });

  $('copy-unix').addEventListener('click', (event) => copyText($('t-unix').textContent, event.currentTarget));
  $('copy-win').addEventListener('click', (event) => copyText($('t-win').textContent, event.currentTarget));
  $('build-copy').addEventListener('click', (event) => copyText($('t-build').textContent, event.currentTarget));
}

/* ---- release feed: the same shape ReClash's shared/site/releases.ts reads ---- */
function classify(name) {
  const lower = name.toLowerCase();
  if (lower.includes('android') || lower.endsWith('.apk')) {
    if (lower.includes('arm64') || lower.includes('v8a')) return { os: 'android', kind: 'APK', arch: 'arm64-v8a' };
    if (lower.includes('armeabi') || lower.includes('v7a')) return { os: 'android', kind: 'APK', arch: 'armeabi-v7a' };
    if (lower.includes('x86_64')) return { os: 'android', kind: 'APK', arch: 'x86_64' };
    return { os: 'android', kind: 'APK', arch: '' };
  }
  if (lower.includes('windows') || lower.endsWith('.exe')) {
    const arch = lower.includes('arm64') ? 'arm64' : lower.includes('amd64') || lower.includes('x64') ? 'x64' : '';
    if (lower.endsWith('.zip')) return { os: 'windows', kind: 'Portable ZIP', arch };
    return { os: 'windows', kind: 'Installer', arch };
  }
  if (lower.includes('macos') || lower.endsWith('.dmg')) {
    const arch = lower.includes('arm64') || lower.includes('apple') ? 'arm64' : lower.includes('amd64') || lower.includes('intel') ? 'x64' : '';
    return { os: 'macos', kind: 'DMG', arch };
  }
  if (lower.includes('linux') || lower.endsWith('.deb') || lower.endsWith('.rpm') || lower.endsWith('.appimage')) {
    const arch = lower.includes('arm64') || lower.includes('aarch64') ? 'arm64' : lower.includes('amd64') || lower.includes('x64') ? 'x64' : '';
    const kind = lower.endsWith('.deb') ? 'DEB' : lower.endsWith('.rpm') ? 'RPM' : lower.endsWith('.appimage') ? 'AppImage' : 'File';
    return { os: 'linux', kind, arch };
  }
  return null;
}

function detectDevice() {
  const ua = navigator.userAgent.toLowerCase();
  if (/android/.test(ua)) return { os: 'android', arch: /arm64|aarch64/.test(ua) ? 'arm64' : '' };
  if (/windows|win32|win64/.test(ua)) return { os: 'windows', arch: /arm64/.test(ua) ? 'arm64' : 'x64' };
  if (/mac os|macintosh|darwin/.test(ua)) return { os: 'macos', arch: /arm64/.test(ua) ? 'arm64' : '' };
  if (/linux/.test(ua)) return { os: 'linux', arch: /arm64|aarch64/.test(ua) ? 'arm64' : 'x64' };
  if (/iphone|ipad|ios/.test(ua)) return { os: 'ios', arch: '' };
  return { os: 'windows', arch: 'x64' };
}

function buildFeed(meta) {
  const assets = (meta?.assets || [])
    .map((asset) => ({ ...asset, ...(classify(asset.name) || {}) }))
    .filter((asset) => asset.os);
  const groups = {};
  for (const asset of assets) (groups[asset.os] ||= []).push(asset);
  const oses = PLATFORMS.filter((os) => groups[os]);
  return {
    status: meta?.tag ? 'ready' : 'error',
    current: meta?.tag
      ? {
          tag: meta.tag,
          name: meta.tag,
          url: `${REPO}/releases/tag/${meta.tag}`,
          published: meta.publishedAt || '',
          prerelease: Boolean(meta.prerelease),
          assets,
          groups,
          best: bestAsset(groups, detectDevice()),
        }
      : undefined,
    failure: meta?.tag ? '' : 'none',
    oses,
    detected: detectDevice(),
  };
}

function score(asset, device) {
  let value = 0;
  if (asset.os !== device.os) return -1;
  value += 10;
  if (device.arch && asset.arch) value += asset.arch === device.arch ? 20 : -5;
  if (asset.kind === 'Installer' || asset.kind === 'DMG' || asset.kind === 'DEB' || asset.kind === 'APK') value += 8;
  return value;
}

function bestAsset(groups, device) {
  if (!device.os || !(device.os in groups)) return undefined;
  return groups[device.os].slice().sort((a, b) => score(b, device) - score(a, device))[0];
}

async function load() {
  const [meta, markdown] = await Promise.allSettled([
    fetch(new URL('release.json', SITE), { cache: 'no-cache' }).then((r) => (r.ok ? r.json() : null)),
    fetch(new URL('CHANGELOG.md', SITE), { cache: 'no-cache' }).then((r) => (r.ok ? r.text() : Promise.reject(r.status))),
  ]);

  const feed = buildFeed(meta.status === 'fulfilled' ? meta.value : null);
  if (feed.current) {
    state.platform = feed.current.best?.os || feed.detected.os || 'windows';
    state.arch = feed.current.best?.arch || feed.detected.arch || 'x64';
  }
  renderRelease(feed);

  if (markdown.status === 'fulfilled') {
    renderChangelog(parseChangelog(markdown.value));
  } else {
    $('changelog').replaceChildren(el('p', { class: 'cl-fail', text: t('clError') }));
    $('cl-meta').textContent = '';
  }

  renderCards();
  renderPrereq();
  $('year').textContent = String(new Date().getUTCFullYear());
}

/* ---- ReClash's motion, ported to the pieces a static page needs ---------
   Their runtime is ~1400 lines of scroll-linked physics. What the eye actually
   reads is two things: a prerendered cover that opens, and elements that rise
   into place as they enter. Both are reproduced here with an observer. */

function splitWords(host) {
  if (host.dataset.split) return;
  host.dataset.split = '1';
  const walk = (node) => {
    for (const child of Array.from(node.childNodes)) {
      if (child.nodeType === Node.TEXT_NODE) {
        const parts = child.textContent.split(/(\s+)/);
        const fragment = document.createDocumentFragment();
        for (const part of parts) {
          if (!part) continue;
          if (/^\s+$/.test(part)) {
            fragment.append(' ');
            continue;
          }
          const outer = el('span', { class: 'w' });
          const inner = el('span', { class: 'wi', text: part });
          outer.append(inner);
          fragment.append(outer);
        }
        child.replaceWith(fragment);
        continue;
      }
      walk(child);
    }
  };
  walk(host);
}

function reveal(root = document) {
  const reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;
  root.querySelectorAll('[data-words]').forEach(splitWords);
  const targets = root.querySelectorAll('[data-fade], [data-words], [data-group]');
  if (reduced || !('IntersectionObserver' in window)) {
    targets.forEach((node) => node.classList.add('is-in'));
    return;
  }
  const observer = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (!entry.isIntersecting) continue;
        entry.target.classList.add('is-in');
        observer.unobserve(entry.target);
      }
    },
    { rootMargin: '0px 0px -8% 0px', threshold: 0.02 },
  );
  targets.forEach((node, index) => {
    if (!node.style.getPropertyValue('--i')) node.style.setProperty('--i', String(Math.min(index, 8)));
    observer.observe(node);
  });
}

function markReveals() {
  // Sections, cards, files and code blocks rise as they enter; the hero is
  // already on screen, so it is revealed immediately.
  const selectors = [
    '.sec-head h2',
    '.sec-head .lede',
    '.rel-top',
    '.pick',
    '.plat-tabs',
    '.asset',
    '.tip',
    '.pcard',
    '.drop',
    '.field',
    '.term',
    '.cl-card',
    '.cl-item',
    '.foot-about',
    '.ph-tags',
    '.ph-eyebrow',
  ];
  for (const node of document.querySelectorAll(selectors.join(','))) {
    if (!node.hasAttribute('data-fade') && !node.hasAttribute('data-words')) {
      node.setAttribute('data-fade', '');
    }
  }
}

function dismissLoader() {
  const root = document.documentElement;
  const loader = $('loader');
  if (!loader) return;
  const finish = () => {
    root.classList.add('is-loaded');
    loader.remove();
  };
  // The cover opens only when the motion runtime asks for it; here the page is
  // ready, so hold the mark for a beat and let the letters settle first.
  const delay = matchMedia('(prefers-reduced-motion: reduce)').matches ? 0 : 620;
  setTimeout(finish, delay);
}

function start() {
  state.lang = STRINGS[document.documentElement.dataset.pageLang || 'en'] ? document.documentElement.dataset.pageLang : 'en';
  applyStaticText();
  markReveals();
  reveal();
  wire();
  load();
  // The loader is prerendered, so it covers the first paint either way.
  if (document.readyState === 'complete') dismissLoader();
  else addEventListener('load', dismissLoader, { once: true });
}

start();

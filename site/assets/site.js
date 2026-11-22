/* Skyward site — data, rendering and interaction.
   Static copy comes from assets/shared.js (STRINGS); everything that depends on
   the release is fetched at runtime from release.json, CHANGELOG.md and — for the
   check — the release's own SHA256SUMS. */

const { REPO, STRINGS, parseChangelog, translate } = globalThis.SkywardSite;

// Data files live at the site root; the zh page is one directory down.
const SITE = new URL(document.documentElement.dataset.base || '.', document.baseURI).href;
const PLATFORMS = ['windows', 'macos', 'linux', 'android'];
const OS_NAMES = { windows: 'Windows', macos: 'macOS', linux: 'Linux', android: 'Android' };
const OS_SHORT = { windows: 'W', macos: 'M', linux: 'L', android: 'A' };

const state = { lang: 'en', platform: 'windows', arch: 'x64' };
// The page is promotional: the notes lead, and only the newest releases follow.
const RECENT_RELEASES = 3;

const $ = (id) => document.getElementById(id);
const t = (key, ...args) => translate(state.lang, key, ...args);

function applyStaticText() {
  document.documentElement.lang = state.lang === 'zh' ? 'zh-CN' : 'en';
  for (const node of document.querySelectorAll('[data-i18n]')) node.textContent = t(node.dataset.i18n);
  for (const node of document.querySelectorAll('[data-i18n-alt]')) node.alt = t(node.dataset.i18nAlt);
  for (const node of document.querySelectorAll('[data-i18n-placeholder]')) node.placeholder = t(node.dataset.i18nPlaceholder);
  for (const node of document.querySelectorAll('[data-i18n-aria]')) node.setAttribute('aria-label', t(node.dataset.i18nAria));
  // The comparison table stacks on phones, where each cell needs its column name.
  for (const cell of document.querySelectorAll('.cmp td')) {
    cell.dataset.label = cell.classList.contains('cmp-us') ? t('cmpUs') : t('cmpTypical');
  }
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
        { id: 'android-arm64-v8a.apk', kind: 'APK', label: 'arm64-v8a', note: 'noteAndroidArm64', rec: true },
        { id: 'android-armeabi-v7a.apk', kind: 'APK', label: 'armeabi-v7a', note: 'noteAndroidArm32' },
        { id: 'android-x86_64.apk', kind: 'APK', label: 'x86_64', note: 'noteAndroidX64' },
      ];
    case 'windows':
      return [
        { id: `windows-${goArch(arch)}-setup.exe`, kind: 'Installer', label: t('winSetup'), note: 'noteWinSetup', rec: true },
        { id: `windows-${goArch(arch)}.zip`, kind: 'Portable ZIP', label: t('winPortable'), note: 'noteWinPortable' },
      ];
    case 'macos':
      return [
        { id: 'macos-arm64.dmg', kind: 'DMG', label: 'Apple Silicon', note: 'noteMacArm', rec: arch === 'arm64' },
        { id: 'macos-amd64.dmg', kind: 'DMG', label: 'Intel', note: 'noteMacIntel', rec: arch !== 'arm64' },
      ];
    case 'linux':
      return [
        { id: `linux-${goArch(arch)}.deb`, kind: 'DEB', label: 'DEB', note: 'noteDeb', rec: true },
        { id: `linux-${goArch(arch)}.rpm`, kind: 'RPM', label: 'RPM', note: 'noteRpm' },
        { id: `linux-${goArch(arch)}.AppImage`, kind: 'AppImage', label: 'AppImage', note: 'noteAppImage' },
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
    $('pick-meta').replaceChildren(
      el('span', { text: best.name }),
      document.createTextNode(' · '),
      el('span', { class: 'nowrap', text: formatSize(best.size) }),
    );
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
        'data-mg': '',
        'aria-pressed': String(state.platform === os),
        onclick: () => {
          state.platform = os;
          renderRelease(feed);
        },
      }),
    ),
  );
  // The plate belongs to the magnet group; rebuilding the buttons replaces it,
  // so put it back and re-select the pressed tab.
  const pressed = seg.querySelector("[aria-pressed='true']");
  if (seg._mg) {
    seg.prepend(seg._mg.el);
    if (pressed) M.frame(() => seg._mg.select(pressed));
  }

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
  revealDynamic();
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

function notesFor(version, level) {
  const blocks = [];
  for (const group of version.groups) {
    if (group.title) blocks.push(el(`h${level}`, { class: 'md-h', text: group.title }));
    const entries = group.entries.map((entry) => {
      const li = el('li');
      if (entry.scope) li.append(el('strong', { text: `${entry.scope} ` }));
      li.append(document.createTextNode(entry.text));
      if (entry.id) li.append(el('a', { class: 'tlink', href: `${REPO}/commit/${entry.id}`, text: ` ${entry.id.slice(0, 7)}` }));
      return li;
    });
    if (entries.length) blocks.push(el('ul', { class: 'md-list' }, ...entries));
  }
  return blocks;
}

function toggleRelease(event) {
  const button = event.currentTarget;
  const item = button.closest('.cl-item');
  const panel = item && item.querySelector('.cl-panel');
  if (!panel) return;
  const opening = !item.hasAttribute('data-open');
  const from = panel.getBoundingClientRect().height;
  item.toggleAttribute('data-open', opening);
  button.setAttribute('aria-expanded', String(opening));
  if (matchMedia('(prefers-reduced-motion: reduce)').matches || !panel.animate) return;
  const to = opening ? panel.scrollHeight : 0;
  if (Math.abs(to - from) < 1) return;
  panel.animate([{ height: `${from}px` }, { height: `${to}px` }], {
    duration: 420,
    easing: 'cubic-bezier(0.22, 1, 0.36, 1)',
  });
}

function renderChangelog(versions, total = versions.length) {
  const host = $('changelog');
  if (!versions.length) {
    host.replaceChildren(el('p', { class: 'cl-empty', text: t('clEmpty') }));
    $('cl-meta').textContent = '';
    return;
  }
  const [first, ...rest] = versions;
  const dateOf = (version) => (version.date ? formatDate(version.date, state.lang) : '');
  const isPre = (version) => /beta|alpha|rc/i.test(version.tag);
  host.replaceChildren(
    el(
      'section',
      { class: 'cl-card cl-in' },
      el(
        'header',
        { class: 'cl-head' },
        el('h3', { class: 'cl-ver', text: first.tag }),
        el('span', { class: 'cl-badge', text: t('clLatest') }),
        el('time', { class: 'cl-date', text: dateOf(first) }),
        el('a', { class: 'btn btn-ghost btn-s cl-gh', href: `${REPO}/releases/tag/${first.tag}`, text: t('clOnGithub') }),
      ),
      el('div', { class: 'md' }, ...notesFor(first, 4)),
    ),
    el('h3', { class: 'cl-sub', text: t('clEarlier') }),
    el(
      'ul',
      { class: 'cl-list' },
      ...rest.map((version, index) =>
        el(
          'li',
          { class: 'cl-item cl-in', style: `--i:${index}` },
          el(
            'h4',
            { class: 'cl-row' },
            el(
              'button',
              {
                class: 'cl-btn',
                type: 'button',
                id: `cl-b-${index}`,
                'aria-expanded': 'false',
                'aria-controls': `cl-p-${index}`,
                onclick: toggleRelease,
              },
              el('span', { class: 'cl-v', text: version.tag }),
              isPre(version) ? el('span', { class: 'cl-badge is-pre', text: t('clPre') }) : null,
              el('time', { class: 'cl-date', text: dateOf(version) }),
              el('span', { class: 'pm', 'aria-hidden': 'true' }),
            ),
          ),
          el(
            'div',
            { class: 'cl-panel', id: `cl-p-${index}`, role: 'region', 'aria-labelledby': `cl-b-${index}` },
            el('div', { class: 'cl-body md' }, ...notesFor(version, 5)),
          ),
        ),
      ),
    ),
  );
  $('cl-meta').textContent = t('clRecent', versions.length, total);
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
        el('div', { class: 'arch' }, ...builds.map((build) => el('span', { text: build.label }))),
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

  // The platform plate belongs to the magnet group now.
  $('copy-unix').addEventListener('click', (event) => copyText($('t-unix').textContent, event.currentTarget));  $('copy-win').addEventListener('click', (event) => copyText($('t-win').textContent, event.currentTarget));
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

/* The Rust-core build ships from its own `-rust` release. Render its card only
   when build_site.sh managed to fetch that release; otherwise leave it hidden. */
function renderRust(meta) {
  const card = $('rust-card');
  if (!card) return;
  if (!meta || !meta.tag || !meta.assets?.length) {
    card.hidden = true;
    return;
  }
  $('rust-version').textContent = `${meta.tag} · ${(meta.publishedAt || '').slice(0, 10)}`;
  const all = $('rust-all');
  if (all && meta.url) all.href = meta.url;
  const list = $('rust-assets');
  list.replaceChildren(
    ...meta.assets.map((a) =>
      el('a', { class: 'asset', href: a.url, rel: 'noopener' },
        el('span', { class: 'n', text: a.name }),
        el('span', { class: 's', text: formatSize(a.size) }),
      ),
    ),
  );
  card.hidden = false;
  if (typeof revealDynamic === 'function') revealDynamic();
}

function buildFeed(meta) {
  // release.json carries the API objects; the file itself is at
  // browser_download_url (the api.github.com url answers with JSON).
  const assets = (meta?.assets || [])
    .map((asset) => ({ ...asset, url: asset.browser_download_url || asset.url, ...(classify(asset.name) || {}) }))
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
          // formatDate() appends T00:00:00Z, so hand it a bare calendar date.
          published: (meta.publishedAt || '').slice(0, 10),
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
  const [meta, markdown, rustMeta] = await Promise.allSettled([
    fetch(new URL('release.json', SITE), { cache: 'no-cache' }).then((r) => (r.ok ? r.json() : null)),
    fetch(new URL('CHANGELOG.md', SITE), { cache: 'no-cache' }).then((r) => (r.ok ? r.text() : Promise.reject(r.status))),
    fetch(new URL('rust-release.json', SITE), { cache: 'no-cache' }).then((r) => (r.ok ? r.json() : null)),
  ]);

  const feed = buildFeed(meta.status === 'fulfilled' ? meta.value : null);
  if (feed.current) {
    state.platform = feed.current.best?.os || feed.detected.os || 'windows';
    state.arch = feed.current.best?.arch || feed.detected.arch || 'x64';
  }
  renderRelease(feed);
  renderRust(rustMeta.status === 'fulfilled' ? rustMeta.value : null);

  if (markdown.status === 'fulfilled') {
    const versions = parseChangelog(markdown.value);
    renderChangelog(versions.slice(0, RECENT_RELEASES), versions.length);
  } else {
    $('changelog').replaceChildren(el('p', { class: 'cl-fail', text: t('clError') }));
    $('cl-meta').textContent = '';
  }

  renderCards();
  renderPrereq();
  $('year').textContent = String(new Date().getUTCFullYear());
  revealDynamic();
}

/* ---- motion: springs, magnetic plates, reveals -------------------------
   The runtime lives in assets/motion.js; this wires it to our markup. */

const M = globalThis.SkywardMotion;
const { clamp, spring } = M || {};
const motionOff = () => (M ? M.reduced : true);

/* The motion script is an enhancement: if it never arrives, the page must still
   show every section instead of sitting at opacity 0. */
function revealAll() {
  document.querySelectorAll('[data-fade], [data-words], [data-reveal]').forEach((node) => node.classList.add('is-in'));
}

/* The hero ring is a 48-point blob: an idle wobble plus a pull toward the
   pointer, redrawn on the shared frame loop. */
function startRing() {
  const svg = document.querySelector('.ph-ring');
  const path = svg && svg.querySelector('.rg');
  if (!path) return;
  const N = 48;
  const C = 200;
  const R = 128;
  const radii = new Array(N);
  let pointer = null;
  let visible = true;

  const draw = (t) => {
    let pa = 0;
    let pull = 0;
    if (pointer) {
      const dx = pointer.x - C;
      const dy = pointer.y - C;
      const d = Math.hypot(dx, dy);
      pa = Math.atan2(dy, dx);
      pull = clamp((d - R) * 0.3, -18, 26) * (Math.abs(d - R) < 140 ? 1 : 0);
    }
    for (let i = 0; i < N; i++) {
      const a = -Math.PI / 2 + (i / N) * Math.PI * 2;
      let target = 7 * Math.sin(3 * a + t * 0.6) + 4 * Math.sin(5 * a - t * 0.45);
      if (pull) {
        const da = Math.atan2(Math.sin(a - pa), Math.cos(a - pa));
        target += pull * Math.exp(-(da * da) / 0.2);
      }
      radii[i] = R + target;
    }
    path.setAttribute('d', M.blobPath(C, C, radii));
  };

  if (motionOff()) {
    draw(0);
    return;
  }
  M.listen(svg, 'pointermove', (e) => {
    const r = svg.getBoundingClientRect();
    pointer = { x: ((e.clientX - r.left) / r.width) * 400, y: ((e.clientY - r.top) / r.height) * 400 };
  });
  M.listen(svg, 'pointerleave', () => { pointer = null; });
  M.observe(([entry]) => { visible = entry.isIntersecting; }, { threshold: 0 }).observe(svg);
  M.tick((now) => {
    if (visible) draw(now / 1000);
  });
}

/* The cover's intro runs on CSS time; we only decide when to cut the window. */
function startLoader() {
  const loader = $('loader');
  if (!loader) return;
  const root = document.documentElement;
  const open = () => {
    if (!loader.isConnected) return;
    root.classList.add('is-ready');
    setTimeout(() => {
      root.classList.add('is-loaded');
      loader.remove();
    }, motionOff() ? 60 : 1200);
  };
  const ready = () => setTimeout(open, motionOff() ? 0 : Math.max(0, 1300 - performance.now()));
  if (document.readyState === 'complete') ready();
  else addEventListener('load', ready, { once: true });
}

/* One magnetic plate per group; the stylesheet does the rest. */
function startMagnets() {
  const footGrid = document.querySelector('.foot-grid');
  if (footGrid) {
    footGrid.setAttribute('data-group', '');
    footGrid.dataset.items = 'a';
    footGrid.dataset.cpull = '0';
    footGrid.querySelectorAll('a').forEach((a) => a.setAttribute('data-mg', ''));
  }
  document.querySelectorAll('[data-group]').forEach((group) => {
    const api = M.magnetGroup(group, {
      items: group.dataset.items || '[data-mg]',
      sticky: group.hasAttribute('data-sticky'),
      contentPull: Number(group.dataset.cpull ?? 0.08),
    });
    group._mg = api;
    const sel = group.querySelector('[aria-current="true"], [aria-current="page"], [aria-pressed="true"]');
    if (sel && group.hasAttribute('data-sticky')) M.frame(() => api.select(sel));
  });
  if (document.fonts && document.fonts.ready) {
    document.fonts.ready.then(() => {
      document.querySelectorAll('[data-group]').forEach((g) => g._mg && g._mg.refresh());
    });
  }
}

/* Theme dropdown: dark, light, paper. The choice is stored, and a first visit
   follows the OS preference (decided in the head script). */
function startThemes() {
  const dd = $('theme-dd');
  const btn = $('theme-btn');
  const panel = $('theme-panel');
  if (!dd || !btn || !panel) return;
  // One set of theme buttons lives in the desktop dropdown and another in the
  // mobile menu; both drive the same choice and stay in sync.
  const items = [...panel.querySelectorAll('[data-theme]'), ...document.querySelectorAll('#menu [data-theme]')];
  const names = { dark: 'themeDark', light: 'themeLight', paper: 'themePaper' };

  const setOpen = (open) => {
    dd.classList.toggle('is-open', open);
    btn.setAttribute('aria-expanded', String(open));
  };
  const apply = (name) => {
    const next = names[name] ? name : 'dark';
    document.documentElement.dataset.theme = next;
    try {
      localStorage.setItem('skyward-theme', next);
    } catch {}
    for (const item of items) {
      const on = item.dataset.theme === next;
      item.classList.toggle('is-active', on);
      item.setAttribute('aria-checked', String(on));
    }
  };

  let hovered = false;
  btn.addEventListener('click', () => {
    // A mouse has already opened it by hovering; only touch and keyboard click.
    if (hovered) return;
    setOpen(!dd.classList.contains('is-open'));
  });
  dd.addEventListener('pointerenter', (e) => {
    if (e.pointerType !== 'mouse') return;
    hovered = true;
    setOpen(true);
  });
  dd.addEventListener('pointerleave', (e) => {
    if (e.pointerType !== 'mouse') return;
    hovered = false;
    setOpen(false);
  });
  dd.addEventListener('focusout', (e) => { if (!dd.contains(e.relatedTarget)) setOpen(false); });
  document.addEventListener('click', (e) => { if (!dd.contains(e.target)) setOpen(false); });
  addEventListener('keydown', (e) => { if (e.key === 'Escape') { setOpen(false); btn.focus(); } });
  panel.addEventListener('click', (e) => {
    const item = e.target.closest('[data-theme]');
    if (!item) return;
    apply(item.dataset.theme);
    setOpen(false);
  });
  const menu = $('menu');
  if (menu) menu.addEventListener('click', (e) => {
    const item = e.target.closest('[data-theme]');
    if (!item) return;
    apply(item.dataset.theme);
  });

  apply(document.documentElement.dataset.theme || 'dark');
}

/* Mobile menu: a full-screen panel that opens from the burger with a circular
   reveal (the stylesheet already supplies the clip-path animation). */
function startMenu() {
  const btn = $('menu-btn');
  const menu = $('menu');
  if (!btn || !menu) return;
  const nav = document.querySelector('.nav-bar');
  const setOpen = (open) => {
    menu.classList.toggle('is-open', open);
    btn.setAttribute('aria-expanded', String(open));
    menu.setAttribute('aria-hidden', String(!open));
    document.body.style.overflow = open ? 'hidden' : '';
    if (!open && btn.focus) btn.focus();
  };
  // Grow the circle from the burger's centre.
  btn.addEventListener('click', () => {
    if (!menu.classList.contains('is-open')) {
      const r = btn.getBoundingClientRect();
      menu.style.setProperty('--ox', `${r.left + r.width / 2}px`);
      menu.style.setProperty('--oy', `${r.top + r.height / 2}px`);
    }
    setOpen(!menu.classList.contains('is-open'));
  });
  menu.addEventListener('click', (e) => {
    const link = e.target.closest('a');
    if (link && link.getAttribute('href')?.startsWith('#')) setOpen(false);
  });
  addEventListener('keydown', (e) => { if (e.key === 'Escape' && menu.classList.contains('is-open')) setOpen(false); });
  // Flag the active language and point the alternate link at the real toggle's
  // href, which render_site.mjs already computes per page.
  const pageLang = document.documentElement.dataset.pageLang || 'en';
  menu.querySelectorAll('[data-menu-lang]').forEach((a) => {
    a.setAttribute('aria-current', String(a.dataset.menuLang === pageLang));
  });
  // The hrefs are relative paths in the template; render_site.mjs rewrites them
  // with the right prefix for each language page, so no JS adjustment is needed.
}

/* The nav hides going down and returns going up. */
function startNav() {
  const nav = document.querySelector('.nav');
  if (!nav) return;
  let lastY = scrollY;
  M.onScroll((y) => {
    const down = y > lastY + 4;
    const up = y < lastY - 4;
    if (down && y > 160) nav.classList.add('is-hidden');
    else if (up || y < 160) nav.classList.remove('is-hidden');
    if (down || up) lastY = y;
  });
}

/* Setup rail: fills with scroll, each step lights as the fill passes it. */
function startSteps() {
  const steps = document.querySelector('.steps');
  if (!steps) return;
  const items = [...steps.querySelectorAll('.step')];
  const fill = spring(0, { preset: 'scroll', precision: 0.0005 });
  fill.onUpdate = (p) => {
    steps.style.setProperty('--p', p.toFixed(4));
    const r = steps.getBoundingClientRect();
    const top = r.top + 22;
    const len = r.height - 44;
    for (const item of items) {
      const n = item.querySelector('.step-n').getBoundingClientRect();
      item.classList.toggle('is-on', p >= (n.top + n.height / 2 - top) / len - 0.02);
    }
  };
  M.onScroll(() => {
    const r = steps.getBoundingClientRect();
    fill.to(clamp((innerHeight * 0.62 - r.top) / r.height, 0, 1));
  });
}

/* Footer wordmark: letters and the glyph's capsules stretch toward the pointer. */
function startWordmark() {
  const wm = document.querySelector('.wordmark');
  if (!wm || motionOff()) return;
  const text = wm.querySelector('.wordmark-text');
  const spans = [...text.textContent.trim()].map((c) => {
    const s = document.createElement('span');
    s.textContent = c;
    return s;
  });
  text.replaceChildren(...spans);
  const bars = [...wm.querySelectorAll('.bm-bar')].map((p) => {
    const s = spring(0.8, { preset: 'jelly', precision: 0.001 });
    s.onUpdate = (v) => {
      const l = clamp(v, 0.0001, 1);
      p.style.strokeDasharray = `${l.toFixed(4)} 2`;
      p.style.strokeDashoffset = (-(1 - l) / 2).toFixed(4);
    };
    return s;
  });
  const letters = spans.map((sp) => {
    const s = spring(1, { preset: 'jelly', precision: 0.001 });
    s.onUpdate = (v) => {
      sp.style.transform = `scaleY(${v.toFixed(4)}) scaleX(${(1 - (v - 1) * 0.25).toFixed(4)})`;
    };
    return s;
  });
  const foot = wm.closest('footer');
  M.listen(foot, 'pointermove', (e) => {
    if (e.pointerType === 'touch') return;
    spans.forEach((sp, i) => {
      const r = sp.getBoundingClientRect();
      const d = e.clientX - (r.left + r.width / 2);
      const near = Math.exp(-(d * d) / (2 * 110 * 110));
      const vert = clamp(1 - Math.abs(e.clientY - r.bottom) / 520, 0, 1);
      letters[i].to(1 + 0.32 * near * vert);
    });
    const mark = wm.querySelector('.wordmark-mark');
    if (mark && bars.length) {
      const r = mark.getBoundingClientRect();
      const d = e.clientX - (r.left + r.width / 2);
      const near = Math.exp(-(d * d) / (2 * 160 * 160)) * clamp(1 - Math.abs(e.clientY - r.bottom) / 520, 0, 1);
      bars.forEach((bar, i) => bar.to(0.8 + 0.2 * near * (1 - Math.abs(clamp((d + 60) / 60, 0, 2) - i) * 0.35)));
    }
  });
  M.listen(foot, 'pointerleave', () => {
    letters.forEach((s) => s.to(1));
    bars.forEach((b) => b.to(0.8));
  });
}

function startReveals() {
  document.querySelectorAll('[data-words]').forEach((node) => M.splitWords(node));
  M.reveal(document.querySelectorAll('[data-words], [data-fade], [data-reveal]'));
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

/* Content that arrives after page load (files, cards, notes) needs marking
   and observing again, or it would sit at opacity 0 forever. */
function revealDynamic() {
  markReveals();
  if (M) M.reveal(document.querySelectorAll('[data-fade], [data-reveal]'));
  else revealAll();
}

function start() {
  state.lang = STRINGS[document.documentElement.dataset.pageLang || 'en'] ? document.documentElement.dataset.pageLang : 'en';
  applyStaticText();
  startLoader();
  if (M) {
    // Make every CSS transition in their stylesheet settle like the springs.
    M.installEasings();
    startReveals();
    startMagnets();
    startNav();
    startThemes();
    startMenu();
    startSteps();
    startWordmark();
    startRing();
  } else {
    revealAll();
  }
  wire();
  load();
}

start();

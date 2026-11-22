/* Skyward site — data, rendering and interaction.
   Static copy comes from assets/shared.js (STRINGS); everything that depends on
   the release is fetched at runtime from release.json and CHANGELOG.md. */

const { REPO, STRINGS, parseChangelog, translate } = globalThis.SkywardSite;

const SITE = new URL('.', document.baseURI).href;
const PLATFORMS = ['android', 'windows', 'macos', 'linux'];
const PLATFORM_ICON = {
  android: '<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M7.2 16.4h9.6v-6.6H7.2v6.6Zm10.6-8.5 1.1-1.9a.4.4 0 0 0-.7-.4l-1.1 1.9a6.7 6.7 0 0 0-9 0L7 5.6a.4.4 0 1 0-.7.4l1.1 1.9a6.4 6.4 0 0 0-3 5.5h17a6.4 6.4 0 0 0-3-5.5ZM10 9.4a.9.9 0 1 1 .9.9.9.9 0 0 1-.9-.9Zm4 0a.9.9 0 1 1 .9.9.9.9 0 0 1-.9-.9Z"/></svg>',
  windows: '<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M4 6.2 10.6 5v5.6H4V6.2Zm7.4-1.4L20 3.6v6.9h-8.6V4.8ZM4 11.4h6.6V17L4 16v-4.6Zm7.4 0H20v6.9l-8.6-1.2v-5.7Z"/></svg>',
  macos: '<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M17.2 12.6c0-2.3 1.9-3.4 2-3.5-1.1-1.6-2.8-1.8-3.4-1.8-1.4-.1-2.8.9-3.5.9s-1.8-.8-3-.8c-1.5 0-3 .9-3.8 2.3-1.6 2.8-.4 7 1.1 9.3.8 1.1 1.7 2.4 2.9 2.3 1.2 0 1.6-.7 3-.7s1.8.7 3 .7 2-1.1 2.8-2.3c.9-1.3 1.2-2.5 1.3-2.6 0 0-2.5-1-2.4-3.9ZM15 6.2c.6-.8 1-1.8.9-2.9-.9 0-2 .6-2.6 1.4-.6.7-1 1.8-.9 2.8 1 .1 2-.5 2.6-1.3Z"/></svg>',
  linux: '<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M12 2.5c-2 0-3.3 1.6-3.3 3.6 0 1.2.3 2.2.7 3.1-.6.7-1.1 1.6-1.1 2.6 0 .5.1 1 .3 1.4-.6.8-1 1.8-1 2.9 0 2.8 2.8 5 6.4 5s6.4-2.2 6.4-5c0-1.1-.4-2.1-1-2.9.2-.4.3-.9.3-1.4 0-1-.5-1.9-1.1-2.6.4-.9.7-1.9.7-3.1 0-2-1.3-3.6-3.3-3.6Zm-1.6 4.1h3.2c.3 0 .5.2.5.5v.5c0 .3-.2.5-.5.5h-.4v.6c.3.2.5.6.5 1v3.2c0 .3-.2.5-.5.5h-2.6c-.3 0-.5-.2-.5-.5V9.9c0-.4.2-.8.5-1V8.3h-.4c-.3 0-.5-.2-.5-.5v-.5c0-.3.2-.5.5-.5Z"/></svg>',
};

const state = { lang: 'en', platform: 'android', arch: 'arm64' };

const $ = (id) => document.getElementById(id);
const t = (key, ...args) => translate(state.lang, key, ...args);

function applyStaticText() {
  document.documentElement.lang = state.lang === 'zh' ? 'zh-CN' : 'en';
  for (const node of document.querySelectorAll('[data-i18n]')) node.textContent = t(node.dataset.i18n);
  for (const node of document.querySelectorAll('[data-i18n-alt]')) node.alt = t(node.dataset.i18nAlt);
  for (const node of document.querySelectorAll('[data-i18n-placeholder]')) node.placeholder = t(node.dataset.i18nPlaceholder);
  const toggle = $('lang-toggle');
  if (toggle) toggle.textContent = t('langToggle');
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

function goArch(arch) {
  return arch === 'arm64' ? 'arm64' : 'amd64';
}

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
        { id: `windows-${goArch(arch)}-setup.exe`, kind: 'EXE', titleKey: 'winSetup', note: 'noteWinSetup', rec: true },
        { id: `windows-${goArch(arch)}.zip`, kind: 'ZIP', titleKey: 'winPortable', note: 'noteWinPortable' },
      ];
    case 'macos':
      return [
        { id: 'macos-arm64.dmg', kind: 'DMG', title: 'Apple Silicon', note: 'noteMacArm', rec: arch === 'arm64' },
        { id: 'macos-amd64.dmg', kind: 'DMG', title: 'Intel', note: 'noteMacIntel', rec: arch !== 'arm64' },
      ];
    case 'linux':
      return [
        { id: `linux-${goArch(arch)}.deb`, kind: 'DEB', title: 'Debian / Ubuntu', short: '.deb', note: 'noteDeb', rec: true },
        { id: `linux-${goArch(arch)}.rpm`, kind: 'RPM', title: 'Fedora / openSUSE', short: '.rpm', note: 'noteRpm' },
        { id: `linux-${goArch(arch)}.AppImage`, kind: 'APPIMAGE', title: 'AppImage', note: 'noteAppImage' },
      ];
    default:
      return [];
  }
}

function formatSize(bytes) {
  if (!bytes && bytes !== 0) return '';
  const units = ['B', 'KB', 'MB', 'GB'];
  let value = bytes;
  let unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit += 1;
  }
  return `${value >= 100 || unit === 0 ? Math.round(value) : value.toFixed(1)} ${units[unit]}`;
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
  const label = button.textContent;
  button.classList.add('done');
  button.textContent = t('copied');
  setTimeout(() => {
    button.classList.remove('done');
    button.textContent = label;
  }, 1600);
  return ok;
}

function fileRow(build, asset, tag) {
  const digest = asset && asset.digest ? asset.digest.replace(/^sha256:/, '') : null;
  const sha = digest
    ? el('button', {
        class: 'sha',
        type: 'button',
        text: 'SHA-256',
        title: digest,
        'data-name': asset ? asset.name : build.id,
        'aria-label': t('copySha', build.id),
        onclick: (event) => copyText(digest, event.currentTarget),
      })
    : null;
  const link = el('a', { class: 'btn ghost s', href: `${REPO}/releases/download/${tag}/${asset ? asset.name : build.id}` }, build.title);
  return el(
    'li',
    { class: build.rec ? 'file rec' : 'file' },
    el('span', { class: `kind${build.kind.length > 4 ? ' long' : ''}`, text: build.kind }),
    el(
      'div',
      { class: 'file-main' },
      el('div', { class: 'file-title' }, build.title, build.rec ? el('span', { class: 'rec-tag', text: t('recommended') }) : null),
      el('p', { class: 'note', text: t(build.note) }),
    ),
    el('div', { class: 'meta' }, asset && asset.size ? el('span', { text: formatSize(asset.size) }) : null, sha),
    link,
  );
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
      el(
        'div',
        { class: 'tip' },
        el('h3', { text: t('tipTrayTitle') }),
        el('p', { text: t('noteLinuxTray') }),
      ),
    ];
  }
  return [];
}

function renderFiles(assets, tag) {
  const list = $('files');
  const error = $('dl-error');
  const builds = buildsFor(state.platform, state.arch);
  const rows = builds
    .map((build) => {
      const asset = assets.get(build.id) || null;
      if (assets.size && !asset) return null;
      return fileRow(build, asset, tag);
    })
    .filter(Boolean);
  list.replaceChildren(...rows);
  $('extras').replaceChildren(...extrasFor(state.platform));
  if (!rows.length) {
    list.append(el('li', { class: 'muted', text: t('filesEmpty') }));
  }
  error.hidden = assets.size > 0;
  if (!assets.size) error.textContent = t('dlError');
}

function renderSegments(assets) {
  const platformSeg = $('platform-seg');
  platformSeg.replaceChildren(
    ...PLATFORMS.map((platform) => {
      const available = buildsFor(platform, state.arch).some((build) => assets.has(build.id));
      return el('button', {
        type: 'button',
        role: 'tab',
        text: t(`platform_${platform}`),
        'aria-selected': String(state.platform === platform),
        disabled: assets.size && !available,
        onclick: () => {
          state.platform = platform;
          renderSegments(assets);
          renderFiles(assets, state.releaseTag);
        },
      });
    }),
  );

  const archSeg = $('arch-seg');
  const arches = state.platform === 'android' ? ['arm64', 'arm32', 'x64'] : ['arm64', 'x64'];
  const current = arches.includes(state.arch) ? state.arch : arches[0];
  if (current !== state.arch) state.arch = current;
  archSeg.hidden = arches.length < 2;
  archSeg.replaceChildren(
    ...arches.map((arch) =>
      el('button', {
        type: 'button',
        role: 'tab',
        text: arch,
        'aria-selected': String(state.arch === arch),
        onclick: () => {
          state.arch = arch;
          renderSegments(assets);
          renderFiles(assets, state.releaseTag);
        },
      }),
    ),
  );
}

function renderChangelog(versions) {
  const host = $('changelog');
  if (!versions.length) {
    host.replaceChildren(el('p', { class: 'muted', text: t('clEmpty') }));
    return;
  }
  const [first, ...rest] = versions;
  const groupBody = (version) =>
    version.groups
      .map((group) => el('ul', {}, ...group.entries.map((entry) => el('li', { text: entry.text }))))
      .filter((list) => list.childNodes.length);
  host.replaceChildren(
    el(
      'section',
      { class: 'cl-card', 'data-rise': '', style: '--i:0' },
      el(
        'div',
        { class: 'cl-head' },
        el('span', { class: 'cl-ver', text: first.tag }),
        el('span', { class: 'badge', text: t('clLatest') }),
        el('span', { class: 'cl-date', text: first.date || '' }),
      ),
      el('div', { class: 'cl-body' }, groupBody(first)),
    ),
    ...rest.map((version, index) =>
      el(
        'details',
        { class: 'cl-item', 'data-rise': '', style: `--i:${index + 1}` },
        el('summary', {}, el('span', { class: 'cl-ver', text: version.tag }), el('span', { class: 'cl-date', text: version.date || '' })),
        el('div', { class: 'cl-body' }, groupBody(version)),
      ),
    ),
  );
}

function renderCards() {
  const cards = [
    { platform: 'windows', body: 'cardWindows' },
    { platform: 'macos', body: 'cardMacos' },
    { platform: 'linux', body: 'cardLinux' },
    { platform: 'android', body: 'cardAndroid' },
  ];
  $('cards').replaceChildren(
    ...cards.map((card, index) => {
      const builds = buildsFor(card.platform, 'arm64');
      return el(
        'li',
        { class: 'pcard', 'data-rise': '', style: `--i:${index}` },
        el('h3', { text: t(`platform_${card.platform}`) }),
        el('span', { class: 'fmt', text: builds.map((build) => build.kind).join(' · ') }),
        el(
          'div',
          { class: 'arch' },
          ...builds.map((build) => el('span', { text: build.short || build.title })),
        ),
        el('p', { text: t(card.body) }),
      );
    }),
  );
}

function renderPrereq() {
  const list = t('prereq');
  $('prereq').replaceChildren(...list.map((item) => el('li', { text: item })));
}

async function verify(file) {
  const nameNode = $('verify-name');
  const result = $('verify-result');
  nameNode.textContent = t('vfNamed', file.name);
  result.className = 'result';
  result.textContent = '';
  const digests = [...document.querySelectorAll('#files .sha')].map((node) => ({
    name: node.dataset.name || '',
    hash: (node.title || '').toLowerCase(),
  }));
  if (!digests.length) {
    result.textContent = t('vfEmpty');
    return;
  }
  const buffer = await file.arrayBuffer();
  const digest = await crypto.subtle.digest('SHA-256', buffer);
  const hex = [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, '0')).join('');
  const hit = digests.find((item) => item.hash === hex);
  result.textContent = hit ? t('vfMatch', hit.name) : t('vfMiss');
}

async function load() {
  const [release, markdown] = await Promise.allSettled([
    fetch(new URL('release.json', SITE), { cache: 'no-cache' }).then((r) => (r.ok ? r.json() : null)),
    fetch(new URL('CHANGELOG.md', SITE), { cache: 'no-cache' }).then((r) => (r.ok ? r.text() : Promise.reject(r.status))),
  ]);

  const meta = release.status === 'fulfilled' ? release.value : null;
  const assets = new Map((meta && meta.assets ? meta.assets : []).map((asset) => [asset.name, asset]));
  const tag = (meta && meta.tag) || '';

  if (meta && meta.stars) {
    const stars = $('stars');
    stars.hidden = false;
    stars.dataset.count = String(meta.stars);
    stars.textContent = t('starsLabel', meta.stars);
    stars.title = t('starsLabel', meta.stars);
  }

  state.releaseTag = tag;
  $('rel-meta').textContent = tag ? `${tag.replace(/^v/, '')} · ${(meta.publishedAt || '').slice(0, 10)}` : '';
  $('sums-link').href = `${REPO}/releases/download/${tag}/SHA256SUMS`;

  renderSegments(assets);
  renderFiles(assets, tag);

  if (markdown.status === 'fulfilled') {
    const versions = parseChangelog(markdown.value);
    renderChangelog(versions);
    $('cl-meta').textContent = versions.length ? t('clMeta', versions.length, versions.filter((v) => v.date).slice(-1)[0]?.date || '') : '';
  } else {
    $('changelog').replaceChildren(
      el(
        'p',
        { class: 'error' },
        t('clError'),
        ' ',
        el('a', { href: `${REPO}/blob/main/CHANGELOG.md`, text: t('clErrorLink') }),
      ),
    );
  }

  renderCards();
  renderPrereq();
}

function detectPlatform() {
  const ua = navigator.userAgent.toLowerCase();
  if (/android/.test(ua)) return { platform: 'android', arch: 'arm64' };
  if (/windows|win32|win64/.test(ua)) return { platform: 'windows', arch: /arm64|aarch64/.test(ua) ? 'arm64' : 'x64' };
  if (/mac os|macintosh|darwin/.test(ua)) return { platform: 'macos', arch: /arm64|aarch64/.test(ua) ? 'arm64' : 'x64' };
  if (/linux/.test(ua)) return { platform: 'linux', arch: /arm64|aarch64/.test(ua) ? 'arm64' : 'x64' };
  return { platform: 'android', arch: 'arm64' };
}

function wire() {
  const buildCopy = $('build-copy');
  if (buildCopy) buildCopy.addEventListener('click', (event) => copyText($('build-cmd').textContent, event.currentTarget));

  const input = $('verify-file');
  const drop = $('drop');
  if (input && drop) {
    input.addEventListener('change', (event) => {
      const file = event.target.files && event.target.files[0];
      if (file) verify(file);
      input.value = '';
    });
    for (const type of ['dragenter', 'dragover']) {
      drop.addEventListener(type, (event) => {
        event.preventDefault();
        drop.classList.add('over');
      });
    }
    for (const type of ['dragleave', 'drop']) {
      drop.addEventListener(type, (event) => {
        event.preventDefault();
        drop.classList.remove('over');
      });
    }
    drop.addEventListener('drop', (event) => {
      const file = event.dataTransfer && event.dataTransfer.files && event.dataTransfer.files[0];
      if (file) verify(file);
    });
  }
}

function start() {
  const detected = detectPlatform();
  state.platform = detected.platform;
  state.arch = detected.arch;
  const lang = document.documentElement.dataset.pageLang || 'en';
  state.lang = STRINGS[lang] ? lang : 'en';
  applyStaticText();
  wire();
  load();
}

start();

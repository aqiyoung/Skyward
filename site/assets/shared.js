globalThis.SkywardSite = (() => {
  'use strict';

  const REPO = 'https://github.com/aqiyoung/Skyward';
  const FIRST_PAGE = 6;
  const MAX_STAGGER = 16;
  const TYPE_BY_TITLE = {
    'Breaking Changes': 'breaking',
    Features: 'feat',
    'Bug Fixes': 'fix',
    Performance: 'perf',
    Reverts: 'revert',
  };
  const TYPE_KEYS = { breaking: 'typeBreaking', feat: 'typeFeat', fix: 'typeFix', perf: 'typePerf', revert: 'typeRevert' };
  const ICON_EXTERNAL =
    '<svg viewBox="0 0 16 16" width="12" height="12" aria-hidden="true"><path d="M6 3.5h6.5V10M12.25 3.75 4 12" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg>';

  const STRINGS = {
    en: {
      pageTitle: 'Skyward – Clash Meta (mihomo) proxy client for Android, Windows, macOS and Linux',
      pageDescription:
        'Skyward is a free, open-source Clash Meta (mihomo) proxy client for Android, Windows, macOS and Linux, with rule routing, TUN mode and subscription import. No ads.',
      skip: 'Skip to downloads',
      navDownload: 'Download',
      navChangelog: 'Changelog',
      langToggle: '中文',
      langLabel: '切换到中文',
      themeLabel: 'Toggle dark mode',
      heroFor: 'for',
      reelLabel: 'Switch platform',
      heroLede: 'A multi-platform proxy client based on Clash Meta (mihomo). Simple to use, open source and ad-free.',
      heroOther: 'Other platforms',
      heroReleaseLoading: 'Latest release',
      heroRelease: (v) => `${v} is out · See what’s new`,
      ctaDownload: (p) => `Download for ${p}`,
      ctaChoose: 'Choose a download',
      ctaIos: 'Skyward does not run on iOS. Pick a build for another device below.',
      previewAlt: 'Skyward dashboard on a MacBook and a phone',
      fact1Title: 'mihomo core',
      fact1: 'Rule routing, proxy groups and TUN mode.',
      fact2Title: 'Subscriptions',
      fact2: 'Import a profile from a subscription link.',
      fact3Title: 'WebDAV sync',
      fact3: 'Back up and restore your data across devices.',
      fact4Title: 'Open source',
      fact4: 'Licensed under GPL-3.0, with no ads.',
      dlTitle: 'Download',
      dlMeta: (v, d) => `Version ${v} · Released ${d}`,
      dlLead: 'The build for this device is already selected. Each file says which devices it is for.',
      dlAll: 'All releases on GitHub',
      verifyTitle: 'Check the file you downloaded',
      verifyLead: 'Drop the package you just downloaded here. The hash is computed in this browser — the file never leaves this device.',
      verifyPick: 'Drop a file here, or click to choose',
      verifyNamed: (name) => `Checking ${name}…`,
      verifyMatch: (name) => `Matches ${name} — the file is intact.`,
      verifyMiss: 'No file in this release has that SHA-256. The download may be incomplete or altered.',
      verifyEmpty: 'This release has no published hash to check against.',
      buildTitle: 'Would rather not wait for a release? Build it.',
      buildSub: 'Seeing for yourself what you run is the most direct way to trust a client.',
      buildPrereq: 'Flutter 3.47.6 (the same as the release CI), Go and Rust/Cargo. The mihomo core and the native libraries are all built from source.',
      buildNote: 'Windows needs the Visual Studio C++ toolchain; macOS needs Xcode. The desktop executable is named SkywardCore.',
      dlError: 'Release details could not be loaded. Download from GitHub Releases instead.',
      platformLabel: 'Platform',
      platform_android: 'Android',
      platform_windows: 'Windows',
      platform_macos: 'macOS',
      platform_linux: 'Linux',
      archLabel: 'Architecture',
      recommended: 'Recommended',
      copied: 'Copied',
      copy: 'Copy',
      copySha: (name) => `Copy the SHA-256 of ${name}`,
      hintAndroid: 'Not sure which one? Pick arm64-v8a.',
      hintWindows: 'ARM64 is for Snapdragon and other ARM laptops.',
      hintMacos: 'Apple menu › About This Mac shows your chip.',
      hintLinux: 'Pick the package format your distribution uses.',
      noteAndroidArm64: 'Most phones and tablets from recent years',
      noteAndroidArm32: 'Older 32-bit devices',
      noteAndroidX64: 'Emulators and x86 devices',
      winSetup: 'Installer',
      noteWinSetup: 'Adds a Start menu entry and an uninstaller',
      winPortable: 'Portable',
      noteWinPortable: 'Unzip and run, nothing to install',
      noteMacArm: 'Macs with an M-series chip',
      noteMacIntel: 'Macs with an Intel processor',
      noteDeb: '.deb package for Debian, Ubuntu and their derivatives',
      noteRpm: '.rpm package for Fedora, openSUSE and their derivatives',
      noteAppImage: 'Runs on most distributions without installing',
      tipIntentTitle: 'Automation',
      tipIntent: 'Other apps can start, stop or toggle the proxy with these intent actions.',
      tipTrayTitle: 'Tray icon',
      tipTray:
        'The .deb package installs its own dependencies. With the AppImage or the .rpm, install the AyatanaAppIndicator library so the tray icon can show.',
      clTitle: 'Changelog',
      clMeta: (n, d) => `${n} releases since ${d}`,
      clSearch: 'Search changes or versions',
      clLatest: 'Latest',
      clMore: (n) => `Show earlier releases (${n} more)`,
      clResults: (e, v) => `${e} ${e === 1 ? 'change' : 'changes'} in ${v} ${v === 1 ? 'release' : 'releases'}`,
      clNone: (q) => `Nothing matches “${q}”.`,
      clClear: 'Clear',
      clEmpty: 'Internal improvements only.',
      clError: 'The changelog could not be loaded.',
      clErrorLink: 'Read CHANGELOG.md on GitHub',
      clOnGithub: 'GitHub',
      clOnGithubLabel: (v) => `Release ${v} on GitHub`,
      navNotes: "What's new",
      navBuild: 'Build it yourself',
      navCta: 'Download',
      relAsking: 'Asking GitHub…',
      relEmpty: 'No releases yet',
      relNone: 'The first release will appear on the GitHub releases page.',
      relError: 'Could not reach GitHub',
      relOffline: 'Could not reach GitHub. Files are always on the releases page.',
      relRate: 'GitHub temporarily limited requests from your address. Files are on the releases page.',
      relPre: 'Prerelease · ',
      relNoAssets: 'The latest release contains no build files. Check the releases page.',
      relIos: 'You seem to be using an iPhone or iPad. There is no iOS build; files for other systems are below.',
      pickTitle: 'Recommended for your device',
      pickCta: 'Download',
      dlNote: 'The platform is detected from your browser and may be wrong. The full file list is always on the releases page.',
      vfField: 'Expected hash or SHA256SUMS contents',
      vfHashing: (name) => `Calculating the hash of “${name}”…`,
      vfHashed: 'Hash calculated. Paste the expected release hash to compare.',
      vfNoLine: (name) => `SHA256SUMS has no line for “${name}”. Check that you chose the right file.`,
      vfNoHash: 'No SHA256 hash found: use 64 hexadecimal characters.',
      vfUnreadable: 'Could not read the file. Try again, or verify it in a terminal.',
      vfMatch: 'Match: this is the expected file.',
      vfMiss: 'Mismatch. Do not run the file; report it in issues.',
      vfDiff: (actual, expected) => `actual:   ${actual}\nexpected: ${expected}`,
      vfTermUnix: 'Linux and macOS',
      footAbout:
        'An open-source client for Clash Meta (mihomo). It does not sell access or provide subscriptions.',
      footSite: 'Site',
      footSource: 'Source',
      footBuiltOn: 'Built on',
      footFork: 'A FlClash fork. Not affiliated with FlClash, mihomo or FlClashX.',
      footLive: 'Actively maintained',
      heroEyebrow: 'Latest release',
      heroTitle: 'Download, or build it yourself.',
      tagPlatforms: 'Four platforms',
      tagSums: 'SHA-256 in every release',
      heroBuild: 'Build it yourself',
      dlSums: 'SHA256SUMS',
      clLead:
        'Release notes come from GitHub with the file list: the current release first, earlier ones below.',
      pfTitle: 'Which package for which system',
      pfLead: 'Every release ships the same four platforms.',
      vfTitle: 'Downloaded it? Verify it.',
      vfLead:
        'Drop the package you just downloaded here. The hash is computed in this browser — the file never leaves this device.',
      vfPick: 'Drop a file here, or click to choose',
      vfNamed: (name) => `Checking ${name}…`,
      vfEmpty: 'This release has no published hash to check against.',
      bdTitle: 'Build it yourself without waiting for a release.',
      bdLead: 'Seeing for yourself what you run is the most direct way to trust a client.',
      bdTerm: 'Build',
      bdNote:
        'Windows needs the Visual Studio C++ toolchain; macOS needs Xcode. The desktop executable is named SkywardCore.',
      prereq: [
        'Flutter 3.47.6 (matching the release CI), Go and Rust/Cargo. The mihomo core and native libraries are built from source.',
        'Windows: Visual Studio C++ tools and the Inno Setup installer generator.',
        'macOS: Xcode and Node.js for appdmg; macOS 12 or later to run.',
        'Linux: the packager asks for administrator rights to install the native dependencies.',
      ],
      dlErrorLink: 'Read CHANGELOG.md on GitHub',
      filesEmpty: 'This release has no files for that platform.',
      cardAndroid: 'For most phones, choose arm64-v8a. Includes a Quick Settings tile, widgets and Always-on VPN.',
      cardWindows: 'The installer sets up the app for the current user and updates itself in the background. TUN mode needs administrator privileges.',
      cardMacos:
        'Not on the App Store: open it once from the context menu → Open. It updates itself while it can write to its own folder.',
      cardLinux:
        'AppImage for x64 (run chmod +x first); ARM64 ships as .deb, .rpm and pacman. Install the system helper from the app to use TUN.',
      noteLinuxTray:
        'The .deb installs its own dependencies. With the AppImage or the .rpm, install the AyatanaAppIndicator library so the tray icon can show.',
      tipFdroidTitle: 'F-Droid',
      tipFdroid: 'Add the Skyward repository to your F-Droid client to get updates there.',
      tipFdroidLink: 'Open the F-Droid repository',
      loading: 'Loading…',
      copies: 'Copies',
      starsLabel: (n) => `${n} stars on GitHub`,
      typeBreaking: 'Breaking changes',
      typeFeat: 'Features',
      typeFix: 'Fixes',
      typePerf: 'Performance',
      typeRevert: 'Reverts',
      footLicense: 'Free and open source under GPL-3.0.',
      footUpdated: 'This page updates with every release.',
      footReleases: 'Releases',
      footTelegram: 'Telegram channel',
      stars: (n) => `${n} stars on GitHub`,
    },
    zh: {
      pageTitle: 'Skyward – 基于 Clash Meta（mihomo）的多平台代理客户端，支持 Android、Windows、macOS、Linux',
      pageDescription:
        'Skyward 是免费开源的 Clash Meta（mihomo）代理客户端，支持 Android、Windows、macOS 与 Linux，提供规则分流、TUN 模式与订阅导入，没有广告。',
      skip: '跳到下载',
      navDownload: '下载',
      navChangelog: '更新日志',
      langToggle: 'EN',
      langLabel: 'Switch to English',
      themeLabel: '切换深色模式',
      heroFor: '适用于',
      reelLabel: '切换平台',
      heroLede: '基于 Clash Meta（mihomo）内核的多平台代理客户端。简单易用，开源，无广告。',
      heroOther: '其他平台',
      heroReleaseLoading: '最新版本',
      heroRelease: (v) => `${v} 已发布 · 查看更新`,
      ctaDownload: (p) => `下载 ${p} 版`,
      ctaChoose: '选择下载版本',
      ctaIos: 'Skyward 不支持 iOS，可以在下方选择其他设备的版本。',
      previewAlt: 'Skyward 仪表盘在 MacBook 与手机上的界面',
      fact1Title: 'mihomo 内核',
      fact1: '规则分流、代理组与 TUN 模式。',
      fact2Title: '订阅导入',
      fact2: '通过订阅链接导入配置。',
      fact3Title: 'WebDAV 同步',
      fact3: '在设备之间备份与恢复数据。',
      fact4Title: '开源',
      fact4: '以 GPL-3.0 协议开源，没有广告。',
      dlTitle: '下载',
      dlMeta: (v, d) => `版本 ${v} · ${d}发布`,
      dlLead: '已为当前设备选好安装包，每个文件都注明了适用的设备。',
      dlAll: '在 GitHub 查看全部版本',
      verifyTitle: '校验你下载的文件',
      verifyLead: '把刚下载的安装包拖进来，哈希在你的浏览器里算——文件不会离开这台设备。',
      verifyPick: '把文件拖到这里，或点击选择',
      verifyNamed: (name) => `正在校验 ${name}…`,
      verifyMatch: (name) => `与 ${name} 一致——文件完整。`,
      verifyMiss: '这个发行版里没有文件的 SHA-256 与它匹配。下载可能不完整或被改动。',
      verifyEmpty: '这个发行版没有公布可用来比对的哈希。',
      buildTitle: '不想等发行版？自己构建。',
      buildSub: '亲眼看到你运行的是什么，是信任一个客户端最直接的方式。',
      buildPrereq: 'Flutter 3.47.6（与发行版 CI 一致）、Go 与 Rust/Cargo。mihomo 内核和原生库都从源码构建。',
      buildNote: 'Windows 需要 Visual Studio C++ 工具链；macOS 需要 Xcode。桌面端的可执行文件名是 SkywardCore。',
      dlError: '未能读取版本信息，请前往 GitHub Releases 下载。',
      platformLabel: '平台',
      platform_android: '安卓',
      platform_windows: 'Windows',
      platform_macos: 'macOS',
      platform_linux: 'Linux',
      archLabel: '架构',
      recommended: '推荐',
      copied: '已复制',
      copy: '复制',
      copySha: (name) => `复制 ${name} 的 SHA-256`,
      hintAndroid: '不确定选哪个？选 arm64-v8a。',
      hintWindows: 'ARM64 适用于骁龙等 ARM 架构笔记本。',
      hintMacos: '在苹果菜单 › 关于本机中可以查看芯片类型。',
      hintLinux: '按发行版使用的软件包格式选择。',
      noteAndroidArm64: '近几年的绝大多数手机与平板',
      noteAndroidArm32: '较老的 32 位设备',
      noteAndroidX64: '模拟器与 x86 设备',
      winSetup: '安装版',
      noteWinSetup: '添加开始菜单入口与卸载程序',
      winPortable: '便携版',
      noteWinPortable: '解压即用，无需安装',
      noteMacArm: '搭载 M 系列芯片的 Mac',
      noteMacIntel: '搭载 Intel 处理器的 Mac',
      noteDeb: '.deb 安装包，也适用于其衍生版',
      noteRpm: '.rpm 安装包，也适用于其衍生版',
      noteAppImage: '适用于多数发行版，无需安装',
      tipIntentTitle: '自动化',
      tipIntent: '其他应用可以通过以下 Intent Action 启动、停止或切换代理。',
      tipTrayTitle: '托盘图标',
      tipTray: '.deb 安装包会自动安装所需依赖。使用 AppImage 或 .rpm 时，需要先安装 AyatanaAppIndicator 库，托盘图标才能显示。',
      clTitle: '更新日志',
      clMeta: (n, d) => `自 ${d}以来共 ${n} 个版本`,
      clSearch: '搜索更新内容或版本',
      clLatest: '最新',
      clMore: (n) => `显示更早的版本（还有 ${n} 个）`,
      clResults: (e, v) => `${v} 个版本中有 ${e} 条匹配`,
      clNone: (q) => `没有与「${q}」相关的更新。`,
      clClear: '清除',
      clEmpty: '仅内部改进。',
      clError: '未能加载更新日志。',
      clErrorLink: '在 GitHub 查看 CHANGELOG.md',
      clOnGithub: 'GitHub',
      clOnGithubLabel: (v) => `在 GitHub 查看 ${v} 发布页`,
      navNotes: '更新内容',
      navBuild: '自行构建',
      navCta: '下载',
      relAsking: '正在询问 GitHub……',
      relEmpty: '暂无发行版',
      relNone: '第一个发行版将出现在 GitHub 发行版页面。',
      relError: '无法连接 GitHub',
      relOffline: '无法连接 GitHub。文件始终可在发行版页面获取。',
      relRate: 'GitHub 暂时限制了来自你的地址的请求。文件可在发行版页面获取。',
      relPre: '预发行版 · ',
      relNoAssets: '最新发行版中没有构建文件。请查看发行版页面。',
      relIos: '你似乎在使用 iPhone 或 iPad。没有 iOS 版本；下方是适用于其他系统的文件。',
      pickTitle: '推荐用于你的设备',
      pickCta: '下载',
      dlNote: '平台是根据浏览器检测的，可能不准确。完整文件列表始终在发行版页面。',
      vfField: '预期哈希或 SHA256SUMS 的内容',
      vfPlaceholder: '粘贴 SHA256SUMS 中的一行或整个文件',
      vfHashing: (name) => `正在计算“${name}”的哈希……`,
      vfHashed: '哈希已计算。请粘贴发行版中的预期哈希以进行比对。',
      vfNoLine: (name) => `SHA256SUMS 中没有“${name}”对应的行。请确认选择的文件是否正确。`,
      vfNoHash: '输入框中没有 SHA256 哈希：需要 64 个十六进制字符。',
      vfUnreadable: '无法读取文件。请重试，或在终端中校验。',
      vfMatch: '一致：这就是预期的文件。',
      vfMiss: '不一致。请勿运行该文件，并到 issues 中反馈。',
      vfDiff: (actual, expected) => `实际：${actual}\n预期：${expected}`,
      vfTermUnix: 'Linux 和 macOS',
      footAbout: '一个开源的 Clash Meta（mihomo）客户端，不出售访问权限，也不提供订阅。',
      footSite: '站点',
      footSource: '源码',
      footBuiltOn: '基于',
      footFork: 'FlClash 的分支，与 FlClash、mihomo 或 FlClashX 无隶属关系。',
      footLive: '持续维护中',
      heroEyebrow: '最新版本',
      heroTitle: '下载，或自行构建。',
      tagPlatforms: '四个平台',
      tagSums: '每个发行版都带 SHA-256',
      heroBuild: '自行构建',
      dlSums: 'SHA256SUMS',
      clLead: '发行说明与文件列表一同来自 GitHub：当前发行版在前，较早的在下。',
      pfTitle: '各系统的安装包',
      pfLead: '每个发行版都提供同样的四个平台。',
      vfTitle: '下载完了？请先校验。',
      vfLead: '把刚下载的安装包拖进来，哈希在你的浏览器里算——文件不会离开这台设备。',
      vfPick: '把文件拖到这里，或点击选择',
      vfNamed: (name) => `正在校验 ${name}…`,
      vfEmpty: '这个发行版没有公布可用来比对的哈希。',
      bdTitle: '无需等待发行版，自行构建。',
      bdLead: '亲眼看到你运行的是什么，是信任一个客户端最直接的方式。',
      bdTerm: '构建',
      bdNote: 'Windows 需要 Visual Studio C++ 工具链；macOS 需要 Xcode。桌面端的可执行文件名是 SkywardCore。',
      prereq: [
        'Flutter 3.47.6（与发行版 CI 一致）、Go 与 Rust/Cargo。mihomo 内核和原生库都从源码构建。',
        'Windows：Visual Studio C++ 工具、GCC，以及用于生成安装程序的 Inno Setup。',
        'macOS：Xcode 和用于 appdmg 的 Node.js；运行需要 macOS 12 或更高版本。',
        'Linux：打包程序会请求管理员权限以安装原生依赖。',
      ],
      dlErrorLink: '在 GitHub 查看 CHANGELOG.md',
      filesEmpty: '这个发行版里没有适用于该平台的内容。',
      cardAndroid: '大多数手机请选择 arm64-v8a。包含快速设置图块、小组件和 Always-on VPN。',
      cardWindows:
        '安装程序为当前用户安装，并在后台自行更新，无需请求权限。TUN 模式需要管理员权限。',
      cardMacos:
        '不在 App Store 中分发：首次启动请用右键菜单 →「打开」。只要能写入自己所在的文件夹，它就会自行更新。',
      cardLinux:
        'AppImage 适用于 x64（先跑 chmod +x）；ARM64 提供 .deb、.rpm 和 pacman。要使用 TUN，请从应用内安装系统助手。',
      noteLinuxTray:
        '.deb 会自动安装所需依赖。使用 AppImage 或 .rpm 时，需要先安装 AyatanaAppIndicator 库，托盘图标才能显示。',
      tipFdroidTitle: 'F-Droid',
      tipFdroid: '在 F-Droid 客户端中添加 Skyward 仓库，即可在那里接收更新。',
      tipFdroidLink: '打开 F-Droid 仓库',
      loading: '正在加载…',
      copies: '复制',
      starsLabel: (n) => `GitHub 上有 ${n} 个星标`,
      typeBreaking: '不兼容变更',
      typeFeat: '新功能',
      typeFix: '问题修复',
      typePerf: '性能',
      typeRevert: '回退',
      footLicense: '以 GPL-3.0 协议免费开源。',
      footUpdated: '本页随每次发布自动更新。',
      footReleases: '发布页',
      footTelegram: 'Telegram 频道',
      stars: (n) => `GitHub 上有 ${n} 个星标`,
    },
  };

  function parseChangelog(markdown) {
    const versions = [];
    let version = null;
    let group = null;
    let entry = null;
    for (const raw of markdown.split(/\r?\n/)) {
      const line = raw.trimEnd();
      let match = line.match(/^## (v?\d[^\s(]*)(?: \((\d{4}-\d{2}-\d{2})\))?$/);
      if (match) {
        version = { tag: match[1], version: match[1].replace(/^v/, ''), date: match[2] || '', groups: [], empty: false };
        versions.push(version);
        group = null;
        entry = null;
        continue;
      }
      if (!version) continue;
      match = line.match(/^\*\*(.+)\*\*$/);
      if (match) {
        group = { type: TYPE_BY_TITLE[match[1]] || 'other', title: match[1], entries: [] };
        version.groups.push(group);
        entry = null;
        continue;
      }
      match = line.match(/^[-*] (.+)$/);
      if (match) {
        if (!group) {
          group = { type: null, title: '', entries: [] };
          version.groups.push(group);
        }
        entry = parseEntry(match[1]);
        group.entries.push(entry);
        continue;
      }
      if (entry && /^\s+\S/.test(raw)) {
        entry.text += ` ${raw.trim()}`;
        continue;
      }
      if (line === 'Internal improvements only.') version.empty = true;
    }
    return versions;
  }

  function parseEntry(source) {
    let text = source;
    let scope = null;
    let id = null;
    const scoped = text.match(/^\*\*([^*]+)\*\* (.+)$/);
    if (scoped) {
      scope = scoped[1];
      text = scoped[2];
    }
    const hashed = text.match(/^(.*) \(([0-9a-f]{7,40})\)$/);
    if (hashed) {
      text = hashed[1];
      id = hashed[2];
    }
    return { scope, text, id };
  }

  function translate(lang, key, ...args) {
    const value = STRINGS[lang][key] ?? STRINGS.en[key] ?? key;
    return typeof value === 'function' ? value(...args) : value;
  }

  function formatDate(iso, lang) {
    if (!iso) return '';
    return new Intl.DateTimeFormat(lang === 'zh' ? 'zh-CN' : 'en', {
      year: 'numeric',
      month: lang === 'zh' ? 'long' : 'short',
      day: 'numeric',
      timeZone: 'UTC',
    }).format(new Date(`${iso}T00:00:00Z`));
  }

  function changelogMeta(versions, lang) {
    const oldest = versions.filter((version) => version.date).pop();
    return oldest ? translate(lang, 'clMeta', versions.length, formatDate(oldest.date, lang)) : '';
  }

  function escapeHtml(text) {
    return String(text).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]);
  }

  function highlight(text, query) {
    if (!query) return escapeHtml(text);
    const lower = text.toLowerCase();
    let html = '';
    let from = 0;
    for (let at = lower.indexOf(query); at !== -1; at = lower.indexOf(query, from)) {
      html += `${escapeHtml(text.slice(from, at))}<mark>${escapeHtml(text.slice(at, at + query.length))}</mark>`;
      from = at + query.length;
    }
    return html + escapeHtml(text.slice(from));
  }

  function releaseHtml(version, groups, { lang, query, isLatest, ago }) {
    const t = (key, ...args) => translate(lang, key, ...args);
    const tag = escapeHtml(version.tag);
    let row = 0;
    const order = () => ` style="--i:${Math.min(row++, MAX_STAGGER)}"`;
    const sections = groups.map((group) => {
      const title = group.type ? (TYPE_KEYS[group.type] ? t(TYPE_KEYS[group.type]) : group.title) : '';
      const heading = title
        ? `<h3 class="group-title"${order()}><span class="mark" aria-hidden="true"></span>${escapeHtml(title)}</h3>`
        : '';
      const entries = group.entries.map((entry) => {
        const scope = entry.scope ? `<span class="scope">${highlight(entry.scope, query)}</span>` : '';
        const hash = entry.id ? `<a class="hash" href="${REPO}/commit/${entry.id}">${entry.id.slice(0, 7)}</a>` : '';
        return `<li class="entry"${order()}><span class="entry-text">${scope}${highlight(entry.text, query)}</span>${hash}</li>`;
      });
      return (
        `<section class="${group.type ? 'group' : 'group plain'}" data-type="${escapeHtml(group.type || 'plain')}">` +
        `${heading}<ul class="entries">${entries.join('')}</ul></section>`
      );
    });
    const empty = version.empty && !groups.length ? `<p class="empty">${escapeHtml(t('clEmpty'))}</p>` : '';
    const title = ago ? ` title="${escapeHtml(ago(version.date))}"` : '';
    const date = version.date
      ? `<span class="when"><time datetime="${version.date}"${title}>${formatDate(version.date, lang)}</time></span>`
      : '';
    return (
      `<article class="release" id="${tag}"><header class="release-head"><div class="ver-row">` +
      `<a class="ver" href="#${tag}">${highlight(version.version, query)}</a>` +
      (isLatest ? `<span class="latest">${escapeHtml(t('clLatest'))}</span>` : '') +
      `</div>${date}<span class="when"><a href="${REPO}/releases/tag/${tag}" ` +
      `aria-label="${escapeHtml(t('clOnGithubLabel', version.tag))}">${escapeHtml(t('clOnGithub'))} ${ICON_EXTERNAL}</a>` +
      `</span></header><div class="release-body">${empty}${sections.join('')}</div></article>`
    );
  }

  function timelineHtml(items, { lang, query = '', latestTag, ago, year = null }) {
    let html = '';
    for (const { version, groups } of items) {
      const releaseYear = version.date.slice(0, 4);
      if (releaseYear && releaseYear !== year) {
        html += `<div class="year">${releaseYear}</div>`;
        year = releaseYear;
      }
      html += releaseHtml(version, groups, { lang, query, isLatest: version.tag === latestTag, ago });
    }
    return { html, year };
  }

  return { REPO, FIRST_PAGE, STRINGS, parseChangelog, translate, formatDate, changelogMeta, escapeHtml, timelineHtml };
})();

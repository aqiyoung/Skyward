> **说明** — Skyward 最初基于 [chen08209](https://github.com/chen08209) 的 FlClash 修改而来，现作为独立项目维护。构建产物在[本仓库的发布页](../../releases/latest)；版本方案、签名改动与和上游的关系见 [FORK.md](FORK.md)。本仓库只发布客户端本体：不含任何代理服务器、订阅链接、账号或流量，也没有任何收费项目。

<div align="center">

<img src="assets/images/icon.png" alt="Skyward" width="88">

# Skyward

基于 ClashMeta 的多平台代理客户端，简单易用，开源无广告。

[English](README.md) · **简体中文**

[![Release](https://img.shields.io/github/v/release/aqiyoung/Skyward?style=flat-square&label=release)](https://github.com/aqiyoung/Skyward/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/aqiyoung/Skyward/total?style=flat-square&logo=github)](https://github.com/aqiyoung/Skyward/releases)
[![License](https://img.shields.io/github/license/aqiyoung/Skyward?style=flat-square)](LICENSE)
[![Telegram](https://img.shields.io/badge/Telegram-channel-26A5E4?style=flat-square&logo=telegram&logoColor=white)](https://t.me/sanyeinfo)

[发布页](https://github.com/aqiyoung/Skyward/releases/latest) · [下载](#下载) · [更新日志](CHANGELOG.md) · [从源码构建](#从源码构建)

</div>

## 功能

- **一个应用覆盖 Android、Windows、macOS 和 Linux**，桌面端同时提供 x64 与 ARM64 版本。
- **mihomo（Clash.Meta）内核**：规则分流、代理组、延迟测试、系统代理与 TUN 模式。内核以 v1.19.33 为基线，
  持续同步上游 Alpha，并保留一小层自有补丁（UDP 稳态快路径、队列加深）—— 属于数据面正确性修复，
  不代表 Android 上速率成倍提升。
- **配置管理**：通过订阅链接或文件导入配置，内置编辑器，支持覆写脚本以及自定义规则、代理和代理组。
- **实时查看**连接、请求、DNS 查询和日志。
- **泄露自检**：多解析器的 DNS 泄露检测，以及内置的 WebRTC（STUN）泄露检测，两者各自超时、异常隔离。
- **VPN 行为控制**（Android）：接管范围、局域网旁路、分应用代理。
- **TUN 栈选择**：gVisor、System、Mixed 与默认的 Mips 四档，App 内逐档说明；切换后需重启 VPN 生效。
- **Material You 设计，融合 Apple 式交互**：支持动态取色、浅色与深色主题，连续曲率圆角，弹出面板可在几档高度间吸附，布局随屏幕从手机到桌面自适应。
- **备份与恢复**：通过 WebDAV 或本地文件。
- **平台细节**：Android 上有快捷设置磁贴、分应用代理和 Android TV 支持；桌面端有托盘菜单和全局快捷键。
- **开源无广告**，以 GPL-3.0 协议发布。

> 上述新增功能先走 [预览 / 测试通道](FORK.md)，晋升后进入默认的 `main` 分支；三个渠道的区别见 [FORK.md](FORK.md)。

## 下载

从[本仓库的发布页](https://github.com/aqiyoung/Skyward/releases/latest)获取最新版本。

这些安装包只是客户端本体：不含任何代理服务器、订阅链接、账号或流量，也没有任何收费项目。

| 平台 | 安装包 | 说明 |
| --- | --- | --- |
| Android | `arm64-v8a`、`armeabi-v7a`、`x86_64` 三种 APK | 绝大多数手机选 `arm64-v8a`。 |
| Windows 10 及以上 | 安装版（`.exe`）或便携版（`.zip`），分 x64 与 ARM64 | 骁龙等 ARM 架构笔记本选 ARM64。 |
| macOS 12 及以上 | Apple Silicon 与 Intel 两种 DMG | |
| Linux | `.deb`、`.rpm` 和 AppImage，分 x64 与 ARM64 | 托盘依赖见下方说明。 |

<p>
  <a href="https://github.com/aqiyoung/Skyward/releases/latest"><img alt="Get it on GitHub" src="snapshots/get-it-on-github.svg" height="56"></a>
</p>

这些包由本仓库编译，用的是本仓库自己的签名证书。上游项目（官网、F-Droid 仓库、Homebrew tap）的包是另一套签名，
两边混装需要先卸载一次 —— 详见 [FORK.md](https://github.com/aqiyoung/Skyward/blob/main/FORK.md)。

**Linux 托盘图标**

`.deb` 安装包会自动安装所需依赖。使用 AppImage 或 `.rpm` 时，需要先安装 AyatanaAppIndicator 库，托盘图标才能显示：

```bash
sudo apt-get install libayatana-appindicator3-1   # Debian 与 Ubuntu
sudo dnf install libayatana-appindicator-gtk3     # Fedora
```

**无人值守的桌面环境**

FlClash 要在免责声明被接受后才会启动核心。在容器等无人点击的环境里，可在应用的环境变量中设置
`FLCLASH_ACCEPT_DISCLAIMER=1`，首次启动时即视为接受。

## 使用

**通过链接导入配置。** 打开下面格式的链接，即可把订阅导入 Skyward。`clashmeta://` 和 `flclash://` 开头的链接同样可用。

```text
clash://install-config?url=<经过 URL 编码的订阅链接>
```

**Android 自动化。** Tasker、MacroDroid 等应用可以用下面的 Action 启动 Activity，从而启动、停止或切换代理：

```text
com.threely.skyward.action.START
com.threely.skyward.action.STOP
com.threely.skyward.action.TOGGLE
```

在电脑上也可以通过 adb 触发：

```bash
adb shell am start -a com.threely.skyward.action.TOGGLE
```

## 从源码构建

需要 [Flutter](https://docs.flutter.dev/get-started/install) 3.47（正式版构建使用 3.47.6）、[Go](https://go.dev/dl/) 1.27，
以及通过 rustup 安装的 [Rust](https://rustup.rs/)。桌面端需要在对应系统上构建，Android 在任意系统上都能构建。

```bash
git clone --recursive https://github.com/aqiyoung/Skyward.git
cd FlClash
flutter pub get
dart setup.dart android   # 或 windows、macos、linux
```

安装包输出到 `dist/`。Go 内核和 Rust 库会在 Flutter 构建过程中一并编译。

| 平台 | 额外依赖 |
| --- | --- |
| Android | 带 NDK 的 Android SDK。加上 `--arch arm64` 可以只构建单个 ABI。 |
| Windows | 编译内核用的 GCC（MinGW-w64），以及打包安装程序用的 [Inno Setup](https://jrsoftware.org/isinfo.php) 6。 |
| macOS | Xcode 与 Node.js。脚本会通过 npm 安装 `appdmg`。 |
| Linux | Debian 或 Ubuntu。脚本会用 apt 安装构建所需的软件包，并下载 `appimagetool`。 |

其余选项可以运行 `dart setup.dart --help` 查看，例如用 `--targets` 只构建部分安装包格式。

## 支持

给仓库点一个 Star 是支持项目最简单的方式。问题讨论和更新通知请关注 [Telegram 频道](https://t.me/sanyeinfo)，
Bug 与功能建议请提交到 [GitHub Issues](https://github.com/aqiyoung/Skyward/issues)。

<a href="https://star-history.com/#aqiyoung/Skyward&Date">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=aqiyoung/Skyward&type=Date&theme=dark">
    <img alt="Star history" src="https://api.star-history.com/svg?repos=aqiyoung/Skyward&type=Date" width="640">
  </picture>
</a>

## 许可证

Skyward 以 [GPL-3.0 协议](LICENSE)发布。

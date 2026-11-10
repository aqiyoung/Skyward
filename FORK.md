# Skyward

Skyward 是一个多平台代理客户端，基于 Clash.Meta（mihomo）内核。本项目**最初从 [chen08209/FlClash](https://github.com/chen08209/FlClash) fork 修改而来**，自 2026 年起作为**独立项目维护**：不再同步上游代码、不再跟随上游版本，版本号与发版流程完全由本项目自己掌控。发布仍以 **Skyward** 名义：包名、桌面图标下的名字和安装包文件名都是自己的，和上游官方包分别安装。构建由 GitHub Actions 全平台完成、自签名，发布到本仓库的 Releases（同时推送到 TG 频道 [@sanyeinfo](https://t.me/sanyeinfo)）。

本仓库只发布**客户端本体**：不含任何代理服务器、订阅链接、账号或流量，也没有任何收费项目。装好之后用什么配置，由使用者自己填。

**装哪个**

- **正式版**（推荐）：[最新 Release](../../releases/latest) 里 `Skyward-` 开头的安装包。`/releases/latest` 永远指向正式版。
- **测试版**：在 [Releases 列表](../../releases) 里标着 *Pre-release* 的那个，比正式版新，也可能有问题。
- **预览版**：只有 Android arm64 一个包，每次代码有改动就自动构建（tag 形如 `preview-<构建号>`）。它是我们自己装机试新功能用的，比测试版更早、也更糙。

Android 一般下 `-arm64-v8a.apk`（绝大多数手机）或 `-armeabi-v7a.apk`（老机器），模拟器下 `-x86_64.apk`。

## 版本号

```
<本项目自有 base>.<序号>[-渠道]
例如        1.0.1.6-beta     1.0.1.6     1.0.1.07-pre     1.0.1.07-dev
```

- 前三段（base）是 **Skyward 自己的版本 base**，不再取自上游 `pubspec.yaml`、也不再跟随上游版本号。当前 base 为 `1.0.1`。
- 第四位分两种，看渠道：**正式版和测试版**共用一条发布序号，一路往上数、每次发版 +1，把 beta 晋升成正式版时也拿一个新号——这样 beta 用户也会收到正式版的更新提示；**预览版和 dev 版**不占发布号，第四位是当天的第几次构建（`01` 起），因为它们是同一天的快照，不是发布。
- 渠道写在**后缀**里：正式版没有后缀，测试版 `-beta`，预览版 `-pre`，dev 版 `-dev`。数字部分干净、固定四段，看得懂哪条线、第几次构建、哪个渠道。
- **Release tag 就是带后缀的完整版本**（如 `v1.0.1.6-beta`）。
- 装上去的包处处显示这个版本：pub 不接受四段版本号，`pubspec.yaml` 里只能写三段，所以版本名在构建时以 `APP_VERSION` 注入（`setup.dart` 读 CI 的 `APP_VERSION_NAME`，写进 `env.json` 的 dart-define），`PackageInfo.displayVersion` 优先用它、为空时回落到 `package_info_plus` 的三段；Android 的 `versionName` 也直接写它，所以「设置 → 应用 → Skyward」里看到的和 App 里的一致。
- 每次构建另外带一个 **`20900000 + 自 2026-01-01 起的天数×100 + 当天序号`** 的构建号，写进 `pubspec.yaml`（构建时注入、不提交），它就是 APK 的 `versionCode`，保证新包一定比手机里那个"更新"，否则 Android 会拒绝覆盖安装。**这个数字不出现在版本名里**，只记在 Release 说明和 APK 元数据里；App 通过 `APP_BUILD_NUMBER` 拿到自己那一份，用来和 Release 说明里的构建号比大小——这就是「检查更新」判断新旧的依据。
- 三个写构建号的地方（预览、dev、正式/测试版）读同一本账：当天已占的 `preview-*` / `dev-*` tag，加上最近一次 Release 说明里的构建号，取最大再 +1，所以谁先谁后都不会撞号。

## 三个渠道

| 渠道 | 分支 | 内容 | Release |
| --- | --- | --- | --- |
| 正式版 | [`main`](../../tree/main) | 已经跑过测试版的代码，晋升进来的 | 标为 Latest |
| 测试版 | [`beta`](../../tree/beta) | beta 分支的代码 + 我们自己的改动 | prerelease，不抢占 Latest |
| 预览版 | [`beta`](../../tree/beta) | 同上，只构建 Android arm64、不跑测试 | prerelease，tag 是 `preview-*` |

三个渠道依次走：预览版是还在改的快速验证包，稳定下来才发测试版，测试版跑一段没问题才晋升成正式版。三个渠道**同包名**（`com.threely.skyward`）、**同签名**，可以互相覆盖安装，`versionCode` 保证单调递增。

每个 Release 的说明里先列**自该渠道上一个版本以来的提交标题**（自动生成的更新日志，最多 40 条），TG 推送里也带上前面几条；`ci:` 这类纯自动化的提交不列。

## 与上游的差异

改动都在 `main` / `beta` 上，以提交的形式存在。`beta` 从 `main` 晋升而来（`main` 是稳定版、`beta` 是测试版）；**自独立维护后不再 rebase 到上游，也不再引入上游的新提交**。fork 初期引入、且仍保留的历史差异包括：

| 改动 | 说明 |
| --- | --- |
| 免责声明 | 保留全部条款文案，把手机上"照着把声明敲一遍"改成勾选确认 |
| 关于页 | 去掉上游的 Telegram 频道入口（那个频道不是本仓库运营的） |
| 内核来源 | 内核（mihomo）改从本仓库作者的 fork `aqiyoung/skyward-core` 取，`FlClash` 分支是官方 mihomo 版本加上补丁层，关于页的「内核」链接也指向它。上游 README 要求非 MetaCubeX 的下游项目名字里不能带 `mihomo`，所以 fork 叫 `skyward-core`。Go 模块路径仍是 `github.com/metacubex/mihomo`、目录仍是 `core/Clash.Meta`——不为了改名去动上游代码的 import |
| 更新检查 | 指向本仓库的 Releases，而不是上游；版本比较额外认我们自己的第四位 |
| 版本名 | 四段版本号由构建注入：Android 走 `versionName`，桌面端走 `APP_VERSION` dart-define（`pubspec.yaml` 仍是三段） |
| 包名 | Android 的 `applicationId` 改成 `com.threely.skyward`（2026-10-18 起先用 `com.threely.clash`，2026-10-21 随改名换成现在这个）。本仓库用自己的名字发布，和上游官方包分别安装 |
| 服务图标 | 仪表盘「服务状态」的 13 个服务图标由单色改为品牌色，图标底板固定浅色 |
| 仪表盘 | 「状态」卡片里的出口国家由两个大写字母改成国旗；国旗底下原来的四叶草去掉、只留国旗，检查出口时由旋转改为渐隐 |
| 用量进度 | 仪表盘「配置」卡片的用量进度由上游的 M3 波浪线改成直线（改 `lib/views/dashboard/widgets/profiles.dart`） |
| README | 下载徽章、下载按钮、官网链接、F-Droid 仓库、Homebrew tap、TG 频道都换成本仓库 / [@sanyeinfo](https://t.me/sanyeinfo)——上游那些入口装出来的是另一套签名的包 |
| dock 玻璃 | 主题设置里开「液态玻璃」后，dock 的观感更贴 iOS 27：tint 不再被 `contrast` 加厚（更透）、镜片折射与色散加深、顶底高光与两侧暗线更明显、选中底板由副色改成中性色（在 `lib/ui/liquid_glass.dart` 与 `lib/ui/navigation_dock.dart`，留意这两处） |
| Windows 安装 | 安装包不再沿用上游的 AppId，装进 `Program Files\Skyward`、开始菜单与桌面快捷方式用自己的图标；数据目录由 `%APPDATA%\com.follow\clash` 改成 `%APPDATA%\Skyward`，旧目录在首次启动时整体改名过去，配置不丢 |

另外两件不在代码里的事：

- **重新签名**：本仓库用自己的证书签名，不改上游官方包的签名——**不加固、不夹带、不绕过检测**。国内手机管家（腾讯引擎）会把一批个人自签名的应用标成 `a.gray.BulimiaTGen.*`「风险应用」，这个判定跟着**签名证书**走：换一张新证书往往就干净了，所以本仓库的证书在 2026-10-21 换过一次（换之前那张在 2026-10-17 之前签过上游 APK 的重打包产物，被人报过毒，判定留在了证书上）。这是签名本身的事，不影响代码。2026-10-21 实测：换上新证书、改掉包名之后，手机管家不再报毒。
- **构建**：本目录不含构建产物，全部由 GitHub Actions 构建。

### 签名变了、包名也换了，第一次要卸载

本仓库的签名与上游官方版、以及 2026-10-21 之前本仓库发的包都不同，装不上；包名也和之前发过的包不同（`com.follow.clash` → `com.threely.clash` → `com.threely.skyward`），不会覆盖安装，而是并排装成几个 App。**先卸载旧版（配置先在 App 里备份出来），再安装**。之后本仓库自己的版本之间（同一个 `com.threely.skyward`）可以直接覆盖升级。

证书 SHA-256：

```
65:37:9E:D7:25:AB:FD:23:30:BC:21:34:AA:A2:76:BA:59:A5:0D:5E:60:6F:44:38:18:00:3F:36:2C:59:35:70
```

### 之前那次报毒是怎么回事

2026-10-21 之前，本仓库发出去的包在部分国产 ROM 上会被腾讯引擎标成「风险应用」（`a.gray.BulimiaTGen.*`）。它标的不是恶意代码：同一批标签也落在 AdAway、fcitx5-android 等一堆无关的开源应用上，社区里的说法是它标的是「个人开发者签名 + 功能偏多」的那一类。换一张新证书、改一个没被收录过的包名之后，实测就不再报了。

换证书只是把旧判定清掉，病毒库更新后有可能再被标回来（社区里有人换签名后只干净了几天）。要根治还是得走腾讯的申诉工单。

## 构建流程

默认分支 `main` 上带着工作流，自动化脚本的源头在 `ci` 分支。**自独立维护后不再与上游同步**：本仓库的 `ci` 工作流只负责构建与发布，不会再去拉上游 `dev` 或把 `beta` rebase 到上游。**需要新功能 / 修复时，直接在本仓库的 `beta` 上改**，跑完测试与构建后晋升进 `main`。

`beta` 的改动通过 `promote` 手动晋升进 `main`：把 `beta` 的代码合进 `main`，再构建并发布正式版。所以正式版发出去的代码一定先在 `beta` 上跑过。预览版不占版本号，只是每次推 `beta` 时出的 Android 试机包。

macOS 产物没有 Apple 开发者证书，是**未签名**的，首次打开要在「系统设置 → 隐私与安全性」里放行。

维护细节（分支结构、版本号规则、晋升、冲突处理、需要的 Secrets）写在 [`ci` 分支的 README](../../blob/ci/README.md)。

### Windows 上换过身份，旧的装过一次要卸

1.0.0.3 及之前的 Windows 安装包沿用了上游的 AppId，会装进旧的 FlClash 目录、也复用它的快捷方式；从 1.0.0.4 起安装包有自己的 AppId，装进 `Program Files\Skyward`。所以 Windows 上如果装过 1.0.0.3 或更早的版本，先在「设置 → 应用」里把旧的 Skyward / FlClash 条目卸载一次，再装新版，否则两个条目会同时存在。配置目录会自动迁移，不用手动搬。

## 鸣谢 / Acknowledgments

Skyward 最初基于 [chen08209/FlClash](https://github.com/chen08209/FlClash) 修改而来，并在其基础上做了大量定制；其代理内核使用 [MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo)（Clash.Meta）。在此对上游作者与相关开源项目致谢：

- **FlClash**（[chen08209/FlClash](https://github.com/chen08209/FlClash)）：本项目的起点与 UI 基础。
- **mihomo / Clash.Meta**（[MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo)）：代理内核。
- 构建所依赖的工具链（如 [flutter_distributor](https://github.com/aqiyoung/flutter_distributor)，本仓库镜像自 fastforge）。

本仓库产物与上游一样受 **GPL-3.0** 约束；使用、修改与分发请遵守该许可证，派生作品同样须以 GPL-3.0 发布并保留原始版权声明。

## License

上游 FlClash 是 GPL-3.0，本仓库产物同样受 GPL-3.0 约束。

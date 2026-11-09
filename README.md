# Skyward 重建版（自签名 release）

本分支（`ci`）只放自动化脚本，不存放应用源码；仓库的**默认分支是 `main`**，那上面是应用源码。晋升时会把这几份工作流从 `ci` 拷回 `main`。安装包发布在本仓库的 Releases。

## 为什么有它

上游 [chen08209/FlClash](https://github.com/chen08209/FlClash) 的官方 APK 在国内部分 ROM 上装不上：小米安全中心（腾讯引擎）把它判成风险应用。

排查出来的结论是：**这个判定跟着"签名证书"走，而不是跟着代码走**。同一份代码，换个签名，判定就变了。我们做过的对照实验：

| 实验包 | 代码 | 证书 | 结果 |
| --- | --- | --- | --- |
| `diag-resign-v0.9.0` | 同一份 | 旧：`O=FlClash, CN=FlClash` | **报毒** |
| `diag-resign-newcert` | 同一份 | 新：`O=aqiyoung` | 不报 |
| `diag-renamed` | 同一份 | 新 | 不报 |

所以我们只做一件事：**换一张中性证书重新签名**。不加固、不夹带、不绕过检测——让检测"看不见"的那种做法不属于这个项目。

代价：签名变了，Android 不允许跨签名覆盖安装。**从任何其它版本（官方版、以及本仓库在 2026-10-17 之前发的包）切过来，都要先卸载一次**；这之后，本仓库自己的版本之间可以直接覆盖升级。

包名是本仓库自己的 `com.threely.skyward`。三个渠道**同包名、同签名**，互相可以覆盖安装。

APK 签名证书（SHA-256）：`04:89:68:C1:72:8E:0E:2E:27:E7:04:D6:B3:01:74:27:65:79:BA:A2:FA:28:8F:4F:1B:A3:75:B7:02:C7:E4:31`

## 分支结构

| 分支 | 内容 |
| --- | --- |
| `main`（默认） | 正式版渠道构建的分支；只由 `beta` 晋升而来 |
| `beta` | 项目的开发主线；预览版和测试版都构建它 |
| `ci` | 只有自动化：`.github/workflows/` + 本文件 |

Skyward 自 2026 年 11 月起独立维护，`beta` 就是本项目的开发主线，不再跟踪上游。CI 里仍留着一个默认关闭的 `sync` 开关：需要吸收 FlClash 的改动时，手动把我们的提交 **rebase** 到上游 `dev` 上——那是一条可选的退路，不是日常流程。

`main` 同样**自成一路**：正式版发的是"在 beta 上跑过、被判定稳定"的那份代码。晋升（`promote` 输入）时**直接把 `main` 的树换成 beta 的树**（`git read-tree -u --reset beta`）：merge 或 `-X theirs` 都会把两条线并起来，那样正式版就会带上 beta 没跑过的代码。换完再把工作流副本从 `ci` 取回来，并检查 `main` 与 `beta` 的差异只剩工作流，否则中止。

用 `sync` 时为什么必须 rebase：FlClash 会改写 `dev` 的历史（force-push），merge 无从谈起。rebase 的代价是遇到冲突要人处理，所以**冲突就停下**——同步任务会中止、推 TG 告警、并且**不构建**，不会静默地用上游代码盖掉我们的改动。`sync` **只手动触发**，没有定时任务：冲突需要人看。

### 我们自己的提交

| 提交 | 说明 |
| --- | --- |
| 免责声明 | 保留全部条款文案，把"照着把声明敲一遍"改成勾选确认 |
| 测试 | 跟着改掉只会打字才能过的用例 |
| 关于页 | 去掉上游的 Telegram 频道入口（那个频道不是我们运营的） |
| 更新检查（两个渠道） | 指向本仓库的 Releases，而不是上游；`compareVersions` 额外认我们自己的第四位（`lib/common/package.dart`） |
| Android 版本名 | `versionName` 由构建通过 `APP_VERSION_NAME` 注入四段版本（`android/app/build.gradle.kts`） |
| 服务状态的图标 | 13 个服务图标由单色改为品牌色，图标底板固定浅色 |
| 仪表盘的图标 | 「状态」卡片里的出口国家由两个大写字母改成国旗（沿用服务状态那套 Twemoji 国旗连字，不引入新资源） |

免责声明那条是**接着上游写的**：上游 0.9.1 起给遥控器设备提供了勾选路径，但手机上仍然是打字。我们只是把这个勾选路径改成所有设备都走，差异因此很小。

（0.9.0 时期 `main` 上还从 `dev` 回移过三条 l10n 文案；上游 0.9.1 自己发了这些键，那条回移已经删掉。）

服务图标那条只动了资产和一处底板颜色：13 个 SVG 原来是 `fill="currentColor"`（跟着主题染色），现在换成各自的品牌色，形状一个没动。因为 GitHub、TikTok 这些品牌色本身是纯黑，压到深色主题的卡片上会看不见，所以图标底板从"跟随主题的表面色"改成固定浅色。另外把"服务已关闭"的灰化从染色改成整枚图标降透明度（`opacity38` → `Opacity`），否则关掉的服务会和打开的长得一样。色值与出处记在 `assets/images/services/LICENSE.md`。

## 版本号

```
<上游版本>.<我们自己的迭代号>     用户看到的版本，例如 0.9.1.13
<20900294><当天序号>             构建号（= versionCode），例如 2090029401
```

- 前三段取自上游 `pubspec.yaml`，我们不动。
- **第四位是我们自己的迭代号**：从我们发的第一个版本起一路往上数，**不随上游版本重置**。每次发版（测试版或正式版）都 +1；预览版不占号，只在 `preview-*` tag 下走；晋升也拿一个新号（beta 拿到 `0.9.1.7`，晋升后的正式版是 `0.9.1.8`），这样 beta 用户也会被提示去装正式版。取值方式：从已有 Release 的 tag 里匹配 `v<三段>.<第四位>`，取最大值加一。
- **Release tag 就是这四段版本**，测试版和正式版一样（`v0.9.1.13`）。App 内更新检查拿 `/releases/latest` 的 tag 和自己的版本名比：相等不提示，第四位变大才提示——"上游没动、只是我们重建"因此也能推给用户。
- 第四位只有 Android 能显示：pub 拒绝四段版本号，`pubspec.yaml` 里只能写三段，所以 `android/app/build.gradle.kts` 从 `APP_VERSION_NAME` 环境变量取 `versionName`；桌面端（deb/rpm/dmg/exe）显示的还是上游那三段。`compareVersions` 也只在**双方都有**第四位时才比它——比成 0 的话，桌面端会永远把自己的 Release 当成更新。
- **构建号**是 APK 的 `versionCode`，写进 `pubspec.yaml` 的 `+` 后面（构建时注入，不提交）。它是"**当天**已用最大值加一"，不分版本、也不数 tag 个数：数 tag 假设序号连续，少一个 tag 就会重号；按版本分别数则会在上游当天又发一版时从 `01` 重来，得到比手机里已装的更小的 `versionCode`，Android 不允许这样覆盖安装。三个渠道共用一个计数器，依次各取一个：同日 `stable` 拿 `…05`、`beta` 拿 `…06`、`preview` 拿 `…07`；晋升同样消耗一个号。
- 构建号写在 Release 的说明里（tag 只放版本），下一次同步从 Release 标题和说明里读回来；所以同一个上游版本重建、乃至一天里发多次，`versionCode` 都不会撞。
- `+` 在链接里要写成 `%2B`。现在的 tag 里已经没有 `+`，发布脚本里的转义留着以防万一。

| 渠道 | 分支 | 怎么发 | Release |
| --- | --- | --- | --- |
| 预览版 | `beta` | 每次推 `beta` 自动构建（`preview.yaml`），也可以手动 `channel=preview` | prerelease，tag `preview-<构建号>`，只发 Android arm64，不占版本号 |
| 测试版 | `beta` | 手动 `channel=beta -f force_build=true` | prerelease，tag `v<版本>`，7 个平台 |
| 正式版 | `main` | 手动 `channel=stable -f promote=true -f publish=true` | 标记 Latest，tag `v<版本>`，7 个平台 |

三个渠道依次晋升：预览版是"还在改"的快速验证包，稳定下来才发测试版，测试版跑一段没问题才晋升成正式版。预览版走 `preview-*` tag、不占第四位版本号，正式版和测试版才占。

App 内更新检查读的是 `/releases/latest`（只挑正式版），所以预览版和测试版都不会推给正式版用户。

## 流程

```
预览版（每次推 beta，或手动 channel=preview）
  └─ build    Android arm64 单架构，不跑测试
  └─ release  tag preview-<构建号> → prerelease → 推 TG（保留最近 5 个）

测试版（手动 channel=beta -f force_build=true）
  └─ [sync]   （可选）beta ← 上游 dev：只有 -f sync=true 才做
  └─ test     跑完整 flutter 测试
  └─ build    矩阵 7 个平台
  └─ release  tag v<版本> → prerelease → 推 TG

正式版（手动 channel=stable -f promote=true）
  └─ promote  main ← beta：直接取 beta 的树 + 从 ci 刷新工作流副本
  └─ test / build / release   同上，Release 标记 Latest
```

- 构建矩阵：

  | 平台 | runner |
  | --- | --- |
  | android | ubuntu-latest |
  | linux amd64 / arm64 | ubuntu-22.04 / ubuntu-24.04-arm |
  | windows amd64 / arm64 | windows-2022 / windows-11-arm |
  | macos amd64 / arm64 | macos-15-intel / macos-latest |

- **测试不过就不发布**：发布挂在"该渠道的测试通过"这个条件上。
- **什么都没动就不构建**：`sync=true` 且上游没动、也没晋升时，测试版/正式版跳过；预览版只要你要，就从 `beta` 当前内容构建。
- 单个平台构建失败**不阻塞**其它平台的发布；该渠道整体失败则不发布。
- `macos` 没有 Apple 开发者证书，产物是**未签名**的（首次打开要在「系统设置 → 隐私与安全性」里放行）。
- 推 `main`/`beta` 会触发这两个分支上**上游自带**的工作流。`build.yaml` 必须保持**手动禁用**：它的触发条件是 `branches: ['**']` 加 `tags: ['v*']`，也就是我们每次同步、每次发布打 tag 都会撞上它。`pages.yaml` 有 `github.repository` 守卫，跑起来什么也不做。

## 内核版本提醒（`core-watch.yaml`）

内核是子模块（`core/Clash.Meta` → `aqiyoung/skyward-core`），pin 只有人动才动，所以上游发了新 release 本仓库是不知道的。这份工作流每天早上跑一次（01:00 UTC，即 09:00）：读 `beta` 上 `build_config.yaml` 的 `core_version`，跟 `MetaCubeX/mihomo` 的最新 release 比，不一致就往 TG 推一条提醒，正文直接给出升内核的三步。

- **只提醒一次**：发完消息会打一个轻量 tag `core-watch-<版本>`，下次跑看到它就不再发。删掉那个 tag 可以再提醒一遍；推送失败则不打 tag，下一次运行会重试。
- **它不改代码**：移 pin 和改版本串是人的决定，自动把内核推上去等于把没跑过 beta 的上游代码发到手机上。
- **`schedule` 只在默认分支生效**，所以这份工作流必须进 `main`。晋升时从 `ci` 拷哪些工作流写在 `ci.yaml` 的 `promote` 段里，新增工作流要加进那个清单，否则 `main` 上永远没有它。
- 升内核的完整步骤（镜像快进、移 pin、依赖变动）见 `beta` 上的 [`.agents/core-sync.md`](../blob/beta/.agents/core-sync.md)。

## 手动触发

```bash
# 预览版：同步上游（sync=true）+ 只构建 Android，发到手机上试
gh workflow run ci.yaml -R aqiyoung/Skyward --ref ci -f channel=preview -f sync=true

# 预览版：不动上游，只按 beta 当前内容重建一个
gh workflow run ci.yaml -R aqiyoung/Skyward --ref ci -f channel=preview

# 测试版：全平台构建 + prerelease（beta 只在上游同步过、或显式 force_build 时才构建）
gh workflow run ci.yaml -R aqiyoung/Skyward --ref ci -f channel=beta -f force_build=true

# 正式版：把 beta 晋升进 main，并构建发布 Latest
gh workflow run ci.yaml -R aqiyoung/Skyward --ref ci -f channel=stable -f promote=true

# 什么都不发，只验证（不创建 Release、不推 TG）
gh workflow run ci.yaml -R aqiyoung/Skyward --ref ci -f channel=all -f force_build=true -f publish=false
```

`promote` 只在选了稳定渠道时有意义（`channel=all` 或 `channel=stable`）；只选 `channel=beta` 时会被忽略并打一条 notice。`force_build` 的含义是"什么都没动也构建"，不会替你造出还不存在的分支。

## 需要修改代码时

应用改动提交到 `beta`：推上去会自动出一个预览版（Android arm64），装到手机上试。要发全平台就先 `channel=beta -f force_build=true`（测试必须是绿的；`publish` 默认就是 true），要正式发布再 `channel=stable -f promote=true`。**不要指望直接往 `main` 提交应用代码**：`main` 只在晋升时从 `beta` 更新，届时应用代码一律以 `beta` 为准。

工作流改动提交到 `ci`：手动触发都用 `--ref ci`，跑的就是 `ci` 上的那份，改完立刻生效；晋升时 `ci` 上的四份工作流会被拷到 `main`。

`preview.yaml` 是例外，它**同时**存在于 `ci` 和 `beta` 树上（按 push 触发的工作流只能跑在收到 push 的那个分支上），两份要**逐字节相同**：改的时候先改 `ci`，再把同一份提交到 `beta`。

## 万一用到 sync、报冲突时

同步任务发现我们的提交重放不上上游代码时，会**中止、不构建、不发布**，并往 TG 推一条告警。处理办法：

1. 先判断冲突的那部分改动**上游是不是已经自己做了**。上游一旦自己实现，我们的补丁就该整条丢掉（0.9.1 的 l10n 回移就是这么处理的）——留着只会让之后每次同步都再冲突一遍。
2. 把分支重建为「上游最新 + 我们剩下的提交」。本地 clone 上游历史很大、经常超时；可行的做法是用 GitHub API 拼树（`git/blobs` → `git/trees`（带 `base_tree`）→ `git/commits` → `PATCH git/refs/heads/<branch>`），或者先在上游那个 commit 上开一个临时 ref、fetch 回来再用真 git 操作。
3. 推完**必须**带 `force_build=true` 触发一次：你已经自己 rebase 到上游了，同步任务会认为"上游没动"而跳过构建。
4. 稳妥起见先 `-f publish=false` 跑一次，测试绿了再正式发。

```bash
gh workflow run ci.yaml -R aqiyoung/Skyward --ref ci \
  -f channel=all -f force_build=true -f publish=false
```

## 需要的 Secrets

| Secret | 用途 | 状态 |
| --- | --- | --- |
| `KEYSTORE` | APK 签名 keystore（base64 编码的 PKCS12） | 已配置（2026-10-17 换成中性证书） |
| `STORE_PASSWORD` | keystore 密码 | 已配置 |
| `KEY_ALIAS` | key alias（`flclash`） | 已配置 |
| `KEY_PASSWORD` | key 密码 | 已配置 |
| `MIRROR_TOKEN` | 推送 `main`/`beta` 用的 PAT，需要 **`workflow`** scope | 已配置 |
| `TELEGRAM_BOT_TOKEN` | 推送用的 bot token | 已配置 |
| `TELEGRAM_CHAT_ID` | 目标会话 / 群，如 `-100xxxxxxxxxx` | 已配置 |

两个 `TELEGRAM_*` 只要有一个没配，**推送步骤会自动跳过**，其余照常发布。

### 推送长什么样

跟 `aqiyoung/datbox-android`、`aqiyoung/iptv-app-check` 里那套一样：`curl` 调 `sendMessage`，正文先写**这次改了什么**（自该渠道上一个 Release 以来的提交标题，最多 15 条，`ci:` 这类自动化提交不列），再列几个平台的**下载直链**，直链前面挂 `https://gh-proxy.com/` 前缀（release 资产在 GitHub 上，很多人打不开）。Release 说明里放的是完整那份（最多 40 条）。因此：

1. **不发文件本身**。安装包动辄 60 MB+，超过云端 Bot API 的 50 MB 上传上限；发链接就没有这个问题，也不用起自建的 Bot API 服务。
2. **bot 得能往目标会话发消息**：发群要先把这个 bot 拉进群，`TELEGRAM_CHAT_ID` 用 `-100…` 那种群 id。
3. 想增减推送哪些安装包，改 `publish-release.yaml` 里遍历 `dist/*` 的那段。

## 关于 MIRROR_TOKEN

推送分支时如果提交里包含 `.github/workflows/` 下的文件，GitHub 会拒绝 `GITHUB_TOKEN`（它拿不到 `workflows` 权限）。用了 `sync` 时，rebase 过来的上游提交里就有这些文件，所以那种推送必须用一个带 `workflow` scope 的 PAT。

> ⚠️ 目前填的是账号的 **classic PAT**，权限很宽（含 `delete_repo`、`admin:org` 等）。建议换成**只对这个仓库生效的 fine-grained PAT**：
> - Repository access：仅 `aqiyoung/Skyward`
> - Permissions：`Contents: Read and write`、`Workflows: Read and write`
>
> 换掉之后不需要改工作流，只要更新 `MIRROR_TOKEN` 这个 secret。

## 安装注意事项

- **跨签名必须卸载**：官方版、以及 2026-10-17 之前本仓库发的包，都和我们现在的签名不同，装不上；先卸载，再安装。
- 此后本仓库自己的版本之间可以直接覆盖升级。
- 小米/红米上如果弹出"风险应用"提示：这在换证书之前是常态；如果新版仍被拦，可以在 `安全中心 → 病毒查杀 → 信任名单` 里放开，或用 `adb install -r <apk>` 兜底。

## License

本项目源自 FlClash（GPL-3.0），产物同样以 GPL-3.0 分发；`LICENSE` 保留上游的版权声明。

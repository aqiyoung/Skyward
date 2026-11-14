# Skyward Rust Core · PoC-6（0.1.0.19-dev · 网络概览接真实探测）

一版可装机的最小骨架，用来回答三个问题：

1. 安卓客户端能不能尽量用 Rust 写 → 能，但 `VpnService` 必须留几十行 Java 壳。
2. 换成 Rust 后体积能压到多少 → 量架构开销，见构建产物。
3. 性能会不会变差 → 规则引擎 / 数据面基准按需在「我的 → 工具」里跑，并带索引 / 线性对照。

> **PoC-6 起内核不再是「模拟数据面」**：本地 SOCKS5 入口 + Shadowsocks AEAD（ChaCha20-Poly1305）
> 出站 + TUN 接管已在 Rust 侧跑通端到端真实转发（单元 + echo 回环实测），UI 上明确区分
> 「模拟会话」与「真实代理流量」。

## 版本线

| 版本 | 内容 | APK |
|---|---|---:|
| `0.1.0.4-dev` | PoC-1：单按钮基准面板，验证架构体积下限 | 0.35 MB |
| `0.1.0.5-dev` | 4 Tab 原生 View UI 骨架，修掉启动卡 `running...` | 0.36 MB |
| `0.1.0.6-dev` | 索引引擎修 O(n) 塌方 + 会话真值 + 状态持久化 | 0.39 MB |
| `0.1.0.7-dev` | App 图标 / logo + 修复资源链路 | 0.42 MB |
| `0.1.0.8-dev` | 换成原 Flutter 版正式 logo（不再自绘） | 0.44 MB |
| `0.1.0.9-dev` | 内核网络探针（真实 DNS + TCP）+ 数据面验证卡 | 0.78 MB |
| `0.1.0.10-dev` | 会话真值全量接入首页 + 内核信息实时读数 | 0.82 MB |
| `0.1.0.11-dev` | VpnService 壳 + TUN 接管 + 真实吞吐统计 37 个 JNI 符号 | 0.98 MB |
| `0.1.0.12-dev` | **PoC-6 真实代理数据面**：SOCKS5 入口 + SS AEAD 出站 + 端到端真实转发 + 本地代理入口 UI | ≈ 1.0 MB |
| `0.1.0.13-dev` | 首页按定稿设计用原生 View 重写：仪表盘状态卡 / Canvas 线框地球 / 悬浮液态玻璃 dock | 1.02 MB |
| `0.1.0.14-dev` | **五页统一设计语言**：32sp 标题 + DEV 徽章、22 圆角白卡、代理/规则/配置摘要卡、dock 让位 | 1.02 MB |
| `0.1.0.15-dev` | 回滚到 0.1.0.12 的页面代码恢复可启动 + CrashGuard 堆栈落盘 | 1.02 MB |
| `0.1.0.16-dev` | 照 `lib/views/dashboard` 源码复刻首页：7 卡、34 圆角、20/18 内边距 | 1.02 MB |
| `0.1.0.17-dev` | 补回被回滚误删的「本地代理入口」+ 五页统一卡片几何 | 1.02 MB |
| `0.1.0.18-dev` | 修 `Pages.home` 重复 addView 的启动闪退；胶囊 dock / 16dp 页边距 / 8dp 卡距 / 定宽速率区 | 1.02 MB |
| `0.1.0.19-dev` | **网络概览按 `service_status.dart` 做成 2×2 服务格 + TCP 握手探测真实延迟 + 结论芯片** | 1.02 MB |

## 0.1.0.8 相对上一版做了什么（本版）

**把上一版自绘的占位图标换成原 Flutter 工程的正式 logo。**

上一版虽然补上了图标、修通了资源链路，但图标是我新画的「teal 箭头」占位图，用户要求
改用原版。本版直接搬运原工程 `aqiyoung/Skyward` 的图标资源，不做任何二次绘制：

| 改动 | 内容 |
|---|---|
| 图标来源 | 原 Flutter 工程 `android/app/src/main/res/` 下的正式 launcher 图标（蓝白星球 + 白色「S」轨迹），非自绘 |
| `mipmap-{hdpi,mdpi,xhdpi,xxhdpi,xxxhdpi}/` | `ic_launcher.webp` + `ic_launcher_round.webp`（原工程各密度 webp） |
| `drawable-xxxhdpi/` | `ic_launcher_background.png` / `ic_launcher_foreground.png` / `ic_launcher_monochrome.png`（自适应前景/背景/单色） |
| `mipmap-anydpi-v26/` | 自适应图标 XML（引用上面三张 drawable，与原工程一致） |
| `drawable-nodpi/ic_logo.png` | 由原 `assets/images/icon.png`（1024²）缩到 288²，用于「我的 → 关于」页品牌展示 |
| 删除 | `scripts/gen_icons.py`（已无用，原图标是位图而非脚本生成） |

`minSdk 26`，**自适应图标是所有目标机型的主显示路径**，传统 / 圆形 webp 兜底。
内核与运行时逻辑**零改动**：仍是 23 个 JNI 符号、索引引擎、会话真值、状态落盘；
液态玻璃默认关闭、模块边界清晰不变。APK 从 0.39 → 0.42 MB，增量全是图标资源，
`classes.dex` / `libskyward_core.so` 未变。

## 0.1.0.6 相对上一版做了什么

**一、修掉内核里实测抓到的设计缺陷。** PoC-1 的 `match_host()` 逐条线性扫描，
规则从 9 条涨到 5 万条时吞吐从 50.97 塌到 0.01 Mops/s。本版改成三类索引：

| 规则类型 | PoC-1 | 本版 |
|---|---|---|
| DOMAIN-SUFFIX | 逐条 `ends_with` | 反转标签 trie，`rsplit` 零分配，O(标签数) |
| DOMAIN-KEYWORD | 逐条 `contains` | 按首字节分桶，只比对同桶候选 |
| IP-CIDR | 字符串前缀近似 | 解析 IPv4 + 按前缀长度分桶 + 桶内二分，最长前缀匹配 |

命中优先级仍按「规则原始序号最小者」，与逐条首次命中语义一致，host 基准
12/12 host 结果完全相同。线性实现保留为 `bench_matches_linear()`，仅用于同机对照，
不参与线上查询。

宿主实测（x86_64，同一份 engine）：

```
   rules      idx(ms)   idx Mops/s |      lin(ms)   lin Mops/s
       9        16.57        12.07 |         3.92        50.97
    1000        17.26        11.59 |        94.06         0.53
   10000        16.56        12.07 |        99.77         0.05
   50000        16.50        12.12 |       200.70         0.01
```

索引吞吐随规则数持平；线性按 O(n) 塌方。要说明的是：**索引化用固定成本换规模无关**，
小规则集下绝对吞吐仍低于线性，但真实 geo 规则量是万级，索引才有意义。
数据面同步受益：100 万包 × 1500 B 从 4.88 提到 **8.47 Mpps / 12.70 GB/s**。

**二、界面数字改成内核真值。** 新增会话状态（运行时长 / 上行 / 下行 / 包数 /
连接表）全部由 Rust core 计算累加，首页每秒 tick 刷新，不再写死
`186 MB` / `00:42:18` 这类演示常量。数据面仍是**内存模拟**，不接管真实网卡。

**三、状态落盘。** 所有开关、主题、路由、节点 / 组选中、连接态与会话累计字节写入
`SharedPreferences`，进程重启后恢复；连接态以原连接时刻为起点恢复内核会话，
时长与累计字节连续。液态玻璃**默认关闭**的规则不变。

**四、基准升级。** 「我的 → 工具」的性能基准改为索引 / 线性双引擎对照，跑完自动
`nativeResetRules()` 恢复默认规则集，避免污染首页「规则条数」。规模下调、子线程
分段、逐段刷新，不会卡界面。

## 架构分层

| 层 | 用什么 | 职责 |
|---|---|---|
| 平台壳（不可省） | Java | `VpnService` 子类、Manifest、Activity 生命周期 |
| UI | Android 原生 View | 纯代码构建，无 XML 布局、无 Compose、无 Flutter、无 WebView |
| JNI 边界 | C ABI | 只传 `int/long/double`，零对象分配、零字符串跨语言拷贝 |
| **内核 / 全部逻辑** | **Rust** | 规则索引、连接状态表、会话统计、数据面模拟、内存读数、基准 |

`core/` 是纯 `std`、零第三方依赖的 crate：`cdylib` 出 `libskyward_core.so`（arm64），
`rlib` 供宿主侧跑同一份逻辑的基准（无真机也能量 CPU/内存量级）。
JNI 导出从 12 个增至 **23 个**。

## 目录

```
core/
  Cargo.toml          release: opt-level=s / lto / codegen-units=1 / panic=abort / strip
  src/engine.rs       规则索引（trie / 关键词分桶 / CIDR）、连接表、会话、数据面、RSS
  src/lib.rs          JNI 导出（23 个函数，全部原始类型）
  examples/bench.rs   宿主侧基准：语义一致性 + 索引/线性对照 + 会话真值
android/
  AndroidManifest.xml 纯原生，含 VpnService 声明 + icon / roundIcon / label
  res/                 图标资源：5 密度 launcher webp + anydpi-v26 adaptive icon
                       + 自适应 fg/bg/mono + drawable-nodpi/ic_logo.png（均来自原 Flutter 工程）
  java/.../RustCore.java          native 声明（23 个 JNI 函数）
  java/.../MainActivity.java      4 Tab 主壳 + 状态恢复 + 页面代次管理
  java/.../Pages.java             四个页面的分组卡片内容 + 对照基准
  java/.../Ui.java                通用 UI 构建器（iOS 分组卡片风格）
  java/.../IconView.java          Canvas 自绘线性图标（零资源）
  java/.../AppState.java          UI 状态 + 会话真值 + SharedPreferences 持久化
  java/.../SkywardVpnService.java 那几十行无法省掉的壳
build.sh               手工组装 APK（不经 Gradle），aapt2 compile 后把 .flat 全传给 link
dist/                  产物
```

## 为什么是手工组装 APK

`aapt2 link` → `javac` → `d8` → 合并 dex/so → `zipalign -p 4` → `apksigner`。
不引入 AGP/Kotlin/Compose/Flutter，APK 里除了系统框架就是 Rust so + 一个 dex，
这样量出来的体积才是「架构本身的下限」，不会被构建工具的运行时污染。

## 构建

```bash
# 环境：Android SDK platform-35 / build-tools 35 / NDK r28c / JDK 17+ /
#       rustup target aarch64-linux-android
VERSION_CODE=8 VERSION_NAME="0.1.0.8-dev" ./build.sh
# 产物：dist/Skyward-RustCore-PoC1-arm64-v8a.apk（默认名，可用 OUT_APK 覆盖）
```

注意：本机 android 的 `libstd` 装在 `1.99.0` toolchain，默认 `stable`(1.93)
的 sysroot 里没有，脚本用 `cargo +1.99.0` 显式指定。换机器时按实际 toolchain 调整
`build.sh` 里的 `RUST_TC`。

## PoC 边界（诚实说明）

- **不含真实代理协议栈**：不含 Clash.Meta / clash-rs 的 VLESS Reality、Hysteria2、
  TUIC、WireGuard 等实现，也没有 tun2socks。数据面基准与会话计数都是**内存模拟**。
- **不含 geo 数据**（现行版 15.55MB）、不含订阅解析、不含真实配置导入 / 编辑。
- **不接管真实流量**：`SkywardVpnService` 有 `establishTun()` 但 UI 不触发，
  避免装机后误触断网。真实 tun fd 交给 Rust 是阶段 2。
- **已落盘的只是界面状态**：开关、主题、路由、选中项、连接态与模拟会话累计字节；
  节点、配置、订阅仍是界面演示占位，"连接"按钮不建 VPN 会话、不改系统设置。
- 因此这一版**不能用来连接代理**，只用于看：界面骨架与信息架构对齐程度、架构体积
  下限、规则引擎规模特性、数据面吞吐、常驻内存。真实转发性能必须等内核补齐后再测。
- 内存量级（host 实测）：基线 RSS 1.89 MB，跑完 100 万包 6.54 MB，逻辑状态约 3 KB。

## 与现行 Flutter 版的对照基线（实测 60.30 MB）

| 组成 | 现行版 | 本 PoC |
|---|---:|---|
| Go 内核 `libclash.so` | 23.62 MB | 无（Rust so 替代，但未含协议栈） |
| Flutter 引擎 + Dart AOT | 11.72 MB | 无（原生 View，系统提供） |
| geo 数据 | 15.55 MB | 无 |
| MLKit 扫码 | 2.84 MB | 无 |

真正该压的是 **Go 内核 + geo 共 39 MB**；本版 0.37 MB 只是架构壳的地板，
不是「完整 App 能这么小」。接上协议栈与 geo 后真实预估 15–22 MB。

## CI 工作流（目前只开发安卓端）

`.github/workflows/android-rust.yml` 只出一个 arm64 安卓 APK：装 JDK 17 / Rust
`aarch64-linux-android` / SDK platform-35 + build-tools 35 + NDK r28c → `./build.sh`
→ 验签+验架构 → 上传 artifact。刻意**不打 Release tag、不构建 desktop 或其它平台**。
`build.sh` 现在会在符号数异常偏少（< 12）时直接失败，防止漏编 JNI。

`.github/workflows/notify-telegram.yml` 是独立的补推工作流：Release 发布后手动
`workflow_dispatch` 派发，下载 Release asset 并 `sendDocument` 到 Dev 预览个人 chat。
TG 消息不可撤回，所以它只挂 dispatch（那条 push 触发器仅为让非默认分支注册该工作流，
job 有 `if` 硬拦截，push 一定 skipped，绝不自动发消息），不挂 schedule / PR / 其它路径。

runner（ubuntu-latest）自带 Android SDK，CI 直接用预装的 `sdkmanager`，**不依赖
`android-actions/setup-android`**（该 action 内部跑 `sdkmanager tools`，而 Google 已
下线旧 `tools` 包，会报 "Failed to find package 'tools'" 退出 1）。

`build.sh` 的所有路径、toolchain、版本号都可以用环境变量覆盖，因此本机与干净的
CI runner 用同一份脚本：

| 变量 | 作用 | 本机默认 | CI 设置 |
|---|---|---|---|
| `SKYWARD_ROOT` | 工程根 | 脚本所在目录 | checkout 根 |
| `ANDROID_SDK_ROOT` / `ANDROID_HOME` | SDK 位置 | `/tmp/rust_android_env/sdk` | runner 预装 SDK |
| `NDK_VERSION` / `BT_VERSION` | NDK / build-tools 版本 | `28.2.13676358` / `35.0.0` | 同左 |
| `RUST_TC` | 显式 toolchain | `+1.99.0` | `''`（用默认 stable，已装 android target） |
| `VERSION_CODE` / `VERSION_NAME` | aapt2 版本 | `1` / `0.1.0-poc1` | `${{ github.run_number }}` 等 |

固定签名：`scripts/debug.keystore`（debug key，密码 `android`）随工程提交，保证
本机 / CI / 任意次构建签名一致、APK 可直接覆盖安装。正式发版前须换成 release key
且**不要**提交进仓库。

版本号注入：`VERSION_CODE` / `VERSION_NAME` 由 CI 传 run number。因为 `aapt2 link` 的
`--version-code` **不会覆盖** manifest 里已硬编码的值，`build.sh` 会先生成一份替换过
`android:versionCode` / `android:versionName` 的临时 manifest 再 link，确保版本号真正
进入 APK。不带变量时默认 `1 / 0.1.0-poc1`。

## 旧版 Flutter 工作流：保留但暂停

`aqiyoung/Skyward` 上原有 12 条工作流（多平台构建、preview、发版、core 检查等）
已用 GitHub Actions 的 `disable` 接口整体暂停：**yaml 文件全部原样保留、内容一个
字节未改**。等新版稳定、你说启用时，一条命令精确恢复：

```bash
# 恢复（只 enable 暂停前 active 的那 11 条，不误开本来就停的 pages.yaml）
python3 scripts/resume-legacy-workflows.py
# 再次暂停（幂等）
python3 scripts/pause-legacy-workflows.py
```

暂停前的状态快照在 `scripts/legacy-workflows-state.json`，恢复以此为准。凭据读
`GITHUB_TOKEN` / `GH_TOKEN`，回退 `/tmp/.valid_tok`；仓库可用 `REPO` 覆盖。
